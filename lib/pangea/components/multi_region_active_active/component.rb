# frozen_string_literal: true

require 'pangea/components/base'
require 'pangea/components/multi_region_active_active/types'
require 'pangea/resources/aws'
require 'json'

module Pangea
  module Components
    # Multi-region active-active infrastructure with data consistency management
    # Creates global databases, health checks, traffic routing, and failover automation
    def multi_region_active_active(name, attributes = {})
      include Base
      include Resources::AWS
      
      # Validate and set defaults
      component_attrs = MultiRegionActiveActive::MultiRegionActiveActiveAttributes.new(attributes)
      component_attrs.validate!
      
      # Generate component-specific tags
      component_tag_set = component_tags('MultiRegionActiveActive', name, component_attrs.tags)
      
      resources = {}
      
      # Create Route 53 hosted zone for global domain
      hosted_zone_ref = aws_route53_zone(
        component_resource_name(name, :hosted_zone),
        {
          name: component_attrs.domain_name,
          comment: "Multi-region active-active deployment for #{component_attrs.deployment_name}",
          tags: component_tag_set.merge(GlobalDeployment: "true")
        }
      )
      resources[:hosted_zone] = hosted_zone_ref
      
      # Create global resources based on database engine
      case component_attrs.global_database.engine
      when 'dynamodb'
        resources[:global_database] = create_dynamodb_global_table(name, component_attrs, component_tag_set)
      when 'aurora-mysql', 'aurora-postgresql'
        resources[:global_database] = create_aurora_global_cluster(name, component_attrs, component_tag_set)
      end
      
      # Create Global Accelerator if enabled
      if component_attrs.enable_global_accelerator
        accelerator_ref = aws_globalaccelerator_accelerator(
          component_resource_name(name, :global_accelerator),
          {
            name: "#{name}-accelerator",
            ip_address_type: "IPV4",
            enabled: true,
            attributes: {
              flow_logs_enabled: component_attrs.monitoring.enabled,
              flow_logs_s3_bucket: component_attrs.monitoring.enabled ? "#{name}-flow-logs" : nil,
              flow_logs_s3_prefix: "global-accelerator/"
            },
            tags: component_tag_set
          }
        )
        resources[:global_accelerator] = accelerator_ref
        
        # Create listener for Global Accelerator
        listener_ref = aws_globalaccelerator_listener(
          component_resource_name(name, :ga_listener),
          {
            accelerator_arn: accelerator_ref.arn,
            client_affinity: component_attrs.traffic_routing.sticky_sessions ? "SOURCE_IP" : "NONE",
            protocol: component_attrs.application ? component_attrs.application.protocol : "TCP",
            port_ranges: [{
              from_port: component_attrs.application ? component_attrs.application.port : 443,
              to_port: component_attrs.application ? component_attrs.application.port : 443
            }]
          }
        )
        resources[:ga_listener] = listener_ref
      end
      
      # Process each region
      regional_resources = {}
      regional_endpoints = []
      
      component_attrs.regions.each_with_index do |region_config, index|
        region_resources = {}
        
        # Create or use existing VPC
        vpc_ref = region_config.vpc_ref || aws_vpc(
          component_resource_name(name, :vpc, region_config.region.to_sym),
          {
            cidr_block: region_config.vpc_cidr,
            enable_dns_hostnames: true,
            enable_dns_support: true,
            tags: component_tag_set.merge(
              Region: region_config.region,
              IsPrimary: region_config.is_primary.to_s
            )
          }
        )
        region_resources[:vpc] = vpc_ref
        
        # Create subnets across availability zones
        subnets = {}
        region_config.availability_zones.each_with_index do |az, az_index|
          # Calculate subnet CIDR (assumes /16 VPC, creates /24 subnets)
          base_ip = region_config.vpc_cidr.split('.')[0..1].join('.')
          public_subnet_ref = aws_subnet(
            component_resource_name(name, :subnet_public, "#{region_config.region}_#{az}".to_sym),
            {
              vpc_id: vpc_ref.id,
              cidr_block: "#{base_ip}.#{az_index * 2}.0/24",
              availability_zone: az,
              map_public_ip_on_launch: true,
              tags: component_tag_set.merge(
                Type: "Public",
                Region: region_config.region,
                AvailabilityZone: az
              )
            }
          )
          
          private_subnet_ref = aws_subnet(
            component_resource_name(name, :subnet_private, "#{region_config.region}_#{az}".to_sym),
            {
              vpc_id: vpc_ref.id,
              cidr_block: "#{base_ip}.#{az_index * 2 + 1}.0/24",
              availability_zone: az,
              map_public_ip_on_launch: false,
              tags: component_tag_set.merge(
                Type: "Private",
                Region: region_config.region,
                AvailabilityZone: az
              )
            }
          )
          
          subnets["public_#{az}".to_sym] = public_subnet_ref
          subnets["private_#{az}".to_sym] = private_subnet_ref
        end
        region_resources[:subnets] = subnets
        
        # Create regional database resources
        if component_attrs.global_database.engine.start_with?('aurora')
          region_resources[:regional_cluster] = create_regional_aurora_cluster(
            name, region_config, component_attrs, resources[:global_database], subnets, component_tag_set
          )
        end
        
        # Create application infrastructure if configured
        if component_attrs.application
          app_resources = create_regional_application(
            name, region_config, component_attrs, vpc_ref, subnets, component_tag_set
          )
          region_resources[:application] = app_resources
          
          # Create regional endpoint for health checks
          endpoint_ref = aws_route53_health_check(
            component_resource_name(name, :health_check, region_config.region.to_sym),
            {
              fqdn: app_resources[:load_balancer].dns_name,
              port: component_attrs.application.port,
              type: component_attrs.application.protocol == 'HTTPS' ? "HTTPS" : "HTTP",
              resource_path: component_attrs.application.health_check_path,
              failure_threshold: component_attrs.failover.unhealthy_threshold.to_s,
              request_interval: component_attrs.failover.health_check_interval.to_s,
              tags: component_tag_set.merge(Region: region_config.region)
            }
          )
          region_resources[:health_check] = endpoint_ref
          
          regional_endpoints << {
            region: region_config.region,
            endpoint: app_resources[:load_balancer].dns_name,
            health_check_id: endpoint_ref.id,
            weight: region_config.write_weight
          }
        end
        
        # Create Transit Gateway for cross-region connectivity
        if component_attrs.regions.length > 1
          tgw_ref = aws_ec2_transit_gateway(
            component_resource_name(name, :transit_gateway, region_config.region.to_sym),
            {
              description: "Transit Gateway for #{component_attrs.deployment_name} in #{region_config.region}",
              amazon_side_asn: 64512 + index,
              default_route_table_association: "enable",
              default_route_table_propagation: "enable",
              dns_support: "enable",
              vpn_ecmp_support: "enable",
              tags: component_tag_set.merge(Region: region_config.region)
            }
          )
          region_resources[:transit_gateway] = tgw_ref
          
          # Attach VPC to Transit Gateway
          tgw_attachment_ref = aws_ec2_transit_gateway_vpc_attachment(
            component_resource_name(name, :tgw_attachment, region_config.region.to_sym),
            {
              transit_gateway_id: tgw_ref.id,
              vpc_id: vpc_ref.id,
              subnet_ids: subnets.select { |k, _| k.to_s.start_with?('private_') }.values.map(&:id),
              dns_support: "enable",
              ipv6_support: "disable",
              tags: component_tag_set.merge(Region: region_config.region)
            }
          )
          region_resources[:tgw_attachment] = tgw_attachment_ref
        end
        
        # Create regional monitoring resources
        if component_attrs.monitoring.enabled
          region_resources[:monitoring] = create_regional_monitoring(
            name, region_config, component_attrs, region_resources, component_tag_set
          )
        end
        
        # Store regional resources
        regional_resources[region_config.region.to_sym] = region_resources
      end
      
      resources[:regional] = regional_resources
      
      # Create cross-region peering connections
      if component_attrs.regions.length > 1
        peering_resources = create_transit_gateway_peering(
          name, component_attrs, regional_resources, component_tag_set
        )
        resources[:peering] = peering_resources
      end
      
      # Create global traffic routing
      if regional_endpoints.any?
        routing_resources = create_global_traffic_routing(
          name, component_attrs, hosted_zone_ref, regional_endpoints, resources[:ga_listener], component_tag_set
        )
        resources[:traffic_routing] = routing_resources
      end
      
      # Create global monitoring dashboard
      if component_attrs.monitoring.cross_region_dashboard
        dashboard_ref = create_global_dashboard(name, component_attrs, resources, component_tag_set)
        resources[:global_dashboard] = dashboard_ref
      end
      
      # Create chaos engineering experiments if enabled
      if component_attrs.enable_chaos_engineering
        chaos_resources = create_chaos_experiments(name, component_attrs, resources, component_tag_set)
        resources[:chaos_engineering] = chaos_resources
      end
      
      # Calculate outputs
      outputs = {
        deployment_name: component_attrs.deployment_name,
        domain_name: component_attrs.domain_name,
        hosted_zone_id: hosted_zone_ref.zone_id,
        
        regions: component_attrs.regions.map(&:region),
        primary_regions: component_attrs.regions.select(&:is_primary).map(&:region),
        
        consistency_model: component_attrs.consistency.consistency_model,
        conflict_resolution: component_attrs.consistency.conflict_resolution,
        
        global_accelerator_dns: resources[:global_accelerator]&.dns_name,
        global_accelerator_ips: resources[:global_accelerator]&.ip_sets&.map { |s| s[:ip_addresses] }&.flatten,
        
        regional_endpoints: regional_endpoints.map { |e| { region: e[:region], endpoint: e[:endpoint] } },
        
        database_engine: component_attrs.global_database.engine,
        database_endpoints: extract_database_endpoints(resources),
        
        features_enabled: [
          ("Global Accelerator" if component_attrs.enable_global_accelerator),
          ("Circuit Breaker" if component_attrs.enable_circuit_breaker),
          ("Bulkhead Pattern" if component_attrs.enable_bulkhead_pattern),
          ("Chaos Engineering" if component_attrs.enable_chaos_engineering),
          ("Data Residency" if component_attrs.data_residency_enabled),
          ("Synthetic Monitoring" if component_attrs.monitoring.synthetic_monitoring),
          ("Anomaly Detection" if component_attrs.monitoring.anomaly_detection)
        ].compact,
        
        estimated_monthly_cost: estimate_multi_region_cost(component_attrs, resources),
        
        health_status: {
          regions_healthy: regional_endpoints.length,
          total_regions: component_attrs.regions.length,
          failover_ready: component_attrs.failover.enabled
        }
      }
      
      create_component_reference(
        'multi_region_active_active',
        name,
        component_attrs.to_h,
        resources,
        outputs
      )
    end
    
    private
    
    def create_dynamodb_global_table(name, attrs, tags)
      # Create DynamoDB global table
      table_ref = aws_dynamodb_table(
        component_resource_name(name, :global_table),
        {
          name: "#{name}-global-table",
          billing_mode: "PAY_PER_REQUEST",
          hash_key: "id",
          range_key: "sort_key",
          
          attribute: [
            { name: "id", type: "S" },
            { name: "sort_key", type: "S" }
          ],
          
          stream_enabled: true,
          stream_view_type: "NEW_AND_OLD_IMAGES",
          
          replica: attrs.regions.map do |region|
            {
              region_name: region.region,
              kms_key_arn: attrs.global_database.kms_key_ref&.arn,
              propagate_tags: true,
              global_secondary_indexes: [{
                index_name: "gsi1",
                projection_type: "ALL",
                non_key_attributes: []
              }]
            }
          end,
          
          server_side_encryption: attrs.global_database.storage_encrypted ? {
            enabled: true,
            kms_key_arn: attrs.global_database.kms_key_ref&.arn
          } : nil,
          
          tags: tags
        }.compact
      )
      
      # Create global table configuration for consistency
      if attrs.consistency.consistency_model != 'eventual'
        # Note: In real implementation, would create additional Lambda functions
        # for strong consistency enforcement
      end
      
      table_ref
    end
    
    def create_aurora_global_cluster(name, attrs, tags)
      # Create Aurora global database cluster
      global_cluster_ref = aws_rds_global_cluster(
        component_resource_name(name, :aurora_global),
        {
          global_cluster_identifier: "#{name}-global-cluster",
          engine: attrs.global_database.engine,
          engine_version: attrs.global_database.engine_version,
          database_name: "#{name.to_s.gsub(/[^a-zA-Z0-9]/, '')}db",
          storage_encrypted: attrs.global_database.storage_encrypted,
          deletion_protection: true
        }
      )
      
      global_cluster_ref
    end
    
    def create_regional_aurora_cluster(name, region_config, attrs, global_cluster, subnets, tags)
      # Create DB subnet group
      db_subnet_group_ref = aws_db_subnet_group(
        component_resource_name(name, :db_subnet_group, region_config.region.to_sym),
        {
          name: "#{name}-#{region_config.region}-subnet-group",
          description: "Subnet group for Aurora cluster in #{region_config.region}",
          subnet_ids: subnets.select { |k, _| k.to_s.start_with?('private_') }.values.map(&:id),
          tags: tags.merge(Region: region_config.region)
        }
      )
      
      # Create regional Aurora cluster
      cluster_ref = aws_rds_cluster(
        component_resource_name(name, :aurora_cluster, region_config.region.to_sym),
        {
          cluster_identifier: "#{name}-#{region_config.region}-cluster",
          engine: attrs.global_database.engine,
          engine_version: attrs.global_database.engine_version,
          global_cluster_identifier: global_cluster.id,
          database_name: region_config.is_primary ? "#{name.to_s.gsub(/[^a-zA-Z0-9]/, '')}db" : nil,
          db_subnet_group_name: db_subnet_group_ref.name,
          backup_retention_period: attrs.global_database.backup_retention_days,
          preferred_backup_window: "03:00-04:00",
          preferred_maintenance_window: "sun:04:00-sun:05:00",
          storage_encrypted: attrs.global_database.storage_encrypted,
          kms_key_id: attrs.global_database.kms_key_ref&.arn,
          enabled_cloudwatch_logs_exports: ["postgresql"] || ["mysql"],
          tags: tags.merge(Region: region_config.region, IsPrimary: region_config.is_primary.to_s)
        }.compact
      )
      
      # Create cluster instances
      instance_count = region_config.is_primary ? 2 : 1
      instances = {}
      
      (1..instance_count).each do |i|
        instance_ref = aws_rds_cluster_instance(
          component_resource_name(name, :aurora_instance, "#{region_config.region}_#{i}".to_sym),
          {
            identifier: "#{name}-#{region_config.region}-instance-#{i}",
            cluster_identifier: cluster_ref.id,
            instance_class: attrs.global_database.instance_class,
            engine: attrs.global_database.engine,
            engine_version: attrs.global_database.engine_version,
            performance_insights_enabled: true,
            monitoring_interval: 60,
            promotion_tier: i,
            tags: tags.merge(Region: region_config.region)
          }
        )
        instances["instance_#{i}".to_sym] = instance_ref
      end
      
      {
        subnet_group: db_subnet_group_ref,
        cluster: cluster_ref,
        instances: instances
      }
    end
    
    def create_regional_application(name, region_config, attrs, vpc_ref, subnets, tags)
      app = attrs.application
      
      # Create security group for application
      app_sg_ref = aws_security_group(
        component_resource_name(name, :app_sg, region_config.region.to_sym),
        {
          name: "#{name}-${region_config.region}-app-sg",
          description: "Security group for application in #{region_config.region}",
          vpc_id: vpc_ref.id,
          tags: tags.merge(Region: region_config.region)
        }
      )
      
      # Create security group rules
      aws_security_group_rule(
        component_resource_name(name, :app_sg_ingress, region_config.region.to_sym),
        {
          type: "ingress",
          from_port: app.port,
          to_port: app.port,
          protocol: "tcp",
          cidr_blocks: ["0.0.0.0/0"],
          security_group_id: app_sg_ref.id
        }
      )
      
      aws_security_group_rule(
        component_resource_name(name, :app_sg_egress, region_config.region.to_sym),
        {
          type: "egress",
          from_port: 0,
          to_port: 0,
          protocol: "-1",
          cidr_blocks: ["0.0.0.0/0"],
          security_group_id: app_sg_ref.id
        }
      )
      
      # Create Application Load Balancer
      alb_ref = aws_lb(
        component_resource_name(name, :alb, region_config.region.to_sym),
        {
          name: "#{name}-#{region_config.region}-alb",
          internal: false,
          load_balancer_type: "application",
          security_groups: [app_sg_ref.id],
          subnets: subnets.select { |k, _| k.to_s.start_with?('public_') }.values.map(&:id),
          enable_deletion_protection: true,
          enable_http2: true,
          enable_cross_zone_load_balancing: true,
          tags: tags.merge(Region: region_config.region)
        }
      )
      
      # Create target group
      target_group_ref = aws_lb_target_group(
        component_resource_name(name, :target_group, region_config.region.to_sym),
        {
          name: "#{name}-#{region_config.region}-tg",
          port: app.port,
          protocol: app.protocol == 'HTTPS' ? 'HTTP' : app.protocol,
          vpc_id: vpc_ref.id,
          target_type: "ip",
          health_check: {
            enabled: true,
            healthy_threshold: 2,
            interval: 30,
            matcher: "200",
            path: app.health_check_path,
            port: "traffic-port",
            protocol: app.protocol == 'HTTPS' ? 'HTTP' : app.protocol,
            timeout: 5,
            unhealthy_threshold: 2
          },
          stickiness: attrs.traffic_routing.sticky_sessions ? {
            enabled: true,
            type: "lb_cookie",
            cookie_duration: attrs.traffic_routing.session_affinity_ttl
          } : nil,
          tags: tags.merge(Region: region_config.region)
        }.compact
      )
      
      # Create ALB listener
      listener_ref = aws_lb_listener(
        component_resource_name(name, :alb_listener, region_config.region.to_sym),
        {
          load_balancer_arn: alb_ref.arn,
          port: app.port,
          protocol: app.protocol,
          certificate_arn: app.protocol == 'HTTPS' ? "arn:aws:acm:#{region_config.region}:ACCOUNT:certificate/CERT" : nil,
          default_action: [{
            type: "forward",
            target_group_arn: target_group_ref.arn
          }]
        }.compact
      )
      
      # Create ECS cluster for the application
      ecs_cluster_ref = aws_ecs_cluster(
        component_resource_name(name, :ecs_cluster, region_config.region.to_sym),
        {
          name: "#{name}-#{region_config.region}-cluster",
          capacity_providers: ["FARGATE", "FARGATE_SPOT"],
          default_capacity_provider_strategy: [
            {
              capacity_provider: "FARGATE",
              weight: attrs.cost_optimization.spot_instances_enabled ? 20 : 100,
              base: 1
            },
            attrs.cost_optimization.spot_instances_enabled ? {
              capacity_provider: "FARGATE_SPOT",
              weight: 80
            } : nil
          ].compact,
          setting: [{
            name: "containerInsights",
            value: attrs.monitoring.enabled ? "enabled" : "disabled"
          }],
          tags: tags.merge(Region: region_config.region)
        }
      )
      
      # Create task definition
      task_def_ref = aws_ecs_task_definition(
        component_resource_name(name, :task_definition, region_config.region.to_sym),
        {
          family: "#{name}-#{region_config.region}-task",
          network_mode: "awsvpc",
          requires_compatibilities: ["FARGATE"],
          cpu: app.task_cpu.to_s,
          memory: app.task_memory.to_s,
          container_definitions: JSON.generate([{
            name: app.name,
            image: app.container_image || "nginx:latest",
            portMappings: [{
              containerPort: app.port,
              protocol: "tcp"
            }],
            environment: [
              { name: "REGION", value: region_config.region },
              { name: "IS_PRIMARY", value: region_config.is_primary.to_s }
            ],
            logConfiguration: {
              logDriver: "awslogs",
              options: {
                "awslogs-group": "/ecs/#{name}-#{region_config.region}",
                "awslogs-region": region_config.region,
                "awslogs-stream-prefix": "ecs"
              }
            }
          }]),
          tags: tags.merge(Region: region_config.region)
        }
      )
      
      # Create ECS service
      ecs_service_ref = aws_ecs_service(
        component_resource_name(name, :ecs_service, region_config.region.to_sym),
        {
          name: "#{name}-#{region_config.region}-service",
          cluster: ecs_cluster_ref.id,
          task_definition: task_def_ref.arn,
          desired_count: app.desired_count,
          launch_type: "FARGATE",
          
          network_configuration: {
            awsvpc_configuration: {
              subnets: subnets.select { |k, _| k.to_s.start_with?('private_') }.values.map(&:id),
              security_groups: [app_sg_ref.id],
              assign_public_ip: "DISABLED"
            }
          },
          
          load_balancer: [{
            target_group_arn: target_group_ref.arn,
            container_name: app.name,
            container_port: app.port
          }],
          
          health_check_grace_period_seconds: 60,
          
          deployment_configuration: {
            maximum_percent: 200,
            minimum_healthy_percent: 100,
            deployment_circuit_breaker: attrs.enable_circuit_breaker ? {
              enable: true,
              rollback: true
            } : nil
          },
          
          tags: tags.merge(Region: region_config.region)
        }.compact
      )
      
      {
        security_group: app_sg_ref,
        load_balancer: alb_ref,
        target_group: target_group_ref,
        listener: listener_ref,
        ecs_cluster: ecs_cluster_ref,
        task_definition: task_def_ref,
        ecs_service: ecs_service_ref
      }
    end
    
    def create_transit_gateway_peering(name, attrs, regional_resources, tags)
      peering_connections = {}
      regions = attrs.regions.map(&:region)
      
      # Create peering connections between all region pairs
      regions.combination(2).each do |region1, region2|
        peering_ref = aws_ec2_transit_gateway_peering_attachment(
          component_resource_name(name, :tgw_peering, "#{region1}_#{region2}".to_sym),
          {
            transit_gateway_id: regional_resources[region1.to_sym][:transit_gateway].id,
            peer_transit_gateway_id: regional_resources[region2.to_sym][:transit_gateway].id,
            peer_account_id: "${AWS::AccountId}",
            peer_region: region2,
            tags: tags.merge(
              PeeringType: "InterRegion",
              Region1: region1,
              Region2: region2
            )
          }
        )
        peering_connections["#{region1}_#{region2}".to_sym] = peering_ref
      end
      
      peering_connections
    end
    
    def create_global_traffic_routing(name, attrs, hosted_zone, endpoints, ga_listener, tags)
      routing_resources = {}
      
      if attrs.enable_global_accelerator && ga_listener
        # Add endpoint groups to Global Accelerator
        endpoints.each do |endpoint|
          endpoint_group_ref = aws_globalaccelerator_endpoint_group(
            component_resource_name(name, :ga_endpoint_group, endpoint[:region].to_sym),
            {
              listener_arn: ga_listener.arn,
              endpoint_group_region: endpoint[:region],
              endpoint_configuration: [{
                endpoint_id: endpoint[:endpoint],
                weight: endpoint[:weight],
                client_ip_preservation_enabled: false
              }],
              health_check_interval_seconds: attrs.failover.health_check_interval,
              health_check_path: attrs.application.health_check_path,
              health_check_port: attrs.application.port,
              health_check_protocol: attrs.application.protocol,
              threshold_count: attrs.failover.unhealthy_threshold
            }
          )
          routing_resources["ga_endpoint_#{endpoint[:region]}".to_sym] = endpoint_group_ref
        end
      end
      
      # Create Route 53 routing policies
      case attrs.traffic_routing.routing_policy
      when 'latency'
        endpoints.each do |endpoint|
          record_ref = aws_route53_record(
            component_resource_name(name, :route53_record, endpoint[:region].to_sym),
            {
              zone_id: hosted_zone.zone_id,
              name: attrs.domain_name,
              type: "A",
              set_identifier: endpoint[:region],
              
              alias: {
                name: endpoint[:endpoint],
                zone_id: "Z35SXDOTRQ7X7K", # ALB zone ID for us-east-1, would be dynamic
                evaluate_target_health: true
              },
              
              latency_routing_policy: {
                region: endpoint[:region]
              },
              
              health_check_id: endpoint[:health_check_id]
            }
          )
          routing_resources["route53_#{endpoint[:region]}".to_sym] = record_ref
        end
        
      when 'weighted'
        endpoints.each do |endpoint|
          record_ref = aws_route53_record(
            component_resource_name(name, :route53_record, endpoint[:region].to_sym),
            {
              zone_id: hosted_zone.zone_id,
              name: attrs.domain_name,
              type: "A",
              set_identifier: endpoint[:region],
              
              alias: {
                name: endpoint[:endpoint],
                zone_id: "Z35SXDOTRQ7X7K",
                evaluate_target_health: true
              },
              
              weighted_routing_policy: {
                weight: endpoint[:weight]
              },
              
              health_check_id: endpoint[:health_check_id]
            }
          )
          routing_resources["route53_#{endpoint[:region]}".to_sym] = record_ref
        end
        
      when 'failover'
        primary_endpoint = endpoints.find { |e| attrs.regions.find { |r| r.region == e[:region] }&.is_primary }
        secondary_endpoints = endpoints.reject { |e| e == primary_endpoint }
        
        # Primary record
        if primary_endpoint
          primary_record_ref = aws_route53_record(
            component_resource_name(name, :route53_record_primary),
            {
              zone_id: hosted_zone.zone_id,
              name: attrs.domain_name,
              type: "A",
              set_identifier: "Primary",
              
              alias: {
                name: primary_endpoint[:endpoint],
                zone_id: "Z35SXDOTRQ7X7K",
                evaluate_target_health: true
              },
              
              failover_routing_policy: {
                type: "PRIMARY"
              },
              
              health_check_id: primary_endpoint[:health_check_id]
            }
          )
          routing_resources[:route53_primary] = primary_record_ref
        end
        
        # Secondary record
        if secondary_endpoints.any?
          secondary_record_ref = aws_route53_record(
            component_resource_name(name, :route53_record_secondary),
            {
              zone_id: hosted_zone.zone_id,
              name: attrs.domain_name,
              type: "A",
              set_identifier: "Secondary",
              
              alias: {
                name: secondary_endpoints.first[:endpoint],
                zone_id: "Z35SXDOTRQ7X7K",
                evaluate_target_health: true
              },
              
              failover_routing_policy: {
                type: "SECONDARY"
              },
              
              health_check_id: secondary_endpoints.first[:health_check_id]
            }
          )
          routing_resources[:route53_secondary] = secondary_record_ref
        end
      end
      
      routing_resources
    end
    
    def create_regional_monitoring(name, region_config, attrs, region_resources, tags)
      monitoring_resources = {}
      
      # Create CloudWatch Log Group
      log_group_ref = aws_cloudwatch_log_group(
        component_resource_name(name, :log_group, region_config.region.to_sym),
        {
          name: "/aws/multi-region/#{name}/#{region_config.region}",
          retention_in_days: 30,
          tags: tags.merge(Region: region_config.region)
        }
      )
      monitoring_resources[:log_group] = log_group_ref
      
      # Create CloudWatch alarms
      if region_resources[:application]
        # ALB health alarm
        alb_health_alarm_ref = aws_cloudwatch_metric_alarm(
          component_resource_name(name, :alarm_alb_health, region_config.region.to_sym),
          {
            alarm_name: "#{name}-#{region_config.region}-alb-health",
            comparison_operator: "LessThanThreshold",
            evaluation_periods: "2",
            metric_name: "HealthyHostCount",
            namespace: "AWS/ApplicationELB",
            period: "60",
            statistic: "Minimum",
            threshold: "1",
            alarm_description: "ALB has unhealthy targets in #{region_config.region}",
            dimensions: {
              TargetGroup: region_resources[:application][:target_group].arn_suffix,
              LoadBalancer: region_resources[:application][:load_balancer].arn_suffix
            },
            tags: tags.merge(Region: region_config.region)
          }
        )
        monitoring_resources[:alb_health_alarm] = alb_health_alarm_ref
        
        # ECS service health alarm
        ecs_health_alarm_ref = aws_cloudwatch_metric_alarm(
          component_resource_name(name, :alarm_ecs_health, region_config.region.to_sym),
          {
            alarm_name: "#{name}-#{region_config.region}-ecs-health",
            comparison_operator: "LessThanThreshold",
            evaluation_periods: "2",
            metric_name: "RunningTaskCount",
            namespace: "AWS/ECS",
            period: "60",
            statistic: "Average",
            threshold: "1",
            alarm_description: "ECS service has insufficient running tasks in #{region_config.region}",
            dimensions: {
              ServiceName: region_resources[:application][:ecs_service].name,
              ClusterName: region_resources[:application][:ecs_cluster].name
            },
            tags: tags.merge(Region: region_config.region)
          }
        )
        monitoring_resources[:ecs_health_alarm] = ecs_health_alarm_ref
      end
      
      # Create synthetic monitoring if enabled
      if attrs.monitoring.synthetic_monitoring
        canary_ref = aws_synthetics_canary(
          component_resource_name(name, :canary, region_config.region.to_sym),
          {
            name: "#{name}-#{region_config.region}-canary",
            artifact_s3_location: "s3://#{name}-canary-artifacts-#{region_config.region}/",
            execution_role_arn: "arn:aws:iam::ACCOUNT:role/CloudWatchSyntheticsRole",
            handler: "pageLoadBlueprint.handler",
            runtime_version: "syn-nodejs-puppeteer-3.5",
            
            schedule: {
              expression: "rate(5 minutes)"
            },
            
            run_config: {
              timeout_in_seconds: 300,
              memory_in_mb: 960,
              active_tracing: true
            },
            
            vpc_config: {
              subnet_ids: region_resources[:subnets].select { |k, _| k.to_s.start_with?('private_') }.values.map(&:id),
              security_group_ids: [region_resources[:application][:security_group].id]
            },
            
            tags: tags.merge(Region: region_config.region)
          }
        )
        monitoring_resources[:canary] = canary_ref
      end
      
      monitoring_resources
    end
    
    def create_global_dashboard(name, attrs, resources, tags)
      dashboard_widgets = []
      
      # Global map widget
      dashboard_widgets << {
        type: "metric",
        x: 0,
        y: 0,
        width: 24,
        height: 8,
        properties: {
          title: "Global Infrastructure Overview",
          metrics: [],
          view: "singleValue",
          region: "us-east-1",
          annotations: {
            horizontal: [{
              label: "All Regions Healthy",
              value: attrs.regions.length
            }]
          }
        }
      }
      
      # Regional health metrics
      attrs.regions.each_with_index do |region, index|
        x = (index % 3) * 8
        y = 8 + (index / 3) * 6
        
        dashboard_widgets << {
          type: "metric",
          x: x,
          y: y,
          width: 8,
          height: 6,
          properties: {
            title: "#{region.region} Health",
            metrics: [
              ["AWS/Route53", "HealthCheckStatus", { HealthCheckId: resources[:regional][region.region.to_sym][:health_check]&.id }],
              ["AWS/ApplicationELB", "HealthyHostCount", { 
                TargetGroup: resources[:regional][region.region.to_sym][:application]&.dig(:target_group)&.arn_suffix,
                LoadBalancer: resources[:regional][region.region.to_sym][:application]&.dig(:load_balancer)&.arn_suffix
              }]
            ].compact,
            period: 300,
            stat: "Average",
            region: region.region,
            yAxis: { left: { min: 0, max: 1 } }
          }
        }
      end
      
      # Global traffic distribution
      dashboard_widgets << {
        type: "metric",
        x: 0,
        y: 20,
        width: 12,
        height: 6,
        properties: {
          title: "Global Traffic Distribution",
          metrics: attrs.regions.map do |region|
            ["AWS/ApplicationELB", "RequestCount", {
              LoadBalancer: resources[:regional][region.region.to_sym][:application]&.dig(:load_balancer)&.arn_suffix
            }]
          end.compact,
          period: 300,
          stat: "Sum",
          region: "us-east-1",
          stacked: true
        }
      }
      
      # Database replication lag (for Aurora)
      if attrs.global_database.engine.start_with?('aurora')
        dashboard_widgets << {
          type: "metric",
          x: 12,
          y: 20,
          width: 12,
          height: 6,
          properties: {
            title: "Cross-Region Replication Lag",
            metrics: attrs.regions.map do |region|
              ["AWS/RDS", "AuroraReplicaLag", {
                DBClusterIdentifier: resources[:regional][region.region.to_sym][:regional_cluster]&.dig(:cluster)&.id
              }]
            end.compact,
            period: 300,
            stat: "Average",
            region: "us-east-1",
            yAxis: { left: { label: "Milliseconds" } }
          }
        }
      end
      
      aws_cloudwatch_dashboard(
        component_resource_name(name, :global_dashboard),
        {
          dashboard_name: "#{name}-global-overview",
          dashboard_body: JSON.generate({
            widgets: dashboard_widgets,
            periodOverride: "auto",
            start: "-PT6H"
          })
        }
      )
    end
    
    def create_chaos_experiments(name, attrs, resources, tags)
      chaos_resources = {}
      
      # Create IAM role for FIS
      fis_role_ref = aws_iam_role(
        component_resource_name(name, :fis_role),
        {
          name: "#{name}-fis-role",
          assume_role_policy: JSON.generate({
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Principal: { Service: "fis.amazonaws.com" },
              Action: "sts:AssumeRole"
            }]
          }),
          tags: tags
        }
      )
      chaos_resources[:fis_role] = fis_role_ref
      
      # Attach FIS policy
      fis_policy_attachment_ref = aws_iam_role_policy_attachment(
        component_resource_name(name, :fis_policy_attachment),
        {
          role: fis_role_ref.name,
          policy_arn: "arn:aws:iam::aws:policy/service-role/AWSFaultInjectionSimulatorECSAccess"
        }
      )
      chaos_resources[:fis_policy] = fis_policy_attachment_ref
      
      # Create experiment template for region failure simulation
      experiment_ref = aws_fis_experiment_template(
        component_resource_name(name, :fis_experiment),
        {
          description: "Simulate region failure for #{attrs.deployment_name}",
          role_arn: fis_role_ref.arn,
          
          stop_condition: [{
            source: "none"
          }],
          
          action: {
            stop_ecs_tasks: {
              action_id: "aws:ecs:stop-task",
              description: "Stop ECS tasks in a region",
              target: {
                key: "Tasks",
                value: "ecs-tasks"
              }
            }
          },
          
          target: {
            "ecs-tasks": {
              resource_type: "aws:ecs:task",
              selection_mode: "PERCENT(50)",
              resource_tag: {
                Component: "MultiRegionActiveActive"
              }
            }
          },
          
          tags: tags.merge(ExperimentType: "RegionFailure")
        }
      )
      chaos_resources[:experiment_template] = experiment_ref
      
      chaos_resources
    end
    
    def extract_database_endpoints(resources)
      endpoints = {}
      
      if resources[:global_database]
        case resources[:global_database].type
        when 'aws_dynamodb_table'
          endpoints[:type] = 'dynamodb'
          endpoints[:table_name] = resources[:global_database].attributes[:name]
          
        when 'aws_rds_global_cluster'
          endpoints[:type] = 'aurora'
          endpoints[:global_cluster] = resources[:global_database].id
          endpoints[:regional] = {}
          
          resources[:regional].each do |region, region_resources|
            if region_resources[:regional_cluster]
              endpoints[:regional][region] = {
                cluster_endpoint: region_resources[:regional_cluster][:cluster].endpoint,
                reader_endpoint: region_resources[:regional_cluster][:cluster].reader_endpoint
              }
            end
          end
        end
      end
      
      endpoints
    end
    
    def estimate_multi_region_cost(attrs, resources)
      cost = 0.0
      
      # Global Accelerator cost
      if attrs.enable_global_accelerator
        cost += 0.025 * 24 * 30  # $0.025 per hour
        cost += 0.015 * 1000      # Estimated data processing
      end
      
      # Route 53 costs
      cost += 0.50  # Hosted zone
      cost += attrs.regions.length * 0.50  # Health checks per region
      
      # Database costs
      case attrs.global_database.engine
      when 'dynamodb'
        # DynamoDB global tables
        cost += attrs.regions.length * 25  # Base cost per region
        cost += attrs.regions.length * 1.25 * 100  # Estimated storage and throughput
        
      when 'aurora-mysql', 'aurora-postgresql'
        # Aurora global database
        attrs.regions.each_with_index do |region, index|
          instance_count = region.is_primary ? 2 : 1
          cost += instance_count * estimate_aurora_instance_cost(attrs.global_database.instance_class)
          cost += 100  # Storage estimate
        end
      end
      
      # Application infrastructure costs (if configured)
      if attrs.application
        attrs.regions.each do |region|
          # ALB cost
          cost += 22.0
          
          # ECS Fargate costs
          task_hours = attrs.application.desired_count * 24 * 30
          cpu_cost = (attrs.application.task_cpu / 1024.0) * 0.04048 * task_hours
          memory_cost = (attrs.application.task_memory / 1024.0) * 0.004445 * task_hours
          cost += cpu_cost + memory_cost
        end
      end
      
      # Transit Gateway costs
      if attrs.regions.length > 1
        cost += attrs.regions.length * 36  # $0.05 per hour per TGW
        cost += attrs.regions.length * (attrs.regions.length - 1) * 20  # Peering attachments
      end
      
      # Monitoring costs
      if attrs.monitoring.enabled
        cost += attrs.regions.length * 15  # CloudWatch logs, metrics, alarms
        
        if attrs.monitoring.synthetic_monitoring
          cost += attrs.regions.length * 10  # Synthetics canaries
        end
      end
      
      # Data transfer costs (estimate)
      cross_region_gb = 500  # Estimated monthly cross-region transfer
      cost += cross_region_gb * 0.02 * attrs.regions.length
      
      cost.round(2)
    end
    
    def estimate_aurora_instance_cost(instance_class)
      case instance_class
      when 'db.r5.large'
        230.0
      when 'db.r5.xlarge'
        460.0
      when 'db.r5.2xlarge'
        920.0
      when 'db.r6g.large'
        180.0
      when 'db.r6g.xlarge'
        360.0
      else
        200.0  # Default estimate
      end
    end
  end
end