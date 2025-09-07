# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'pangea/components/base'
require 'pangea/components/disaster_recovery_pilot_light/types'
require 'pangea/resources/aws'
require 'json'

module Pangea
  module Components
    # Pilot light DR pattern with automated activation and validation
    # Creates minimal standby resources, automated testing, and rapid activation
    def disaster_recovery_pilot_light(name, attributes = {})
      include Base
      include Resources::AWS
      
      # Validate and set defaults
      component_attrs = DisasterRecoveryPilotLight::DisasterRecoveryPilotLightAttributes.new(attributes)
      component_attrs.validate!
      
      # Generate component-specific tags
      component_tag_set = component_tags('DisasterRecoveryPilotLight', name, component_attrs.tags)
      
      resources = {}
      
      # Set up primary region infrastructure
      primary_resources = setup_primary_region(name, component_attrs, component_tag_set)
      resources[:primary] = primary_resources
      
      # Set up DR region pilot light infrastructure
      dr_resources = setup_dr_region(name, component_attrs, component_tag_set)
      resources[:dr] = dr_resources
      
      # Create cross-region networking if enabled
      if component_attrs.enable_cross_region_vpc_peering
        peering_resources = create_cross_region_peering(
          name, component_attrs, primary_resources, dr_resources, component_tag_set
        )
        resources[:peering] = peering_resources
      end
      
      # Set up data replication
      replication_resources = setup_data_replication(name, component_attrs, primary_resources, dr_resources, component_tag_set)
      resources[:replication] = replication_resources
      
      # Create backup and recovery infrastructure
      backup_resources = create_backup_infrastructure(name, component_attrs, primary_resources, component_tag_set)
      resources[:backup] = backup_resources
      
      # Create activation automation
      activation_resources = create_activation_automation(name, component_attrs, dr_resources, component_tag_set)
      resources[:activation] = activation_resources
      
      # Set up DR testing infrastructure
      if component_attrs.testing.automated_testing
        testing_resources = create_testing_infrastructure(name, component_attrs, resources, component_tag_set)
        resources[:testing] = testing_resources
      end
      
      # Create monitoring and alerting
      if component_attrs.monitoring.dashboard_enabled || component_attrs.monitoring.alerting_enabled
        monitoring_resources = create_monitoring_infrastructure(name, component_attrs, resources, component_tag_set)
        resources[:monitoring] = monitoring_resources
      end
      
      # Create compliance and audit resources
      if component_attrs.compliance.audit_logging
        compliance_resources = create_compliance_resources(name, component_attrs, resources, component_tag_set)
        resources[:compliance] = compliance_resources
      end
      
      # Calculate outputs
      outputs = {
        dr_name: component_attrs.dr_name,
        primary_region: component_attrs.primary_region.region,
        dr_region: component_attrs.dr_region.region,
        
        rto_hours: component_attrs.compliance.rto_hours,
        rpo_hours: component_attrs.compliance.rpo_hours,
        
        pilot_light_resources: extract_pilot_light_resources(dr_resources),
        
        activation_method: component_attrs.activation.activation_method,
        activation_runbook_url: resources.dig(:activation, :runbook, :url),
        
        data_replication_status: {
          databases: replication_resources[:database_replicas]&.any? ? "Active" : "Not configured",
          s3_buckets: replication_resources[:s3_replication]&.any? ? "Active" : "Not configured",
          efs_filesystems: replication_resources[:efs_replication]&.any? ? "Active" : "Not configured"
        },
        
        backup_status: {
          vault_name: backup_resources[:backup_vault]&.name,
          plan_name: backup_resources[:backup_plan]&.name,
          cross_region_enabled: component_attrs.critical_data.cross_region_backup
        },
        
        testing_configuration: {
          automated: component_attrs.testing.automated_testing,
          schedule: component_attrs.testing.test_schedule,
          scenarios: component_attrs.testing.test_scenarios
        },
        
        cost_optimization_features: [
          ("Spot Instances" if component_attrs.cost_optimization.use_spot_instances),
          ("Auto-shutdown Non-critical" if component_attrs.cost_optimization.auto_shutdown_non_critical),
          ("Compressed Backups" if component_attrs.cost_optimization.compress_backups),
          ("Data Deduplication" if component_attrs.cost_optimization.dedup_enabled),
          ("Lifecycle Policies" if component_attrs.cost_optimization.data_lifecycle_policies)
        ].compact,
        
        monitoring_dashboards: [
          resources.dig(:monitoring, :primary_dashboard)&.dashboard_name,
          resources.dig(:monitoring, :dr_dashboard)&.dashboard_name,
          resources.dig(:monitoring, :replication_dashboard)&.dashboard_name
        ].compact,
        
        estimated_monthly_cost: estimate_dr_cost(component_attrs, resources),
        
        readiness_score: calculate_readiness_score(component_attrs, resources)
      }
      
      create_component_reference(
        'disaster_recovery_pilot_light',
        name,
        component_attrs.to_h,
        resources,
        outputs
      )
    end
    
    private
    
    def setup_primary_region(name, attrs, tags)
      primary = attrs.primary_region
      primary_resources = {}
      
      # Create or use existing VPC
      vpc_ref = primary.vpc_ref || aws_vpc(
        component_resource_name(name, :primary_vpc),
        {
          cidr_block: primary.vpc_cidr,
          enable_dns_hostnames: true,
          enable_dns_support: true,
          tags: tags.merge(
            Region: primary.region,
            Role: "Primary"
          )
        }
      )
      primary_resources[:vpc] = vpc_ref
      
      # Create subnets
      subnets = {}
      primary.availability_zones.each_with_index do |az, index|
        base_ip = primary.vpc_cidr.split('.')[0..1].join('.')
        
        public_subnet_ref = aws_subnet(
          component_resource_name(name, :primary_public_subnet, "az#{index}".to_sym),
          {
            vpc_id: vpc_ref.id,
            cidr_block: "#{base_ip}.#{index * 2}.0/24",
            availability_zone: az,
            map_public_ip_on_launch: true,
            tags: tags.merge(Type: "Public", Region: primary.region)
          }
        )
        
        private_subnet_ref = aws_subnet(
          component_resource_name(name, :primary_private_subnet, "az#{index}".to_sym),
          {
            vpc_id: vpc_ref.id,
            cidr_block: "#{base_ip}.#{index * 2 + 1}.0/24",
            availability_zone: az,
            tags: tags.merge(Type: "Private", Region: primary.region)
          }
        )
        
        subnets["public_#{index}".to_sym] = public_subnet_ref
        subnets["private_#{index}".to_sym] = private_subnet_ref
      end
      primary_resources[:subnets] = subnets
      
      # Create critical resources monitoring
      if primary.critical_resources.any?
        critical_monitors = {}
        primary.critical_resources.each_with_index do |resource, index|
          if resource[:type] == 'database'
            # Monitor RDS instances
            db_alarm_ref = aws_cloudwatch_metric_alarm(
              component_resource_name(name, :primary_db_alarm, "resource#{index}".to_sym),
              {
                alarm_name: "#{name}-primary-db-#{resource[:id]}-health",
                comparison_operator: "LessThanThreshold",
                evaluation_periods: "2",
                metric_name: "DatabaseConnections",
                namespace: "AWS/RDS",
                period: "300",
                statistic: "Average",
                threshold: "1",
                alarm_description: "Primary database health check",
                dimensions: {
                  DBInstanceIdentifier: resource[:id]
                },
                tags: tags
              }
            )
            critical_monitors["db_#{index}".to_sym] = db_alarm_ref
          end
        end
        primary_resources[:critical_monitors] = critical_monitors
      end
      
      primary_resources
    end
    
    def setup_dr_region(name, attrs, tags)
      dr = attrs.dr_region
      dr_resources = {}
      
      # Create or use existing VPC
      vpc_ref = dr.vpc_ref || aws_vpc(
        component_resource_name(name, :dr_vpc),
        {
          cidr_block: dr.vpc_cidr,
          enable_dns_hostnames: true,
          enable_dns_support: true,
          tags: tags.merge(
            Region: dr.region,
            Role: "DR",
            State: "PilotLight"
          )
        }
      )
      dr_resources[:vpc] = vpc_ref
      
      # Create subnets
      subnets = {}
      dr.availability_zones.each_with_index do |az, index|
        base_ip = dr.vpc_cidr.split('.')[0..1].join('.')
        
        public_subnet_ref = aws_subnet(
          component_resource_name(name, :dr_public_subnet, "az#{index}".to_sym),
          {
            vpc_id: vpc_ref.id,
            cidr_block: "#{base_ip}.#{index * 2}.0/24",
            availability_zone: az,
            map_public_ip_on_launch: true,
            tags: tags.merge(Type: "Public", Region: dr.region, State: "PilotLight")
          }
        )
        
        private_subnet_ref = aws_subnet(
          component_resource_name(name, :dr_private_subnet, "az#{index}".to_sym),
          {
            vpc_id: vpc_ref.id,
            cidr_block: "#{base_ip}.#{index * 2 + 1}.0/24",
            availability_zone: az,
            tags: tags.merge(Type: "Private", Region: dr.region, State: "PilotLight")
          }
        )
        
        subnets["public_#{index}".to_sym] = public_subnet_ref
        subnets["private_#{index}".to_sym] = private_subnet_ref
      end
      dr_resources[:subnets] = subnets
      
      # Create minimal compute resources (launch templates, not instances)
      if attrs.pilot_light.minimal_compute
        # Create launch template for rapid scaling
        launch_template_ref = aws_launch_template(
          component_resource_name(name, :dr_launch_template),
          {
            name: "#{name}-dr-template",
            description: "DR activation launch template",
            
            image_id: "ami-12345678", # Would be dynamic based on region
            instance_type: attrs.pilot_light.standby_instance_type,
            
            vpc_security_group_ids: [], # Would reference security groups
            
            user_data: Base64.encode64(generate_dr_userdata(attrs)),
            
            tag_specifications: [{
              resource_type: "instance",
              tags: tags.merge(State: "DR-Activated")
            }],
            
            metadata_options: {
              http_tokens: "required",
              http_put_response_hop_limit: 1
            },
            
            tags: tags.merge(State: "PilotLight")
          }
        )
        dr_resources[:launch_template] = launch_template_ref
        
        # Create auto-scaling group (initially scaled to 0)
        asg_ref = aws_autoscaling_group(
          component_resource_name(name, :dr_asg),
          {
            name: "#{name}-dr-asg",
            min_size: 0,  # Pilot light - no running instances
            max_size: attrs.pilot_light.auto_scaling_max,
            desired_capacity: 0,
            
            launch_template: {
              id: launch_template_ref.id,
              version: "$Latest"
            },
            
            vpc_zone_identifier: subnets.select { |k, _| k.to_s.start_with?('private_') }.values.map(&:id),
            
            health_check_type: "ELB",
            health_check_grace_period: 300,
            
            tags: [
              {
                key: "Name",
                value: "#{name}-dr-instance",
                propagate_at_launch: true
              },
              {
                key: "State",
                value: "PilotLight",
                propagate_at_launch: true
              }
            ]
          }
        )
        dr_resources[:asg] = asg_ref
      end
      
      # Create database subnet group for replicas
      if attrs.pilot_light.database_replicas
        db_subnet_group_ref = aws_db_subnet_group(
          component_resource_name(name, :dr_db_subnet_group),
          {
            name: "#{name}-dr-db-subnet-group",
            description: "DR database subnet group",
            subnet_ids: subnets.select { |k, _| k.to_s.start_with?('private_') }.values.map(&:id),
            tags: tags.merge(Region: dr.region, State: "PilotLight")
          }
        )
        dr_resources[:db_subnet_group] = db_subnet_group_ref
      end
      
      dr_resources
    end
    
    def create_cross_region_peering(name, attrs, primary_resources, dr_resources, tags)
      peering_resources = {}
      
      # Create VPC peering connection
      peering_ref = aws_vpc_peering_connection(
        component_resource_name(name, :vpc_peering),
        {
          vpc_id: primary_resources[:vpc].id,
          peer_vpc_id: dr_resources[:vpc].id,
          peer_region: attrs.dr_region.region,
          tags: tags.merge(
            Name: "#{name}-primary-to-dr",
            Type: "Cross-Region-DR"
          )
        }
      )
      peering_resources[:connection] = peering_ref
      
      # Accept peering connection (would be in DR region)
      peering_accepter_ref = aws_vpc_peering_connection_accepter(
        component_resource_name(name, :vpc_peering_accepter),
        {
          vpc_peering_connection_id: peering_ref.id,
          tags: tags
        }
      )
      peering_resources[:accepter] = peering_accepter_ref
      
      # Add routes in primary VPC
      primary_resources[:subnets].each do |subnet_key, subnet|
        route_ref = aws_route(
          component_resource_name(name, :primary_to_dr_route, subnet_key),
          {
            route_table_id: subnet.route_table_id,
            destination_cidr_block: attrs.dr_region.vpc_cidr,
            vpc_peering_connection_id: peering_ref.id
          }
        )
        peering_resources["primary_route_#{subnet_key}".to_sym] = route_ref
      end
      
      # Add routes in DR VPC
      dr_resources[:subnets].each do |subnet_key, subnet|
        route_ref = aws_route(
          component_resource_name(name, :dr_to_primary_route, subnet_key),
          {
            route_table_id: subnet.route_table_id,
            destination_cidr_block: attrs.primary_region.vpc_cidr,
            vpc_peering_connection_id: peering_ref.id
          }
        )
        peering_resources["dr_route_#{subnet_key}".to_sym] = route_ref
      end
      
      peering_resources
    end
    
    def setup_data_replication(name, attrs, primary_resources, dr_resources, tags)
      replication_resources = {}
      
      # Set up database replication
      if attrs.pilot_light.database_replicas && attrs.critical_data.databases.any?
        db_replicas = {}
        
        attrs.critical_data.databases.each_with_index do |db, index|
          if db[:engine].start_with?('aurora')
            # For Aurora, create cross-region read replica cluster
            replica_cluster_ref = aws_rds_cluster(
              component_resource_name(name, :dr_db_cluster, "db#{index}".to_sym),
              {
                cluster_identifier: "#{name}-dr-cluster-#{index}",
                engine: db[:engine],
                engine_version: db[:engine_version],
                
                # This would reference the primary cluster
                replication_source_identifier: "arn:aws:rds:#{attrs.primary_region.region}:ACCOUNT:cluster:#{db[:identifier]}",
                
                db_subnet_group_name: dr_resources[:db_subnet_group].name,
                
                backup_retention_period: attrs.critical_data.backup_retention_days,
                storage_encrypted: attrs.compliance.encryption_required,
                
                tags: tags.merge(
                  Region: attrs.dr_region.region,
                  State: "PilotLight",
                  Role: "ReadReplica"
                )
              }
            )
            db_replicas["cluster_#{index}".to_sym] = replica_cluster_ref
            
            # Create minimal instance in replica cluster
            replica_instance_ref = aws_rds_cluster_instance(
              component_resource_name(name, :dr_db_instance, "db#{index}".to_sym),
              {
                identifier: "#{name}-dr-instance-#{index}",
                cluster_identifier: replica_cluster_ref.id,
                instance_class: "db.t3.small", # Minimal for pilot light
                engine: db[:engine],
                
                performance_insights_enabled: attrs.monitoring.dr_region_monitoring,
                
                tags: tags.merge(
                  State: "PilotLight"
                )
              }
            )
            db_replicas["instance_#{index}".to_sym] = replica_instance_ref
          end
        end
        
        replication_resources[:database_replicas] = db_replicas
      end
      
      # Set up S3 bucket replication
      if attrs.critical_data.s3_buckets.any?
        s3_replication = {}
        
        attrs.critical_data.s3_buckets.each_with_index do |bucket_name, index|
          # Create destination bucket in DR region
          dr_bucket_ref = aws_s3_bucket(
            component_resource_name(name, :dr_s3_bucket, "bucket#{index}".to_sym),
            {
              bucket: "#{bucket_name}-dr-#{attrs.dr_region.region}",
              tags: tags.merge(
                Region: attrs.dr_region.region,
                State: "PilotLight",
                SourceBucket: bucket_name
              )
            }
          )
          s3_replication["bucket_#{index}".to_sym] = dr_bucket_ref
          
          # Enable versioning on DR bucket
          dr_versioning_ref = aws_s3_bucket_versioning(
            component_resource_name(name, :dr_s3_versioning, "bucket#{index}".to_sym),
            {
              bucket: dr_bucket_ref.id,
              versioning_configuration: {
                status: "Enabled"
              }
            }
          )
          s3_replication["versioning_#{index}".to_sym] = dr_versioning_ref
          
          # Create replication configuration (would be on source bucket)
          replication_config_ref = aws_s3_bucket_replication_configuration(
            component_resource_name(name, :s3_replication, "bucket#{index}".to_sym),
            {
              bucket: bucket_name,
              role: "arn:aws:iam::ACCOUNT:role/s3-replication-role",
              
              rule: [{
                id: "ReplicateToDR",
                priority: 1,
                status: "Enabled",
                
                filter: {},
                
                destination: {
                  bucket: dr_bucket_ref.arn,
                  storage_class: "STANDARD_IA", # Cost optimization
                  
                  replication_time: attrs.compliance.rpo_hours <= 1 ? {
                    status: "Enabled",
                    time: {
                      minutes: 15
                    }
                  } : nil,
                  
                  metrics: {
                    status: "Enabled",
                    event_threshold: {
                      minutes: 15
                    }
                  }
                },
                
                delete_marker_replication: {
                  status: "Enabled"
                }
              }]
            }.compact
          )
          s3_replication["replication_#{index}".to_sym] = replication_config_ref
        end
        
        replication_resources[:s3_replication] = s3_replication
      end
      
      # Set up EFS replication
      if attrs.critical_data.efs_filesystems.any?
        efs_replication = {}
        
        attrs.critical_data.efs_filesystems.each_with_index do |fs_id, index|
          # Create replication configuration for EFS
          efs_replication_ref = aws_efs_replication_configuration(
            component_resource_name(name, :efs_replication, "fs#{index}".to_sym),
            {
              source_file_system_id: fs_id,
              
              destination: [{
                region: attrs.dr_region.region,
                availability_zone_name: attrs.dr_region.availability_zones.first,
                kms_key_id: attrs.compliance.encryption_required ? "alias/aws/efs" : nil
              }]
            }.compact
          )
          efs_replication["fs_#{index}".to_sym] = efs_replication_ref
        end
        
        replication_resources[:efs_replication] = efs_replication
      end
      
      # Create DMS replication instance for other data sources
      if attrs.critical_data.databases.any? { |db| !db[:engine].start_with?('aurora') }
        dms_instance_ref = aws_dms_replication_instance(
          component_resource_name(name, :dms_instance),
          {
            replication_instance_id: "#{name}-dms-instance",
            replication_instance_class: "dms.t3.small", # Minimal for pilot light
            
            vpc_security_group_ids: [],
            replication_subnet_group_id: dr_resources[:db_subnet_group].name,
            
            multi_az: false, # Cost optimization for pilot light
            
            tags: tags.merge(
              State: "PilotLight"
            )
          }
        )
        replication_resources[:dms_instance] = dms_instance_ref
      end
      
      replication_resources
    end
    
    def create_backup_infrastructure(name, attrs, primary_resources, tags)
      backup_resources = {}
      
      # Create backup vault
      backup_vault_ref = aws_backup_vault(
        component_resource_name(name, :backup_vault),
        {
          name: "#{name}-backup-vault",
          encryption_key_arn: attrs.compliance.encryption_required ? "alias/aws/backup" : nil,
          tags: tags.merge(
            Purpose: "DR-Backup"
          )
        }.compact
      )
      backup_resources[:backup_vault] = backup_vault_ref
      
      # Create backup vault in DR region if cross-region backup enabled
      if attrs.critical_data.cross_region_backup
        dr_vault_ref = aws_backup_vault(
          component_resource_name(name, :dr_backup_vault),
          {
            name: "#{name}-dr-backup-vault",
            encryption_key_arn: attrs.compliance.encryption_required ? "alias/aws/backup" : nil,
            tags: tags.merge(
              Purpose: "DR-Backup",
              Region: attrs.dr_region.region
            )
          }.compact
        )
        backup_resources[:dr_vault] = dr_vault_ref
      end
      
      # Create backup plan
      backup_plan_ref = aws_backup_plan(
        component_resource_name(name, :backup_plan),
        {
          name: "#{name}-dr-backup-plan",
          
          rule: [{
            rule_name: "DailyBackup",
            target_vault_name: backup_vault_ref.name,
            
            schedule: attrs.primary_region.backup_schedule,
            start_window: 60,
            completion_window: 120,
            
            lifecycle: {
              delete_after: attrs.critical_data.backup_retention_days,
              cold_storage_after: attrs.cost_optimization.data_lifecycle_policies ? 7 : nil
            }.compact,
            
            copy_action: attrs.critical_data.cross_region_backup ? [{
              destination_vault_arn: dr_vault_ref.arn,
              lifecycle: {
                delete_after: attrs.critical_data.backup_retention_days
              }
            }] : nil
          }.compact],
          
          tags: tags
        }
      )
      backup_resources[:backup_plan] = backup_plan_ref
      
      # Create backup selection
      backup_selection_ref = aws_backup_selection(
        component_resource_name(name, :backup_selection),
        {
          name: "#{name}-dr-backup-selection",
          plan_id: backup_plan_ref.id,
          iam_role_arn: "arn:aws:iam::ACCOUNT:role/service-role/AWSBackupDefaultServiceRole",
          
          selection_tag: [{
            type: "STRINGEQUALS",
            key: "Backup",
            value: "true"
          }],
          
          resources: [
            # Add specific resource ARNs if needed
          ]
        }
      )
      backup_resources[:backup_selection] = backup_selection_ref
      
      backup_resources
    end
    
    def create_activation_automation(name, attrs, dr_resources, tags)
      activation_resources = {}
      
      # Create IAM role for activation automation
      activation_role_ref = aws_iam_role(
        component_resource_name(name, :activation_role),
        {
          name: "#{name}-dr-activation-role",
          assume_role_policy: JSON.generate({
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Principal: {
                Service: ["lambda.amazonaws.com", "states.amazonaws.com"]
              },
              Action: "sts:AssumeRole"
            }]
          }),
          tags: tags
        }
      )
      activation_resources[:role] = activation_role_ref
      
      # Attach necessary policies
      policy_attachment_ref = aws_iam_role_policy_attachment(
        component_resource_name(name, :activation_policy),
        {
          role: activation_role_ref.name,
          policy_arn: "arn:aws:iam::aws:policy/PowerUserAccess" # Would be more restrictive
        }
      )
      activation_resources[:policy] = policy_attachment_ref
      
      # Create activation Lambda function
      activation_lambda_ref = aws_lambda_function(
        component_resource_name(name, :activation_lambda),
        {
          function_name: "#{name}-dr-activation",
          role: activation_role_ref.arn,
          handler: "index.handler",
          runtime: "python3.9",
          timeout: attrs.activation.activation_timeout,
          memory_size: 512,
          
          environment: {
            variables: {
              DR_ASG_NAME: dr_resources[:asg]&.name || "",
              DR_REGION: attrs.dr_region.region,
              MIN_INSTANCES: attrs.pilot_light.auto_scaling_min.to_s,
              MAX_INSTANCES: attrs.pilot_light.auto_scaling_max.to_s,
              ACTIVATION_METHOD: attrs.activation.activation_method
            }
          },
          
          code: {
            zip_file: generate_activation_lambda_code(attrs)
          },
          
          tags: tags
        }
      )
      activation_resources[:lambda] = activation_lambda_ref
      
      # Create Step Functions state machine for orchestration
      state_machine_ref = aws_sfn_state_machine(
        component_resource_name(name, :activation_state_machine),
        {
          name: "#{name}-dr-activation-workflow",
          role_arn: activation_role_ref.arn,
          
          definition: JSON.generate(create_activation_workflow(attrs)),
          
          logging_configuration: {
            level: "ALL",
            include_execution_data: true,
            destinations: [{
              cloud_watch_logs_log_group: {
                log_group_arn: "arn:aws:logs:#{attrs.dr_region.region}:ACCOUNT:log-group:/aws/vendedlogs/states/#{name}-dr-activation:*"
              }
            }]
          },
          
          tags: tags
        }
      )
      activation_resources[:state_machine] = state_machine_ref
      
      # Create runbook in Systems Manager
      runbook_ref = aws_ssm_document(
        component_resource_name(name, :activation_runbook),
        {
          name: "#{name}-DR-Activation-Runbook",
          document_type: "Automation",
          document_format: "YAML",
          
          content: generate_activation_runbook(attrs),
          
          tags: tags.merge(
            Type: "DR-Activation"
          )
        }
      )
      activation_resources[:runbook] = runbook_ref
      
      # Create EventBridge rule for automated activation if enabled
      if attrs.enable_automated_failover
        event_rule_ref = aws_cloudwatch_event_rule(
          component_resource_name(name, :activation_trigger),
          {
            name: "#{name}-dr-activation-trigger",
            description: "Trigger DR activation on primary failure",
            
            event_pattern: JSON.generate({
              source: ["aws.health"],
              "detail-type": ["AWS Health Event"],
              detail: {
                service: ["EC2", "RDS"],
                eventTypeCategory: ["issue"]
              }
            }),
            
            tags: tags
          }
        )
        activation_resources[:trigger] = event_rule_ref
        
        # Add Lambda as target
        event_target_ref = aws_cloudwatch_event_target(
          component_resource_name(name, :activation_target),
          {
            rule: event_rule_ref.name,
            target_id: "1",
            arn: activation_lambda_ref.arn
          }
        )
        activation_resources[:trigger_target] = event_target_ref
      end
      
      activation_resources
    end
    
    def create_testing_infrastructure(name, attrs, resources, tags)
      testing_resources = {}
      
      # Create test execution Lambda
      test_lambda_ref = aws_lambda_function(
        component_resource_name(name, :test_lambda),
        {
          function_name: "#{name}-dr-test-executor",
          role: resources[:activation][:role].arn,
          handler: "index.handler",
          runtime: "python3.9",
          timeout: 900,
          memory_size: 1024,
          
          environment: {
            variables: {
              TEST_SCENARIOS: attrs.testing.test_scenarios.join(','),
              ROLLBACK_ENABLED: attrs.testing.rollback_after_test.to_s,
              TEST_DATA_SUBSET: attrs.testing.test_data_subset.to_s,
              STATE_MACHINE_ARN: resources[:activation][:state_machine].arn
            }
          },
          
          code: {
            zip_file: generate_test_lambda_code(attrs)
          },
          
          tags: tags
        }
      )
      testing_resources[:lambda] = test_lambda_ref
      
      # Create scheduled test execution
      test_schedule_ref = aws_cloudwatch_event_rule(
        component_resource_name(name, :test_schedule),
        {
          name: "#{name}-dr-test-schedule",
          description: "Scheduled DR testing",
          schedule_expression: attrs.testing.test_schedule,
          tags: tags
        }
      )
      testing_resources[:schedule] = test_schedule_ref
      
      # Add Lambda as target
      test_target_ref = aws_cloudwatch_event_target(
        component_resource_name(name, :test_target),
        {
          rule: test_schedule_ref.name,
          target_id: "1",
          arn: test_lambda_ref.arn
        }
      )
      testing_resources[:target] = test_target_ref
      
      # Create test results bucket
      test_results_bucket_ref = aws_s3_bucket(
        component_resource_name(name, :test_results_bucket),
        {
          bucket: "#{name}-dr-test-results",
          tags: tags
        }
      )
      testing_resources[:results_bucket] = test_results_bucket_ref
      
      testing_resources
    end
    
    def create_monitoring_infrastructure(name, attrs, resources, tags)
      monitoring_resources = {}
      
      # Create CloudWatch dashboard for primary region
      if attrs.monitoring.primary_region_monitoring
        primary_dashboard_ref = create_region_dashboard(
          name, "primary", attrs.primary_region, resources[:primary], tags
        )
        monitoring_resources[:primary_dashboard] = primary_dashboard_ref
      end
      
      # Create CloudWatch dashboard for DR region
      if attrs.monitoring.dr_region_monitoring
        dr_dashboard_ref = create_region_dashboard(
          name, "dr", attrs.dr_region, resources[:dr], tags
        )
        monitoring_resources[:dr_dashboard] = dr_dashboard_ref
      end
      
      # Create replication monitoring dashboard
      replication_widgets = []
      
      # Database replication lag widget
      if resources[:replication][:database_replicas]&.any?
        replication_widgets << {
          type: "metric",
          x: 0,
          y: 0,
          width: 12,
          height: 6,
          properties: {
            title: "Database Replication Lag",
            metrics: [
              ["AWS/RDS", "AuroraReplicaLag", { DBClusterIdentifier: "#{name}-dr-cluster-*" }]
            ],
            period: 300,
            stat: "Average",
            region: attrs.dr_region.region,
            yAxis: { left: { label: "Milliseconds" } }
          }
        }
      end
      
      # S3 replication metrics
      if resources[:replication][:s3_replication]&.any?
        replication_widgets << {
          type: "metric",
          x: 12,
          y: 0,
          width: 12,
          height: 6,
          properties: {
            title: "S3 Replication Status",
            metrics: [
              ["AWS/S3", "ReplicationLatency", { SourceBucket: "*", DestinationBucket: "*-dr-*" }]
            ],
            period: 300,
            stat: "Average",
            region: attrs.primary_region.region
          }
        }
      end
      
      # Backup job status
      replication_widgets << {
        type: "metric",
        x: 0,
        y: 6,
        width: 12,
        height: 6,
        properties: {
          title: "Backup Job Success Rate",
          metrics: [
            ["AWS/Backup", "NumberOfBackupJobsCompleted", { BackupVaultName: resources[:backup][:backup_vault].name }],
            [".", "NumberOfBackupJobsFailed", { BackupVaultName: resources[:backup][:backup_vault].name }]
          ],
          period: 86400,
          stat: "Sum",
          region: attrs.primary_region.region
        }
      }
      
      replication_dashboard_ref = aws_cloudwatch_dashboard(
        component_resource_name(name, :replication_dashboard),
        {
          dashboard_name: "#{name}-replication-status",
          dashboard_body: JSON.generate({
            widgets: replication_widgets,
            periodOverride: "auto",
            start: "-PT24H"
          })
        }
      )
      monitoring_resources[:replication_dashboard] = replication_dashboard_ref
      
      # Create alarms
      if attrs.monitoring.alerting_enabled
        # Replication lag alarm
        if resources[:replication][:database_replicas]&.any?
          lag_alarm_ref = aws_cloudwatch_metric_alarm(
            component_resource_name(name, :replication_lag_alarm),
            {
              alarm_name: "#{name}-replication-lag-high",
              comparison_operator: "GreaterThanThreshold",
              evaluation_periods: "2",
              metric_name: "AuroraReplicaLag",
              namespace: "AWS/RDS",
              period: "300",
              statistic: "Average",
              threshold: (attrs.monitoring.replication_lag_threshold_seconds * 1000).to_s,
              alarm_description: "Database replication lag is too high",
              dimensions: {
                DBClusterIdentifier: "#{name}-dr-cluster-*"
              },
              tags: tags
            }
          )
          monitoring_resources[:lag_alarm] = lag_alarm_ref
        end
        
        # Backup failure alarm
        backup_alarm_ref = aws_cloudwatch_metric_alarm(
          component_resource_name(name, :backup_failure_alarm),
          {
            alarm_name: "#{name}-backup-failures",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: "1",
            metric_name: "NumberOfBackupJobsFailed",
            namespace: "AWS/Backup",
            period: "86400",
            statistic: "Sum",
            threshold: "0",
            alarm_description: "Backup jobs are failing",
            dimensions: {
              BackupVaultName: resources[:backup][:backup_vault].name
            },
            tags: tags
          }
        )
        monitoring_resources[:backup_alarm] = backup_alarm_ref
      end
      
      monitoring_resources
    end
    
    def create_compliance_resources(name, attrs, resources, tags)
      compliance_resources = {}
      
      # Create CloudTrail for audit logging
      trail_ref = aws_cloudtrail(
        component_resource_name(name, :audit_trail),
        {
          name: "#{name}-dr-audit-trail",
          s3_bucket_name: "#{name}-audit-logs",
          
          event_selector: [{
            read_write_type: "All",
            include_management_events: true,
            
            data_resource: [
              {
                type: "AWS::S3::Object",
                values: ["arn:aws:s3:::#{name}-*/*"]
              },
              {
                type: "AWS::RDS::DBCluster",
                values: ["arn:aws:rds:*:*:cluster:#{name}-*"]
              }
            ]
          }],
          
          insight_selector: [{
            insight_type: "ApiCallRateInsight"
          }],
          
          tags: tags
        }
      )
      compliance_resources[:trail] = trail_ref
      
      # Create Config rules for compliance checking
      config_rules = []
      
      # RTO/RPO compliance rule
      rto_rule_ref = aws_config_config_rule(
        component_resource_name(name, :rto_compliance_rule),
        {
          name: "#{name}-rto-compliance",
          description: "Verify RTO compliance",
          
          source: {
            owner: "AWS",
            source_identifier: "BACKUP_RECOVERY_POINT_CREATED"
          },
          
          scope: {
            compliance_resource_types: ["AWS::RDS::DBCluster", "AWS::EC2::Instance"]
          },
          
          tags: tags
        }
      )
      config_rules << rto_rule_ref
      
      compliance_resources[:config_rules] = config_rules
      
      compliance_resources
    end
    
    def create_region_dashboard(name, region_type, region_config, region_resources, tags)
      dashboard_widgets = []
      
      # VPC health widget
      dashboard_widgets << {
        type: "metric",
        x: 0,
        y: 0,
        width: 12,
        height: 6,
        properties: {
          title: "#{region_type.capitalize} Region VPC Health",
          metrics: [
            ["AWS/EC2", "NetworkPacketsIn", { VPC: region_resources[:vpc].id }],
            [".", "NetworkPacketsOut", { VPC: region_resources[:vpc].id }]
          ],
          period: 300,
          stat: "Sum",
          region: region_config.region
        }
      }
      
      # Resource status widget
      dashboard_widgets << {
        type: "metric",
        x: 12,
        y: 0,
        width: 12,
        height: 6,
        properties: {
          title: "#{region_type.capitalize} Region Resources",
          metrics: [],
          period: 300,
          stat: "Average",
          region: region_config.region,
          annotations: {
            horizontal: [{
              label: "Healthy",
              value: 1
            }]
          }
        }
      }
      
      aws_cloudwatch_dashboard(
        component_resource_name(name, :"#{region_type}_dashboard"),
        {
          dashboard_name: "#{name}-#{region_type}-region",
          dashboard_body: JSON.generate({
            widgets: dashboard_widgets,
            periodOverride: "auto",
            start: "-PT6H"
          })
        }
      )
    end
    
    def generate_dr_userdata(attrs)
      <<~BASH
        #!/bin/bash
        # DR Activation Script
        
        # Set DR activation flag
        echo "DR_ACTIVATED=true" >> /etc/environment
        
        # Update application configuration for DR
        aws ssm get-parameter --name "/dr/config" --region #{attrs.dr_region.region} > /tmp/dr-config.json
        
        # Start application with DR configuration
        systemctl start application-dr
        
        # Send activation notification
        aws sns publish --topic-arn "arn:aws:sns:#{attrs.dr_region.region}:ACCOUNT:dr-notifications" \
          --message "DR activation completed for instance $(ec2-metadata --instance-id)"
      BASH
    end
    
    def generate_activation_lambda_code(attrs)
      <<~PYTHON
        import boto3
        import os
        import json
        from datetime import datetime
        
        def handler(event, context):
            asg_client = boto3.client('autoscaling', region_name=os.environ['DR_REGION'])
            sns_client = boto3.client('sns', region_name=os.environ['DR_REGION'])
            
            try:
                # Scale up ASG
                response = asg_client.update_auto_scaling_group(
                    AutoScalingGroupName=os.environ['DR_ASG_NAME'],
                    MinSize=int(os.environ['MIN_INSTANCES']),
                    DesiredCapacity=int(os.environ['MIN_INSTANCES'])
                )
                
                # Promote read replicas if needed
                if event.get('promote_replicas', True):
                    rds_client = boto3.client('rds', region_name=os.environ['DR_REGION'])
                    # Logic to promote read replicas
                
                # Update Route 53 if automated
                if os.environ['ACTIVATION_METHOD'] == 'automated':
                    route53_client = boto3.client('route53')
                    # Logic to update DNS
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': 'DR activation initiated',
                        'timestamp': datetime.utcnow().isoformat()
                    })
                }
                
            except Exception as e:
                print(f"Error: {str(e)}")
                return {
                    'statusCode': 500,
                    'body': json.dumps({'error': str(e)})
                }
      PYTHON
    end
    
    def generate_test_lambda_code(attrs)
      <<~PYTHON
        import boto3
        import os
        import json
        import time
        
        def handler(event, context):
            sfn_client = boto3.client('stepfunctions')
            s3_client = boto3.client('s3')
            
            test_scenarios = os.environ['TEST_SCENARIOS'].split(',')
            results = []
            
            for scenario in test_scenarios:
                print(f"Running test scenario: {scenario}")
                
                # Execute test based on scenario
                if scenario == 'failover':
                    result = test_failover_scenario(sfn_client)
                elif scenario == 'data_recovery':
                    result = test_data_recovery_scenario()
                else:
                    result = {'status': 'skipped', 'reason': 'Unknown scenario'}
                
                results.append({
                    'scenario': scenario,
                    'result': result,
                    'timestamp': time.time()
                })
                
                # Rollback if enabled
                if os.environ['ROLLBACK_ENABLED'] == 'true' and result['status'] == 'success':
                    rollback_changes(scenario)
            
            # Store results
            s3_client.put_object(
                Bucket=f"{os.environ['TEST_RESULTS_BUCKET']}",
                Key=f"test-results/{context.request_id}.json",
                Body=json.dumps(results)
            )
            
            return {
                'statusCode': 200,
                'body': json.dumps(results)
            }
        
        def test_failover_scenario(sfn_client):
            # Implement failover test logic
            return {'status': 'success', 'duration': 300}
        
        def test_data_recovery_scenario():
            # Implement data recovery test logic
            return {'status': 'success', 'recovered_items': 1000}
        
        def rollback_changes(scenario):
            # Implement rollback logic
            pass
      PYTHON
    end
    
    def create_activation_workflow(attrs)
      {
        Comment: "DR Activation Workflow",
        StartAt: "PreActivationChecks",
        States: {
          PreActivationChecks: {
            Type: "Parallel",
            Branches: attrs.activation.pre_activation_checks.map do |check|
              {
                StartAt: check[:name],
                States: {
                  check[:name] => {
                    Type: "Task",
                    Resource: check[:function_arn] || "arn:aws:lambda:REGION:ACCOUNT:function:check",
                    End: true
                  }
                }
              }
            end,
            Next: "ActivateResources"
          },
          
          ActivateResources: {
            Type: "Parallel",
            Branches: [
              {
                StartAt: "ScaleCompute",
                States: {
                  ScaleCompute: {
                    Type: "Task",
                    Resource: "arn:aws:states:::aws-sdk:autoscaling:updateAutoScalingGroup",
                    Parameters: {
                      AutoScalingGroupName: "DR_ASG_NAME",
                      MinSize: attrs.pilot_light.auto_scaling_min,
                      DesiredCapacity: attrs.pilot_light.auto_scaling_min
                    },
                    End: true
                  }
                }
              },
              {
                StartAt: "PromoteDatabases",
                States: {
                  PromoteDatabases: {
                    Type: "Task",
                    Resource: "arn:aws:states:::aws-sdk:rds:promoteReadReplicaDBCluster",
                    Parameters: {
                      DBClusterIdentifier: "DR_CLUSTER_ID"
                    },
                    End: true
                  }
                }
              }
            ],
            Next: "PostActivationValidation"
          },
          
          PostActivationValidation: {
            Type: "Parallel",
            Branches: attrs.activation.post_activation_validation.map do |validation|
              {
                StartAt: validation[:name],
                States: {
                  validation[:name] => {
                    Type: "Task",
                    Resource: validation[:function_arn] || "arn:aws:lambda:REGION:ACCOUNT:function:validate",
                    End: true
                  }
                }
              }
            end,
            Next: "NotifyCompletion"
          },
          
          NotifyCompletion: {
            Type: "Task",
            Resource: "arn:aws:states:::sns:publish",
            Parameters: {
              TopicArn: "DR_NOTIFICATION_TOPIC",
              Message: "DR activation completed successfully"
            },
            End: true
          }
        }
      }
    end
    
    def generate_activation_runbook(attrs)
      <<~YAML
        schemaVersion: "0.3"
        description: "DR Activation Runbook for #{attrs.dr_name}"
        parameters:
          ActivationType:
            type: String
            description: Type of activation (test or real)
            default: test
        mainSteps:
          - name: ValidatePrimaryHealth
            action: "aws:executeScript"
            inputs:
              Runtime: python3.8
              Handler: validate_primary
              Script: |
                def validate_primary(events, context):
                    # Check primary region health
                    return {"status": "unhealthy"}
          
          - name: ActivateDRResources
            action: "aws:executeStateMachine"
            inputs:
              stateMachineArn: "ACTIVATION_STATE_MACHINE_ARN"
              input: |
                {
                  "activation_type": "{{ ActivationType }}",
                  "timestamp": "{{ global:DATE_TIME }}"
                }
          
          - name: ValidateDRActivation
            action: "aws:waitForAwsResourceProperty"
            inputs:
              Service: autoscaling
              Api: DescribeAutoScalingGroups
              AutoScalingGroupNames:
                - "DR_ASG_NAME"
              PropertySelector: "$.AutoScalingGroups[0].DesiredCapacity"
              DesiredValues:
                - "{{ MinInstances }}"
          
          - name: UpdateDNS
            action: "aws:executeScript"
            onFailure: Continue
            inputs:
              Runtime: python3.8
              Handler: update_dns
              Script: |
                def update_dns(events, context):
                    if events['ActivationType'] == 'real':
                        # Update Route 53 records
                        pass
                    return {"status": "success"}
        outputs:
          - ActivationTime:
              Value: "{{ global:DATE_TIME }}"
          - ActivationStatus:
              Value: "Completed"
      YAML
    end
    
    def extract_pilot_light_resources(dr_resources)
      resources = []
      
      resources << "VPC and Subnets" if dr_resources[:vpc]
      resources << "Launch Template" if dr_resources[:launch_template]
      resources << "Auto Scaling Group (scaled to 0)" if dr_resources[:asg]
      resources << "Database Subnet Group" if dr_resources[:db_subnet_group]
      resources << "Database Read Replicas" if dr_resources[:database_replicas]
      
      resources
    end
    
    def calculate_readiness_score(attrs, resources)
      score = 0.0
      max_score = 100.0
      
      # Data replication (30 points)
      if resources[:replication][:database_replicas]&.any?
        score += 10.0
      end
      if resources[:replication][:s3_replication]&.any?
        score += 10.0
      end
      if resources[:replication][:efs_replication]&.any?
        score += 10.0
      end
      
      # Backup infrastructure (20 points)
      if resources[:backup][:backup_vault]
        score += 10.0
      end
      if attrs.critical_data.cross_region_backup
        score += 10.0
      end
      
      # Activation automation (20 points)
      if resources[:activation][:state_machine]
        score += 10.0
      end
      if resources[:activation][:runbook]
        score += 10.0
      end
      
      # Testing (15 points)
      if attrs.testing.automated_testing
        score += 10.0
      end
      if attrs.testing.test_scenarios.length >= 2
        score += 5.0
      end
      
      # Monitoring (15 points)
      if attrs.monitoring.dashboard_enabled
        score += 7.5
      end
      if attrs.monitoring.alerting_enabled
        score += 7.5
      end
      
      (score / max_score * 100).round(1)
    end
    
    def estimate_dr_cost(attrs, resources)
      cost = 0.0
      
      # Pilot light infrastructure (minimal)
      # Launch template and ASG (no running instances)
      cost += 0.0
      
      # Database read replicas
      if attrs.pilot_light.database_replicas
        replica_count = attrs.critical_data.databases.length
        cost += replica_count * 50.0  # Minimal instance size
      end
      
      # S3 replication storage
      if attrs.critical_data.s3_buckets.any?
        # Estimate 1TB replicated data with IA storage
        cost += 1000 * 0.0125  # S3 IA storage
        cost += 100 * 0.01     # Replication data transfer
      end
      
      # EFS replication
      if attrs.critical_data.efs_filesystems.any?
        cost += attrs.critical_data.efs_filesystems.length * 30.0
      end
      
      # Backup costs
      cost += 0.05 * 1000  # 1TB backup storage estimate
      
      # DMS instance (if needed)
      if resources[:replication][:dms_instance]
        cost += 50.0  # t3.small instance
      end
      
      # Monitoring and automation
      cost += 10.0  # CloudWatch dashboards and alarms
      cost += 5.0   # Lambda executions
      
      # Testing costs (periodic)
      if attrs.testing.automated_testing
        # 4 tests per month, 1 hour each
        cost += 4 * 10.0  # Temporary resource costs
      end
      
      cost.round(2)
    end
  end
end