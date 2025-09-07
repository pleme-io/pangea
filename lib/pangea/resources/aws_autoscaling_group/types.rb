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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Launch template specification for ASG
        class LaunchTemplateSpecification < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :id, Resources::Types::String.optional.default(nil)
          attribute :name, Resources::Types::String.optional.default(nil)
          attribute :version, Resources::Types::String.default('$Latest')
          
          # Validate that either id or name is specified
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            unless attrs[:id] || attrs[:name]
              raise Dry::Struct::Error, "Launch template must specify either 'id' or 'name'"
            end
            
            if attrs[:id] && attrs[:name]
              raise Dry::Struct::Error, "Launch template cannot specify both 'id' and 'name'"
            end
            
            super(attrs)
          end
          
          def to_h
            {
              id: id,
              name: name,
              version: version
            }.compact
          end
        end
        
        # Instance refresh preferences
        class InstanceRefreshPreferences < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :min_healthy_percentage, Resources::Types::Integer.default(90).constrained(gteq: 0, lteq: 100)
          attribute :instance_warmup, Resources::Types::Integer.optional.default(nil)
          attribute :checkpoint_percentages, Resources::Types::Array.of(Resources::Types::Integer).default([].freeze)
          attribute :checkpoint_delay, Resources::Types::Integer.optional.default(nil)
          
          def to_h
            attributes.reject { |_, v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }
          end
        end
        
        # Tag specification for ASG
        class AutoScalingTag < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :key, Resources::Types::String
          attribute :value, Resources::Types::String
          attribute :propagate_at_launch, Resources::Types::Bool.default(true)
          
          def to_h
            {
              key: key,
              value: value,
              propagate_at_launch: propagate_at_launch
            }
          end
        end
        
        # Auto Scaling Group resource attributes with validation
        class AutoScalingGroupAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :min_size, Resources::Types::Integer.constrained(gteq: 0)
          attribute :max_size, Resources::Types::Integer.constrained(gteq: 0)
          
          # Optional sizing
          attribute :desired_capacity, Resources::Types::Integer.optional.default(nil)
          attribute :default_cooldown, Resources::Types::Integer.default(300)
          
          # Launch configuration (one of these is required)
          attribute :launch_configuration, Resources::Types::String.optional.default(nil)
          attribute :launch_template, LaunchTemplateSpecification.optional.default(nil)
          attribute :mixed_instances_policy, Resources::Types::Hash.optional.default(nil)
          
          # Network configuration
          attribute :vpc_zone_identifier, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
          attribute :availability_zones, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
          
          # Health check configuration
          attribute :health_check_type, Resources::Types::String.default('EC2').enum('EC2', 'ELB')
          attribute :health_check_grace_period, Resources::Types::Integer.default(300)
          
          # Termination policies
          attribute :termination_policies, Resources::Types::Array.of(
            Resources::Types::String.enum(
              'OldestInstance', 'NewestInstance', 'OldestLaunchConfiguration',
              'OldestLaunchTemplate', 'ClosestToNextInstanceHour', 'Default',
              'AllocationStrategy'
            )
          ).default([].freeze)
          
          # Other options
          attribute :enabled_metrics, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
          attribute :metrics_granularity, Resources::Types::String.default('1Minute').enum('1Minute')
          attribute :wait_for_capacity_timeout, Resources::Types::String.default('10m')
          attribute :min_elb_capacity, Resources::Types::Integer.optional.default(nil)
          attribute :protect_from_scale_in, Resources::Types::Bool.default(false)
          attribute :service_linked_role_arn, Resources::Types::String.optional.default(nil)
          attribute :max_instance_lifetime, Resources::Types::Integer.optional.default(nil)
          attribute :capacity_rebalance, Resources::Types::Bool.default(false)
          
          # Target group ARNs
          attribute :target_group_arns, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
          attribute :load_balancers, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
          
          # Tags
          attribute :tags, Resources::Types::Array.of(AutoScalingTag).default([].freeze)
          
          # Instance refresh
          attribute :instance_refresh, InstanceRefreshPreferences.optional.default(nil)
          
          # Validate configuration consistency
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate min/max size relationship
            if attrs[:min_size] && attrs[:max_size] && attrs[:min_size] > attrs[:max_size]
              raise Dry::Struct::Error, "min_size (#{attrs[:min_size]}) cannot be greater than max_size (#{attrs[:max_size]})"
            end
            
            # Validate desired capacity
            if attrs[:desired_capacity]
              min = attrs[:min_size] || 0
              max = attrs[:max_size] || 0
              
              if attrs[:desired_capacity] < min || attrs[:desired_capacity] > max
                raise Dry::Struct::Error, "desired_capacity (#{attrs[:desired_capacity]}) must be between min_size (#{min}) and max_size (#{max})"
              end
            end
            
            # Validate launch configuration
            launch_configs = [
              attrs[:launch_configuration],
              attrs[:launch_template],
              attrs[:mixed_instances_policy]
            ].compact
            
            if launch_configs.empty?
              raise Dry::Struct::Error, "Auto Scaling Group must specify one of: launch_configuration, launch_template, or mixed_instances_policy"
            end
            
            if launch_configs.size > 1
              raise Dry::Struct::Error, "Auto Scaling Group can only specify one of: launch_configuration, launch_template, or mixed_instances_policy"
            end
            
            # Validate network configuration
            if attrs[:vpc_zone_identifier].empty? && attrs[:availability_zones].empty?
              raise Dry::Struct::Error, "Auto Scaling Group must specify either vpc_zone_identifier or availability_zones"
            end
            
            super(attrs)
          end
          
          # Computed properties
          def uses_launch_template?
            !launch_template.nil?
          end
          
          def uses_mixed_instances?
            !mixed_instances_policy.nil?
          end
          
          def uses_target_groups?
            target_group_arns.any?
          end
          
          def uses_classic_load_balancers?
            load_balancers.any?
          end
          
          def to_h
            hash = {
              min_size: min_size,
              max_size: max_size,
              desired_capacity: desired_capacity,
              default_cooldown: default_cooldown,
              health_check_type: health_check_type,
              health_check_grace_period: health_check_grace_period,
              wait_for_capacity_timeout: wait_for_capacity_timeout,
              protect_from_scale_in: protect_from_scale_in,
              capacity_rebalance: capacity_rebalance
            }
            
            # Add optional attributes
            hash[:launch_configuration] = launch_configuration if launch_configuration
            hash[:launch_template] = launch_template.to_h if launch_template
            hash[:mixed_instances_policy] = mixed_instances_policy if mixed_instances_policy
            hash[:vpc_zone_identifier] = vpc_zone_identifier if vpc_zone_identifier.any?
            hash[:availability_zones] = availability_zones if availability_zones.any?
            hash[:termination_policies] = termination_policies if termination_policies.any?
            hash[:enabled_metrics] = enabled_metrics if enabled_metrics.any?
            hash[:metrics_granularity] = metrics_granularity if enabled_metrics.any?
            hash[:min_elb_capacity] = min_elb_capacity if min_elb_capacity
            hash[:service_linked_role_arn] = service_linked_role_arn if service_linked_role_arn
            hash[:max_instance_lifetime] = max_instance_lifetime if max_instance_lifetime
            hash[:target_group_arns] = target_group_arns if target_group_arns.any?
            hash[:load_balancers] = load_balancers if load_balancers.any?
            hash[:tags] = tags.map(&:to_h) if tags.any?
            hash[:instance_refresh] = instance_refresh.to_h if instance_refresh
            
            hash.compact
          end
        end
      end
    end
  end
end