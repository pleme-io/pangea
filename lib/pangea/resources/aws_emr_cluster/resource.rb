# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_emr_cluster/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EMR Cluster with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] EMR Cluster attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_emr_cluster(name, attributes = {})
        # Validate attributes using dry-struct
        cluster_attrs = Types::EmrClusterAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_emr_cluster, name) do
          # Required attributes
          cluster_name = cluster_attrs.name
          release_label cluster_attrs.release_label
          service_role cluster_attrs.service_role
          
          # Applications
          if cluster_attrs.applications.any?
            cluster_attrs.applications.each do |app|
              applications app
            end
          end
          
          # Configurations
          cluster_attrs.configurations.each do |config|
            configurations do
              classification config[:classification]
              
              if config[:configurations]
                config[:configurations].each do |sub_config|
                  configurations do
                    classification sub_config[:classification] if sub_config[:classification]
                    
                    if sub_config[:properties]&.any?
                      properties do
                        sub_config[:properties].each do |key, value|
                          public_send(key.gsub(/[^a-zA-Z0-9_]/, '_').downcase, value)
                        end
                      end
                    end
                  end
                end
              end
              
              if config[:properties]&.any?
                properties do
                  config[:properties].each do |key, value|
                    public_send(key.gsub(/[^a-zA-Z0-9_]/, '_').downcase, value)
                  end
                end
              end
            end
          end
          
          # EC2 attributes
          ec2_attributes do
            ec2_attrs = cluster_attrs.ec2_attributes
            instance_profile ec2_attrs[:instance_profile]
            key_name ec2_attrs[:key_name] if ec2_attrs[:key_name]
            
            emr_managed_master_security_group ec2_attrs[:emr_managed_master_security_group] if ec2_attrs[:emr_managed_master_security_group]
            emr_managed_slave_security_group ec2_attrs[:emr_managed_slave_security_group] if ec2_attrs[:emr_managed_slave_security_group]
            service_access_security_group ec2_attrs[:service_access_security_group] if ec2_attrs[:service_access_security_group]
            
            additional_master_security_groups ec2_attrs[:additional_master_security_groups] if ec2_attrs[:additional_master_security_groups]&.any?
            additional_slave_security_groups ec2_attrs[:additional_slave_security_groups] if ec2_attrs[:additional_slave_security_groups]&.any?
            
            subnet_id ec2_attrs[:subnet_id] if ec2_attrs[:subnet_id]
            subnet_ids ec2_attrs[:subnet_ids] if ec2_attrs[:subnet_ids]&.any?
          end
          
          # Master instance group
          master_instance_group do
            mig = cluster_attrs.master_instance_group
            instance_type mig[:instance_type]
            instance_count mig[:instance_count] if mig[:instance_count]
          end
          
          # Core instance group
          if cluster_attrs.core_instance_group
            core_instance_group do
              cig = cluster_attrs.core_instance_group
              instance_type cig[:instance_type]
              instance_count cig[:instance_count] if cig[:instance_count]
              bid_price cig[:bid_price] if cig[:bid_price]
              
              if cig[:ebs_config]
                ebs_config do
                  ebs_cfg = cig[:ebs_config]
                  ebs_optimized ebs_cfg[:ebs_optimized] unless ebs_cfg[:ebs_optimized].nil?
                  
                  if ebs_cfg[:ebs_block_device_config]&.any?
                    ebs_cfg[:ebs_block_device_config].each do |device_config|
                      ebs_block_device_config do
                        volumes_per_instance device_config[:volumes_per_instance] if device_config[:volumes_per_instance]
                        
                        volume_specification do
                          vol_spec = device_config[:volume_specification]
                          volume_type vol_spec[:volume_type]
                          size_in_gb vol_spec[:size_in_gb]
                          iops vol_spec[:iops] if vol_spec[:iops]
                        end
                      end
                    end
                  end
                end
              end
            end
          end
          
          # Task instance groups
          cluster_attrs.task_instance_groups.each do |task_group|
            task_instance_groups do
              name task_group[:name] if task_group[:name]
              instance_role task_group[:instance_role]
              instance_type task_group[:instance_type]
              instance_count task_group[:instance_count]
              bid_price task_group[:bid_price] if task_group[:bid_price]
              
              if task_group[:ebs_config]
                ebs_config do
                  ebs_cfg = task_group[:ebs_config]
                  ebs_optimized ebs_cfg[:ebs_optimized] unless ebs_cfg[:ebs_optimized].nil?
                  
                  if ebs_cfg[:ebs_block_device_config]&.any?
                    ebs_cfg[:ebs_block_device_config].each do |device_config|
                      ebs_block_device_config do
                        volumes_per_instance device_config[:volumes_per_instance] if device_config[:volumes_per_instance]
                        
                        volume_specification do
                          vol_spec = device_config[:volume_specification]
                          volume_type vol_spec[:volume_type]
                          size_in_gb vol_spec[:size_in_gb]
                          iops vol_spec[:iops] if vol_spec[:iops]
                        end
                      end
                    end
                  end
                end
              end
              
              if task_group[:auto_scaling_policy]
                auto_scaling_policy do
                  asp = task_group[:auto_scaling_policy]
                  
                  constraints do
                    constraints_config = asp[:constraints]
                    min_capacity constraints_config[:min_capacity]
                    max_capacity constraints_config[:max_capacity]
                  end
                  
                  asp[:rules].each do |rule|
                    rules do
                      name rule[:name]
                      description rule[:description] if rule[:description]
                      
                      action do
                        action_config = rule[:action]
                        market action_config[:market] if action_config[:market]
                        
                        simple_scaling_policy_configuration do
                          sspc = action_config[:simple_scaling_policy_configuration]
                          adjustment_type sspc[:adjustment_type] if sspc[:adjustment_type]
                          scaling_adjustment sspc[:scaling_adjustment]
                          cool_down sspc[:cool_down] if sspc[:cool_down]
                        end
                      end
                      
                      trigger do
                        cloud_watch_alarm_definition do
                          cwad = rule[:trigger][:cloud_watch_alarm_definition]
                          comparison_operator cwad[:comparison_operator]
                          evaluation_periods cwad[:evaluation_periods]
                          metric_name cwad[:metric_name]
                          namespace cwad[:namespace]
                          period cwad[:period]
                          statistic cwad[:statistic] if cwad[:statistic]
                          threshold cwad[:threshold]
                          unit cwad[:unit] if cwad[:unit]
                          
                          if cwad[:dimensions]&.any?
                            dimensions do
                              cwad[:dimensions].each do |dim_key, dim_value|
                                public_send(dim_key.gsub(/[^a-zA-Z0-9_]/, '_').downcase, dim_value)
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
          
          # Bootstrap actions
          cluster_attrs.bootstrap_action.each do |bootstrap|
            bootstrap_action do
              name bootstrap[:name]
              path bootstrap[:path]
              args bootstrap[:args] if bootstrap[:args]&.any?
            end
          end
          
          # Logging
          log_uri cluster_attrs.log_uri if cluster_attrs.log_uri
          log_encryption_kms_key_id cluster_attrs.log_encryption_kms_key_id if cluster_attrs.log_encryption_kms_key_id
          
          # Cluster behavior
          termination_protection cluster_attrs.termination_protection
          keep_job_flow_alive_when_no_steps cluster_attrs.keep_job_flow_alive_when_no_steps
          visible_to_all_users cluster_attrs.visible_to_all_users
          
          # Auto termination
          if cluster_attrs.auto_termination_policy
            auto_termination_policy do
              atp = cluster_attrs.auto_termination_policy
              idle_timeout atp[:idle_timeout] if atp[:idle_timeout]
            end
          end
          
          # Custom AMI
          custom_ami_id cluster_attrs.custom_ami_id if cluster_attrs.custom_ami_id
          
          # EBS root volume
          ebs_root_volume_size cluster_attrs.ebs_root_volume_size if cluster_attrs.ebs_root_volume_size
          
          # Kerberos
          if cluster_attrs.kerberos_attributes
            kerberos_attributes do
              ka = cluster_attrs.kerberos_attributes
              kdc_admin_password ka[:kdc_admin_password]
              realm ka[:realm]
              ad_domain_join_password ka[:ad_domain_join_password] if ka[:ad_domain_join_password]
              ad_domain_join_user ka[:ad_domain_join_user] if ka[:ad_domain_join_user]
              cross_realm_trust_principal_password ka[:cross_realm_trust_principal_password] if ka[:cross_realm_trust_principal_password]
            end
          end
          
          # Step concurrency
          step_concurrency_level cluster_attrs.step_concurrency_level if cluster_attrs.step_concurrency_level
          
          # Placement groups
          cluster_attrs.placement_group_configs.each do |placement_config|
            placement_group_configs do
              instance_role placement_config[:instance_role]
              placement_strategy placement_config[:placement_strategy] if placement_config[:placement_strategy]
            end
          end
          
          # Apply tags if present
          if cluster_attrs.tags.any?
            tags do
              cluster_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_emr_cluster',
          name: name,
          resource_attributes: cluster_attrs.to_h,
          outputs: {
            id: "${aws_emr_cluster.#{name}.id}",
            name: "${aws_emr_cluster.#{name}.name}",
            arn: "${aws_emr_cluster.#{name}.arn}",
            cluster_state: "${aws_emr_cluster.#{name}.cluster_state}",
            master_instance_group_id: "${aws_emr_cluster.#{name}.master_instance_group[0].id}",
            core_instance_group_id: "${aws_emr_cluster.#{name}.core_instance_group[0].id}",
            master_public_dns: "${aws_emr_cluster.#{name}.master_public_dns}",
            log_uri: "${aws_emr_cluster.#{name}.log_uri}",
            applications: "${aws_emr_cluster.#{name}.applications}"
          },
          computed_properties: {
            uses_spark: cluster_attrs.uses_spark?,
            uses_hive: cluster_attrs.uses_hive?,
            uses_presto: cluster_attrs.uses_presto?,
            uses_ml_frameworks: cluster_attrs.uses_ml_frameworks?,
            uses_notebooks: cluster_attrs.uses_notebooks?,
            is_multi_az: cluster_attrs.is_multi_az?,
            uses_spot_instances: cluster_attrs.uses_spot_instances?,
            has_auto_scaling: cluster_attrs.has_auto_scaling?,
            total_core_instances: cluster_attrs.total_core_instances,
            total_task_instances: cluster_attrs.total_task_instances,
            total_cluster_instances: cluster_attrs.total_cluster_instances,
            estimated_hourly_cost_usd: cluster_attrs.estimated_hourly_cost_usd,
            configuration_warnings: cluster_attrs.configuration_warnings
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)