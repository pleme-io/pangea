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

# Sub-types for Auto Scaling Group
require_relative 'types/launch_template_specification'
require_relative 'types/instance_refresh_preferences'
require_relative 'types/auto_scaling_tag'

module Pangea
  module Resources
    module AWS
      module Types
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
            validate_size_constraints!(attrs)
            validate_launch_configuration!(attrs)
            validate_network_configuration!(attrs)
            super(attrs)
          end

          def self.validate_size_constraints!(attrs)
            if attrs[:min_size] && attrs[:max_size] && attrs[:min_size] > attrs[:max_size]
              raise Dry::Struct::Error,
                    "min_size (#{attrs[:min_size]}) cannot be greater than max_size (#{attrs[:max_size]})"
            end

            return unless attrs[:desired_capacity]

            min = attrs[:min_size] || 0
            max = attrs[:max_size] || 0
            return unless attrs[:desired_capacity] < min || attrs[:desired_capacity] > max

            raise Dry::Struct::Error,
                  "desired_capacity (#{attrs[:desired_capacity]}) must be between min_size (#{min}) and max_size (#{max})"
          end

          def self.validate_launch_configuration!(attrs)
            launch_configs = [
              attrs[:launch_configuration],
              attrs[:launch_template],
              attrs[:mixed_instances_policy]
            ].compact

            if launch_configs.empty?
              raise Dry::Struct::Error,
                    'Auto Scaling Group must specify one of: launch_configuration, launch_template, or mixed_instances_policy'
            end

            return unless launch_configs.size > 1

            raise Dry::Struct::Error,
                  'Auto Scaling Group can only specify one of: launch_configuration, launch_template, or mixed_instances_policy'
          end

          def self.validate_network_configuration!(attrs)
            vpc_empty = attrs[:vpc_zone_identifier].nil? || attrs[:vpc_zone_identifier].empty?
            az_empty = attrs[:availability_zones].nil? || attrs[:availability_zones].empty?
            return unless vpc_empty && az_empty

            raise Dry::Struct::Error,
                  'Auto Scaling Group must specify either vpc_zone_identifier or availability_zones'
          end

          # Computed properties
          def uses_launch_template? = !launch_template.nil?
          def uses_mixed_instances? = !mixed_instances_policy.nil?
          def uses_target_groups? = target_group_arns.any?
          def uses_classic_load_balancers? = load_balancers.any?

          def to_h
            build_required_attributes
              .merge(build_optional_attributes)
              .compact
          end

          private

          def build_required_attributes
            {
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
          end

          def build_optional_attributes
            {
              launch_configuration: launch_configuration,
              launch_template: launch_template&.to_h,
              mixed_instances_policy: mixed_instances_policy,
              vpc_zone_identifier: vpc_zone_identifier.any? ? vpc_zone_identifier : nil,
              availability_zones: availability_zones.any? ? availability_zones : nil,
              termination_policies: termination_policies.any? ? termination_policies : nil,
              enabled_metrics: enabled_metrics.any? ? enabled_metrics : nil,
              metrics_granularity: enabled_metrics.any? ? metrics_granularity : nil,
              min_elb_capacity: min_elb_capacity,
              service_linked_role_arn: service_linked_role_arn,
              max_instance_lifetime: max_instance_lifetime,
              target_group_arns: target_group_arns.any? ? target_group_arns : nil,
              load_balancers: load_balancers.any? ? load_balancers : nil,
              tags: tags.any? ? tags.map(&:to_h) : nil,
              instance_refresh: instance_refresh&.to_h
            }
          end
        end
      end
    end
  end
end
