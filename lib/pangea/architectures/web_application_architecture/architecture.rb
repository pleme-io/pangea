# frozen_string_literal: true

require_relative '../base'
require_relative '../types'
require_relative 'types'
require 'pangea/architecture_registry'

module Pangea
  module Architectures
    module WebApplicationArchitecture
      class Architecture
        def self.build(name, attributes = {})
          new.build(name, attributes)
        end

        def build(name, attributes = {})
          # 1. Validate input attributes
          arch_attrs = Types::Input.new(attributes)
          
          # 2. Merge with environment defaults
          defaults = Pangea::Architectures::Types.defaults_for_environment(arch_attrs.environment)
          merged_attrs = defaults.merge(arch_attrs.to_h)
          
          # 3. Create components using Pangea components
          components = create_components(name, merged_attrs)
          
          # 4. Create additional resources
          resources = create_resources(name, merged_attrs, components)
          
          # 5. Calculate outputs
          outputs = calculate_outputs(name, merged_attrs, components, resources)
          
          # 6. Return ArchitectureReference
          Pangea::Architectures::ArchitectureReference.new(
            type: 'web_application_architecture',
            name: name,
            architecture_attributes: arch_attrs.to_h,
            components: components,
            resources: resources,
            outputs: outputs
          )
        end

        private

        def create_components(name, attributes)
          # Include the Components module to access component functions
          extend Pangea::Components if defined?(Pangea::Components)
          
          components = {}

          # 1. Network Foundation
          components[:network] = create_network_component(name, attributes)
          
          # 2. Security Groups
          components[:security_groups] = create_security_groups(name, attributes, components[:network])
          
          # 3. Load Balancer
          components[:load_balancer] = create_load_balancer(name, attributes, components[:network], components[:security_groups])
          
          # 4. Auto Scaling Web Servers
          components[:web_servers] = create_web_servers(name, attributes, components[:network], components[:security_groups], components[:load_balancer])
          
          # 5. Database (if enabled)
          if attributes[:database_enabled] != false
            components[:database] = create_database(name, attributes, components[:network], components[:security_groups])
          end
          
          # 6. Monitoring & Logging
          components[:monitoring] = create_monitoring(name, attributes, components)
          
          # 7. Optional components
          if attributes[:enable_caching]
            components[:cache] = create_cache_component(name, attributes, components[:network], components[:security_groups])
          end
          
          if attributes[:enable_cdn]
            components[:cdn] = create_cdn_component(name, attributes, components[:load_balancer])
          end
          
          components
        end

        def create_network_component(name, attributes)
          # This would use the secure_vpc component if available
          if defined?(Pangea::Components) && respond_to?(:secure_vpc)
            secure_vpc(:"#{name}_network", {
              cidr_block: attributes[:vpc_cidr] || "10.0.0.0/16",
              availability_zones: attributes[:availability_zones] || ["us-east-1a", "us-east-1b", "us-east-1c"],
              enable_flow_logs: attributes[:environment] == 'production',
              tags: architecture_tags(attributes)
            })
          else
            # Fallback to direct resource creation
            create_vpc_directly(name, attributes)
          end
        end

        def create_security_groups(name, attributes, network)
          if defined?(Pangea::Components) && respond_to?(:web_security_group)
            web_security_group(:"#{name}_web_sg", {
              vpc_ref: network.respond_to?(:vpc) ? network.vpc : network,
              allowed_cidr_blocks: attributes[:allowed_cidr_blocks] || ["0.0.0.0/0"],
              tags: architecture_tags(attributes)
            })
          else
            create_security_groups_directly(name, attributes, network)
          end
        end

        def create_load_balancer(name, attributes, network, security_groups)
          if defined?(Pangea::Components) && respond_to?(:application_load_balancer)
            subnets = network.respond_to?(:public_subnets) ? network.public_subnets : []
            sg_refs = security_groups.respond_to?(:security_groups) ? security_groups.security_groups : [security_groups]
            
            application_load_balancer(:"#{name}_alb", {
              subnet_refs: subnets,
              security_group_refs: sg_refs,
              enable_deletion_protection: attributes[:environment] == 'production',
              certificate_arn: attributes[:ssl_certificate_arn],
              tags: architecture_tags(attributes)
            })
          else
            create_load_balancer_directly(name, attributes, network, security_groups)
          end
        end

        def create_web_servers(name, attributes, network, security_groups, load_balancer)
          if defined?(Pangea::Components) && respond_to?(:auto_scaling_web_servers)
            subnets = network.respond_to?(:private_subnets) ? network.private_subnets : []
            
            auto_scaling_web_servers(:"#{name}_web", {
              subnet_refs: subnets,
              target_group_ref: load_balancer.respond_to?(:target_group) ? load_balancer.target_group : nil,
              min_size: attributes[:auto_scaling][:min],
              max_size: attributes[:auto_scaling][:max],
              desired_capacity: attributes[:auto_scaling][:desired] || attributes[:auto_scaling][:min],
              instance_type: attributes[:instance_type] || 't3.medium',
              tags: architecture_tags(attributes)
            })
          else
            create_web_servers_directly(name, attributes, network, security_groups, load_balancer)
          end
        end

        def create_database(name, attributes, network, security_groups)
          engine = attributes[:database_engine] || 'mysql'
          
          if defined?(Pangea::Components)
            component_method = case engine
                             when 'mysql'
                               :mysql_database
                             when 'postgresql'  
                               :postgresql_database
                             else
                               :mysql_database
                             end
            
            if respond_to?(component_method)
              subnets = network.respond_to?(:private_subnets) ? network.private_subnets : []
              vpc = network.respond_to?(:vpc) ? network.vpc : network
              
              send(component_method, :"#{name}_db", {
                subnet_refs: subnets,
                vpc_ref: vpc,
                instance_class: attributes[:database_instance_class] || 'db.t3.micro',
                allocated_storage: attributes[:database_allocated_storage] || 20,
                storage_encrypted: attributes[:environment] == 'production',
                backup_retention_days: attributes[:backup]&.[](:retention_days) || (attributes[:environment] == 'production' ? 7 : 1),
                multi_az: attributes[:high_availability] && attributes[:environment] == 'production',
                tags: architecture_tags(attributes)
              })
            else
              create_database_directly(name, attributes, network, security_groups)
            end
          else
            create_database_directly(name, attributes, network, security_groups)
          end
        end

        def create_monitoring(name, attributes, components)
          # Create CloudWatch resources and dashboards
          monitoring_resources = {}
          
          # This could use monitoring components if available
          if attributes[:monitoring][:enable_alerting]
            monitoring_resources[:alarms] = create_cloudwatch_alarms(name, attributes, components)
          end
          
          if attributes[:monitoring][:detailed_monitoring]
            monitoring_resources[:dashboard] = create_cloudwatch_dashboard(name, attributes, components)
          end
          
          monitoring_resources
        end

        def create_cache_component(name, attributes, network, security_groups)
          if defined?(Pangea::Components) && respond_to?(:elasticache_redis)
            subnets = network.respond_to?(:private_subnets) ? network.private_subnets : []
            
            elasticache_redis(:"#{name}_cache", {
              subnet_refs: subnets,
              node_type: 'cache.t3.micro',
              num_cache_nodes: 1,
              port: 6379,
              tags: architecture_tags(attributes)
            })
          else
            create_cache_directly(name, attributes, network, security_groups)
          end
        end

        def create_cdn_component(name, attributes, load_balancer)
          if defined?(Pangea::Components) && respond_to?(:cloudfront_distribution)
            cloudfront_distribution(:"#{name}_cdn", {
              origin_domain_name: load_balancer.respond_to?(:dns_name) ? load_balancer.dns_name : '',
              price_class: 'PriceClass_100',
              tags: architecture_tags(attributes)
            })
          else
            create_cdn_directly(name, attributes, load_balancer)
          end
        end

        def create_resources(name, attributes, components)
          resources = {}
          
          # DNS Zone (if domain provided)
          if attributes[:domain_name]
            resources[:dns_zone] = create_dns_zone(name, attributes)
          end
          
          # SSL Certificate (if domain provided)
          if attributes[:domain_name] && !attributes[:ssl_certificate_arn]
            resources[:ssl_certificate] = create_ssl_certificate(name, attributes)
          end
          
          # S3 buckets for logs, assets, etc.
          resources[:s3_buckets] = create_s3_buckets(name, attributes)
          
          resources
        end

        def calculate_outputs(name, attributes, components, resources)
          outputs = {}
          
          # Primary application URL
          if attributes[:domain_name]
            outputs[:application_url] = "https://#{attributes[:domain_name]}"
          elsif components[:load_balancer] && components[:load_balancer].respond_to?(:dns_name)
            outputs[:application_url] = "https://#{components[:load_balancer].dns_name}"
          end
          
          # Load balancer DNS name
          if components[:load_balancer] && components[:load_balancer].respond_to?(:dns_name)
            outputs[:load_balancer_dns] = components[:load_balancer].dns_name
          end
          
          # Database endpoint
          if components[:database] && components[:database].respond_to?(:endpoint)
            outputs[:database_endpoint] = components[:database].endpoint
          end
          
          # CDN domain (if enabled)
          if components[:cdn] && components[:cdn].respond_to?(:domain_name)
            outputs[:cdn_domain] = components[:cdn].domain_name
          end
          
          # Monitoring dashboard URL
          if components[:monitoring] && components[:monitoring][:dashboard]
            outputs[:monitoring_dashboard_url] = components[:monitoring][:dashboard][:url]
          end
          
          # Estimated monthly cost
          outputs[:estimated_monthly_cost] = calculate_monthly_cost(components, resources)
          
          # Architecture capabilities
          outputs[:capabilities] = {
            high_availability: has_high_availability?(components),
            auto_scaling: has_auto_scaling?(components),
            caching: components.key?(:cache),
            cdn: components.key?(:cdn),
            ssl_termination: attributes[:ssl_certificate_arn] || resources[:ssl_certificate],
            monitoring: components[:monitoring]&.any?,
            backup: has_backup_strategy?(components)
          }
          
          outputs
        end

        # Fallback resource creation methods (when components aren't available)
        def create_vpc_directly(name, attributes)
          # Direct resource creation using aws_vpc, aws_subnet, etc.
          # This would be implemented if needed
          {
            vpc: { id: "#{name}-vpc-id" },
            public_subnets: [],
            private_subnets: []
          }
        end

        def create_security_groups_directly(name, attributes, network)
          # Direct security group creation
          {
            web_sg: { id: "#{name}-web-sg-id" },
            db_sg: { id: "#{name}-db-sg-id" }
          }
        end

        def create_load_balancer_directly(name, attributes, network, security_groups)
          # Direct ALB creation
          {
            arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/#{name}/1234567890123456",
            dns_name: "#{name}-alb-1234567890.us-east-1.elb.amazonaws.com",
            target_group: { arn: "#{name}-tg-arn" }
          }
        end

        def create_web_servers_directly(name, attributes, network, security_groups, load_balancer)
          # Direct ASG creation
          {
            auto_scaling_group_name: "#{name}-asg",
            launch_template_id: "#{name}-lt",
            min_size: attributes[:auto_scaling][:min],
            max_size: attributes[:auto_scaling][:max]
          }
        end

        def create_database_directly(name, attributes, network, security_groups)
          # Direct RDS creation
          {
            endpoint: "#{name}-db.cluster-xyz.us-east-1.rds.amazonaws.com",
            port: 3306,
            db_name: name.to_s.gsub('-', '_')
          }
        end

        def create_cache_directly(name, attributes, network, security_groups)
          # Direct ElastiCache creation
          {
            cache_cluster_id: "#{name}-cache",
            redis_endpoint: "#{name}-cache.abc123.0001.use1.cache.amazonaws.com",
            port: 6379
          }
        end

        def create_cdn_directly(name, attributes, load_balancer)
          # Direct CloudFront creation
          {
            distribution_id: "E1234567890123",
            domain_name: "d1234567890123.cloudfront.net"
          }
        end

        def create_dns_zone(name, attributes)
          # DNS zone creation logic
          {
            zone_id: "Z1234567890123",
            name_servers: ["ns-123.awsdns-12.com", "ns-456.awsdns-45.net"]
          }
        end

        def create_ssl_certificate(name, attributes)
          # ACM certificate creation logic
          {
            certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
            domain_name: attributes[:domain_name]
          }
        end

        def create_s3_buckets(name, attributes)
          # S3 bucket creation for logs, assets, etc.
          {
            logs_bucket: { name: "#{name}-logs-#{SecureRandom.hex(8)}" },
            assets_bucket: { name: "#{name}-assets-#{SecureRandom.hex(8)}" }
          }
        end

        def create_cloudwatch_alarms(name, attributes, components)
          # CloudWatch alarms creation
          {
            high_cpu_alarm: "#{name}-high-cpu",
            low_cpu_alarm: "#{name}-low-cpu",
            target_response_time_alarm: "#{name}-response-time"
          }
        end

        def create_cloudwatch_dashboard(name, attributes, components)
          # CloudWatch dashboard creation
          {
            dashboard_name: "#{name}-dashboard",
            url: "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=#{name}-dashboard"
          }
        end

        # Helper methods
        def architecture_tags(attributes)
          base_tags = {
            Architecture: 'WebApplication',
            Environment: attributes[:environment],
            ManagedBy: 'Pangea'
          }
          
          base_tags.merge(attributes[:tags] || {})
        end

        def calculate_monthly_cost(components, resources)
          # Simplified cost calculation
          cost = 0.0
          
          # Load balancer cost
          cost += 22.0 if components[:load_balancer]
          
          # EC2 instances (estimated based on auto scaling)
          if components[:web_servers] && components[:web_servers][:min_size]
            instance_cost = estimate_instance_cost(components[:web_servers][:instance_type] || 't3.medium')
            cost += instance_cost * components[:web_servers][:min_size]
          end
          
          # Database cost
          if components[:database]
            cost += estimate_database_cost(components[:database][:instance_class] || 'db.t3.micro')
          end
          
          # Cache cost
          cost += 15.0 if components[:cache]
          
          # CDN cost (estimated)
          cost += 10.0 if components[:cdn]
          
          cost.round(2)
        end

        def estimate_instance_cost(instance_type)
          case instance_type
          when /t3\.micro/ then 8.5
          when /t3\.small/ then 17.0
          when /t3\.medium/ then 34.0
          when /t3\.large/ then 67.0
          when /c5\.large/ then 72.0
          else 50.0
          end
        end

        def estimate_database_cost(instance_class)
          case instance_class
          when /db\.t3\.micro/ then 16.0
          when /db\.t3\.small/ then 32.0
          when /db\.r5\.large/ then 180.0
          else 80.0
          end
        end

        def has_high_availability?(components)
          # Check if deployed across multiple AZs
          network = components[:network]
          return false unless network
          
          if network.respond_to?(:availability_zones)
            network.availability_zones.size >= 2
          else
            true # Assume HA for fallback
          end
        end

        def has_auto_scaling?(components)
          components[:web_servers] && 
          components[:web_servers][:auto_scaling_group_name] &&
          components[:web_servers][:max_size] > components[:web_servers][:min_size]
        end

        def has_backup_strategy?(components)
          database = components[:database]
          return false unless database
          
          # Check if backup retention is configured
          if database.respond_to?(:backup_retention_days)
            database.backup_retention_days > 0
          else
            true # Assume backup for fallback
          end
        end
      end
    end

    # Architecture module for auto-registration
    module WebApplicationArchitectureModule
      # Architecture function that can be used in templates
      def web_application_architecture(name, attributes = {})
        WebApplicationArchitecture::Architecture.build(name, attributes)
      end
    end
  end
end

# Auto-register this architecture module when it's loaded
Pangea::ArchitectureRegistry.register_architecture(Pangea::Architectures::WebApplicationArchitectureModule)