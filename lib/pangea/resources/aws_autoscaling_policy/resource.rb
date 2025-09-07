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
require 'pangea/resources/aws_autoscaling_policy/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Auto Scaling Policy with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Auto Scaling Policy attributes
      # @option attributes [String] :autoscaling_group_name The ASG name (required)
      # @option attributes [String] :name Policy name
      # @option attributes [String] :policy_type Type of policy (SimpleScaling, StepScaling, etc.)
      # @option attributes [String] :adjustment_type How to scale (ChangeInCapacity, etc.)
      # @option attributes [Integer] :scaling_adjustment Amount to scale (SimpleScaling)
      # @option attributes [Hash] :target_tracking_configuration Target tracking config
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Simple scaling policy
      #   policy = aws_autoscaling_policy(:scale_up, {
      #     autoscaling_group_name: asg.name,
      #     policy_type: "SimpleScaling",
      #     adjustment_type: "ChangeInCapacity",
      #     scaling_adjustment: 2,
      #     cooldown: 300
      #   })
      #
      # @example Target tracking policy
      #   policy = aws_autoscaling_policy(:cpu_tracking, {
      #     autoscaling_group_name: asg.name,
      #     policy_type: "TargetTrackingScaling",
      #     target_tracking_configuration: {
      #       target_value: 70.0,
      #       predefined_metric_specification: {
      #         predefined_metric_type: "ASGAverageCPUUtilization"
      #       }
      #     }
      #   })
      def aws_autoscaling_policy(name, attributes = {})
        # Validate attributes using dry-struct
        policy_attrs = Types::Types::AutoScalingPolicyAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_autoscaling_policy, name) do
          # Required attributes
          autoscaling_group_name policy_attrs.autoscaling_group_name
          __send__(:name, policy_attrs.name) if policy_attrs.name
          policy_type policy_attrs.policy_type
          
          # Policy type specific attributes
          case policy_attrs.policy_type
          when 'SimpleScaling'
            adjustment_type policy_attrs.adjustment_type
            scaling_adjustment policy_attrs.scaling_adjustment
            cooldown policy_attrs.cooldown if policy_attrs.cooldown
            min_adjustment_magnitude policy_attrs.min_adjustment_magnitude if policy_attrs.min_adjustment_magnitude
            
          when 'StepScaling'
            adjustment_type policy_attrs.adjustment_type
            metric_aggregation_type policy_attrs.metric_aggregation_type
            estimated_instance_warmup policy_attrs.estimated_instance_warmup if policy_attrs.estimated_instance_warmup
            min_adjustment_magnitude policy_attrs.min_adjustment_magnitude if policy_attrs.min_adjustment_magnitude
            
            # Step adjustments
            policy_attrs.step_adjustments.each do |step|
              step_adjustment do
                metric_interval_lower_bound step.metric_interval_lower_bound if step.metric_interval_lower_bound
                metric_interval_upper_bound step.metric_interval_upper_bound if step.metric_interval_upper_bound
                scaling_adjustment step.scaling_adjustment
              end
            end
            
          when 'TargetTrackingScaling'
            if policy_attrs.target_tracking_configuration
              target_tracking_configuration do
                ttc = policy_attrs.target_tracking_configuration
                target_value ttc.target_value
                disable_scale_in ttc.disable_scale_in if ttc.disable_scale_in
                scale_in_cooldown ttc.scale_in_cooldown if ttc.scale_in_cooldown
                scale_out_cooldown ttc.scale_out_cooldown if ttc.scale_out_cooldown
                
                if ttc.predefined_metric_specification
                  predefined_metric_specification do
                    predefined_metric_type ttc.predefined_metric_specification[:predefined_metric_type]
                    resource_label ttc.predefined_metric_specification[:resource_label] if ttc.predefined_metric_specification[:resource_label]
                  end
                elsif ttc.customized_metric_specification
                  customized_metric_specification do
                    cms = ttc.customized_metric_specification
                    metric_name cms[:metric_name]
                    namespace cms[:namespace]
                    statistic cms[:statistic]
                    unit cms[:unit] if cms[:unit]
                    
                    if cms[:dimensions]
                      dimensions do
                        cms[:dimensions].each do |key, value|
                          public_send(key, value)
                        end
                      end
                    end
                  end
                end
              end
            end
            
          when 'PredictiveScaling'
            if policy_attrs.predictive_scaling_configuration
              predictive_scaling_configuration do
                psc = policy_attrs.predictive_scaling_configuration
                mode psc.mode
                scheduling_buffer_time psc.scheduling_buffer_time if psc.scheduling_buffer_time
                max_capacity_breach_behavior psc.max_capacity_breach_behavior
                max_capacity_buffer psc.max_capacity_buffer if psc.max_capacity_buffer
                
                # Metric specifications would be added here
                psc.metric_specifications.each do |metric_spec|
                  metric_specification metric_spec
                end
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_autoscaling_policy',
          name: name,
          resource_attributes: policy_attrs.to_h,
          outputs: {
            id: "${aws_autoscaling_policy.#{name}.id}",
            arn: "${aws_autoscaling_policy.#{name}.arn}",
            name: "${aws_autoscaling_policy.#{name}.name}",
            adjustment_type: "${aws_autoscaling_policy.#{name}.adjustment_type}",
            policy_type: "${aws_autoscaling_policy.#{name}.policy_type}"
          },
          computed_properties: {
            is_simple_scaling: policy_attrs.is_simple_scaling?,
            is_step_scaling: policy_attrs.is_step_scaling?,
            is_target_tracking: policy_attrs.is_target_tracking?,
            is_predictive: policy_attrs.is_predictive?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)