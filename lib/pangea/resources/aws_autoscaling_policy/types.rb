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
        # Step adjustment for step scaling
        class StepAdjustment < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :metric_interval_lower_bound, Resources::Types::Float.optional.default(nil)
          attribute :metric_interval_upper_bound, Resources::Types::Float.optional.default(nil)
          attribute :scaling_adjustment, Resources::Types::Integer
          
          def to_h
            attributes.compact
          end
        end
        
        # Target tracking configuration
        class TargetTrackingConfiguration < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :target_value, Resources::Types::Float
          attribute :disable_scale_in, Resources::Types::Bool.default(false)
          attribute :scale_in_cooldown, Resources::Types::Integer.optional.default(nil)
          attribute :scale_out_cooldown, Resources::Types::Integer.optional.default(nil)
          
          # Predefined metric specification
          attribute :predefined_metric_specification, Resources::Types::Hash.schema(
            predefined_metric_type: Resources::Types::String.enum(
              'ASGAverageCPUUtilization',
              'ASGAverageNetworkIn',
              'ASGAverageNetworkOut',
              'ALBRequestCountPerTarget'
            ),
            resource_label: Resources::Types::String.optional
          ).optional.default(nil)
          
          # Custom metric specification
          attribute :customized_metric_specification, Resources::Types::Hash.schema(
            metric_name: Resources::Types::String,
            namespace: Resources::Types::String,
            statistic: Resources::Types::String.enum('Average', 'Minimum', 'Maximum', 'SampleCount', 'Sum'),
            unit: Resources::Types::String.optional,
            dimensions: Resources::Types::Hash.optional
          ).optional.default(nil)
          
          # Validate exactly one metric specification
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            metrics = [
              attrs[:predefined_metric_specification],
              attrs[:customized_metric_specification]
            ].compact
            
            if metrics.empty?
              raise Dry::Struct::Error, "Target tracking must specify either predefined_metric_specification or customized_metric_specification"
            end
            
            if metrics.size > 1
              raise Dry::Struct::Error, "Target tracking can only specify one metric specification"
            end
            
            super(attrs)
          end
          
          def to_h
            hash = {
              target_value: target_value,
              disable_scale_in: disable_scale_in
            }
            
            hash[:scale_in_cooldown] = scale_in_cooldown if scale_in_cooldown
            hash[:scale_out_cooldown] = scale_out_cooldown if scale_out_cooldown
            hash[:predefined_metric_specification] = predefined_metric_specification if predefined_metric_specification
            hash[:customized_metric_specification] = customized_metric_specification if customized_metric_specification
            
            hash.compact
          end
        end
        
        # Predictive scaling configuration
        class PredictiveScalingConfiguration < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :mode, Resources::Types::String.default('ForecastOnly').enum('ForecastOnly', 'ForecastAndScale')
          attribute :scheduling_buffer_time, Resources::Types::Integer.optional.default(nil)
          attribute :max_capacity_breach_behavior, Resources::Types::String.default('HonorMaxCapacity').enum('HonorMaxCapacity', 'IncreaseMaxCapacity')
          attribute :max_capacity_buffer, Resources::Types::Integer.optional.default(nil)
          
          # Metric specifications would go here (simplified for this example)
          attribute :metric_specifications, Resources::Types::Array.default([].freeze)
          
          def to_h
            attributes.reject { |_, v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }
          end
        end
        
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
            
            case policy_type
            when 'SimpleScaling'
              unless attrs[:adjustment_type] && attrs[:scaling_adjustment]
                raise Dry::Struct::Error, "SimpleScaling policy requires adjustment_type and scaling_adjustment"
              end
            when 'StepScaling'
              unless attrs[:adjustment_type] && attrs[:step_adjustments] && !attrs[:step_adjustments].empty?
                raise Dry::Struct::Error, "StepScaling policy requires adjustment_type and step_adjustments"
              end
              if attrs[:scaling_adjustment]
                raise Dry::Struct::Error, "StepScaling policy cannot use scaling_adjustment (use step_adjustments instead)"
              end
            when 'TargetTrackingScaling'
              unless attrs[:target_tracking_configuration]
                raise Dry::Struct::Error, "TargetTrackingScaling policy requires target_tracking_configuration"
              end
              if attrs[:adjustment_type] || attrs[:scaling_adjustment]
                raise Dry::Struct::Error, "TargetTrackingScaling policy cannot use adjustment_type or scaling_adjustment"
              end
            when 'PredictiveScaling'
              unless attrs[:predictive_scaling_configuration]
                raise Dry::Struct::Error, "PredictiveScaling policy requires predictive_scaling_configuration"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def is_simple_scaling?
            policy_type == 'SimpleScaling'
          end
          
          def is_step_scaling?
            policy_type == 'StepScaling'
          end
          
          def is_target_tracking?
            policy_type == 'TargetTrackingScaling'
          end
          
          def is_predictive?
            policy_type == 'PredictiveScaling'
          end
          
          def to_h
            hash = {
              autoscaling_group_name: autoscaling_group_name,
              policy_type: policy_type
            }
            
            hash[:name] = name if name
            
            # Add type-specific attributes
            case policy_type
            when 'SimpleScaling'
              hash[:adjustment_type] = adjustment_type
              hash[:scaling_adjustment] = scaling_adjustment
              hash[:cooldown] = cooldown if cooldown
              hash[:min_adjustment_magnitude] = min_adjustment_magnitude if min_adjustment_magnitude
            when 'StepScaling'
              hash[:adjustment_type] = adjustment_type
              hash[:metric_aggregation_type] = metric_aggregation_type
              hash[:step_adjustments] = step_adjustments.map(&:to_h)
              hash[:estimated_instance_warmup] = estimated_instance_warmup if estimated_instance_warmup
              hash[:min_adjustment_magnitude] = min_adjustment_magnitude if min_adjustment_magnitude
            when 'TargetTrackingScaling'
              hash[:target_tracking_configuration] = target_tracking_configuration.to_h
            when 'PredictiveScaling'
              hash[:predictive_scaling_configuration] = predictive_scaling_configuration.to_h
            end
            
            hash.compact
          end
        end
      end
    end
  end
end