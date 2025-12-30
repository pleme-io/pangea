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
require_relative 'types/step_adjustment'
require_relative 'types/target_tracking_configuration'
require_relative 'types/predictive_scaling_configuration'

module Pangea
  module Resources
    module AWS
      module Types
        # Auto Scaling Policy resource attributes with validation
        class AutoScalingPolicyAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required
          attribute :autoscaling_group_name, Resources::Types::String
          attribute :name, Resources::Types::String.optional.default(nil)

          # Policy type determines which other attributes are valid
          attribute :policy_type, Resources::Types::String.default('SimpleScaling').enum(
            'SimpleScaling',
            'StepScaling',
            'TargetTrackingScaling',
            'PredictiveScaling'
          )

          # Simple/Step scaling attributes
          attribute :adjustment_type, Resources::Types::String.optional.default(nil).enum(
            'ChangeInCapacity',
            'ExactCapacity',
            'PercentChangeInCapacity',
            nil
          )
          attribute :scaling_adjustment, Resources::Types::Integer.optional.default(nil)
          attribute :cooldown, Resources::Types::Integer.optional.default(nil)
          attribute :min_adjustment_magnitude, Resources::Types::Integer.optional.default(nil)

          # Step scaling specific
          attribute :metric_aggregation_type, Resources::Types::String.default('Average').enum('Average', 'Minimum', 'Maximum')
          attribute :step_adjustments, Resources::Types::Array.of(StepAdjustment).default([].freeze)
          attribute :estimated_instance_warmup, Resources::Types::Integer.optional.default(nil)

          # Target tracking specific
          attribute :target_tracking_configuration, TargetTrackingConfiguration.optional.default(nil)

          # Predictive scaling specific
          attribute :predictive_scaling_configuration, PredictiveScalingConfiguration.optional.default(nil)

          # Validate policy type specific requirements
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            policy_type = attrs[:policy_type] || 'SimpleScaling'

            validate_policy_attributes!(policy_type, attrs)
            super(attrs)
          end

          def self.validate_policy_attributes!(policy_type, attrs)
            case policy_type
            when 'SimpleScaling'
              validate_simple_scaling!(attrs)
            when 'StepScaling'
              validate_step_scaling!(attrs)
            when 'TargetTrackingScaling'
              validate_target_tracking!(attrs)
            when 'PredictiveScaling'
              validate_predictive_scaling!(attrs)
            end
          end

          def self.validate_simple_scaling!(attrs)
            return if attrs[:adjustment_type] && attrs[:scaling_adjustment]

            raise Dry::Struct::Error, 'SimpleScaling policy requires adjustment_type and scaling_adjustment'
          end

          def self.validate_step_scaling!(attrs)
            unless attrs[:adjustment_type] && attrs[:step_adjustments] && !attrs[:step_adjustments].empty?
              raise Dry::Struct::Error, 'StepScaling policy requires adjustment_type and step_adjustments'
            end
            return unless attrs[:scaling_adjustment]

            raise Dry::Struct::Error, 'StepScaling policy cannot use scaling_adjustment (use step_adjustments instead)'
          end

          def self.validate_target_tracking!(attrs)
            unless attrs[:target_tracking_configuration]
              raise Dry::Struct::Error, 'TargetTrackingScaling policy requires target_tracking_configuration'
            end
            return unless attrs[:adjustment_type] || attrs[:scaling_adjustment]

            raise Dry::Struct::Error, 'TargetTrackingScaling policy cannot use adjustment_type or scaling_adjustment'
          end

          def self.validate_predictive_scaling!(attrs)
            return if attrs[:predictive_scaling_configuration]

            raise Dry::Struct::Error, 'PredictiveScaling policy requires predictive_scaling_configuration'
          end

          private_class_method :validate_policy_attributes!, :validate_simple_scaling!,
                               :validate_step_scaling!, :validate_target_tracking!, :validate_predictive_scaling!

          # Computed properties
          def simple_scaling?
            policy_type == 'SimpleScaling'
          end

          def step_scaling?
            policy_type == 'StepScaling'
          end

          def target_tracking?
            policy_type == 'TargetTrackingScaling'
          end

          def predictive?
            policy_type == 'PredictiveScaling'
          end

          def to_h
            hash = { autoscaling_group_name: autoscaling_group_name, policy_type: policy_type }
            hash[:name] = name if name
            add_policy_type_attributes(hash)
            hash.compact
          end

          private

          def add_policy_type_attributes(hash)
            case policy_type
            when 'SimpleScaling'
              add_simple_scaling_attributes(hash)
            when 'StepScaling'
              add_step_scaling_attributes(hash)
            when 'TargetTrackingScaling'
              hash[:target_tracking_configuration] = target_tracking_configuration.to_h
            when 'PredictiveScaling'
              hash[:predictive_scaling_configuration] = predictive_scaling_configuration.to_h
            end
          end

          def add_simple_scaling_attributes(hash)
            hash[:adjustment_type] = adjustment_type
            hash[:scaling_adjustment] = scaling_adjustment
            hash[:cooldown] = cooldown if cooldown
            hash[:min_adjustment_magnitude] = min_adjustment_magnitude if min_adjustment_magnitude
          end

          def add_step_scaling_attributes(hash)
            hash[:adjustment_type] = adjustment_type
            hash[:metric_aggregation_type] = metric_aggregation_type
            hash[:step_adjustments] = step_adjustments.map(&:to_h)
            hash[:estimated_instance_warmup] = estimated_instance_warmup if estimated_instance_warmup
            hash[:min_adjustment_magnitude] = min_adjustment_magnitude if min_adjustment_magnitude
          end
        end
      end
    end
  end
end
