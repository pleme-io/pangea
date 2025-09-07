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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_emr_instance_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EMR Instance Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] EMR Instance Group attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_emr_instance_group(name, attributes = {})
        # Validate attributes using dry-struct
        group_attrs = Types::EmrInstanceGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_emr_instance_group, name) do
          # Required attributes
          cluster_id group_attrs.cluster_id
          instance_role group_attrs.instance_role
          instance_type group_attrs.instance_type
          instance_count group_attrs.instance_count
          
          # Optional attributes
          name group_attrs.name if group_attrs.name
          bid_price group_attrs.bid_price if group_attrs.bid_price
          
          # EBS configuration
          if group_attrs.ebs_config
            ebs_config do
              ebs_cfg = group_attrs.ebs_config
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
          
          # Auto scaling policy
          if group_attrs.auto_scaling_policy
            auto_scaling_policy do
              asp = group_attrs.auto_scaling_policy
              
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
          
          # Configurations
          group_attrs.configurations.each do |config|
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
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_emr_instance_group',
          name: name,
          resource_attributes: group_attrs.to_h,
          outputs: {
            id: "${aws_emr_instance_group.#{name}.id}",
            running_instance_count: "${aws_emr_instance_group.#{name}.running_instance_count}",
            status: "${aws_emr_instance_group.#{name}.status}"
          },
          computed_properties: {
            is_master: group_attrs.is_master?,
            is_core: group_attrs.is_core?,
            is_task: group_attrs.is_task?,
            uses_spot_instances: group_attrs.uses_spot_instances?,
            has_auto_scaling: group_attrs.has_auto_scaling?,
            is_ebs_optimized: group_attrs.is_ebs_optimized?,
            total_ebs_storage_gb_per_instance: group_attrs.total_ebs_storage_gb_per_instance,
            scaling_capacity_range: group_attrs.scaling_capacity_range,
            scaling_rules_summary: group_attrs.scaling_rules_summary,
            estimated_hourly_cost_usd: group_attrs.estimated_hourly_cost_usd,
            configuration_warnings: group_attrs.configuration_warnings
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)