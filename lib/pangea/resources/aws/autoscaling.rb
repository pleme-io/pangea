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


require_relative 'autoscaling/autoscaling_lifecycle_hook'
require_relative 'autoscaling/autoscaling_notification'
require_relative 'autoscaling/autoscaling_schedule'
require_relative 'autoscaling/autoscaling_traffic_source_attachment'
require_relative 'autoscaling/autoscaling_warm_pool'
require_relative 'autoscaling/autoscaling_group_tag'
require_relative 'autoscaling/launch_configuration'
require_relative 'autoscaling/placement_group'
require_relative 'autoscaling/autoscaling_policy_step_adjustment'
require_relative 'autoscaling/autoscaling_policy_target_tracking_scaling_policy'

module Pangea
  module Resources
    module AWS
      # AWS Auto Scaling Extended service module
      # Provides type-safe resource functions for advanced auto scaling configuration
      module AutoScaling
        # Creates an auto scaling lifecycle hook for custom actions during scaling events
        #
        # @param name [Symbol] Unique name for the lifecycle hook resource
        # @param attributes [Hash] Configuration attributes for the lifecycle hook
        # @return [AutoScaling::AutoscalingLifecycleHook::AutoscalingLifecycleHookReference] Reference to the created lifecycle hook
        def aws_autoscaling_lifecycle_hook(name, attributes = {})
          resource = AutoScaling::AutoscalingLifecycleHook.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AutoScaling::AutoscalingLifecycleHook::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an auto scaling notification for monitoring auto scaling events
        #
        # @param name [Symbol] Unique name for the auto scaling notification resource
        # @param attributes [Hash] Configuration attributes for the notification
        # @return [AutoScaling::AutoscalingNotification::AutoscalingNotificationReference] Reference to the created notification
        def aws_autoscaling_notification(name, attributes = {})
          resource = AutoScaling::AutoscalingNotification.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AutoScaling::AutoscalingNotification::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an auto scaling schedule for scheduled scaling actions
        #
        # @param name [Symbol] Unique name for the auto scaling schedule resource
        # @param attributes [Hash] Configuration attributes for the schedule
        # @return [AutoScaling::AutoscalingSchedule::AutoscalingScheduleReference] Reference to the created schedule
        def aws_autoscaling_schedule(name, attributes = {})
          resource = AutoScaling::AutoscalingSchedule.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AutoScaling::AutoscalingSchedule::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an auto scaling traffic source attachment for load balancer integration
        #
        # @param name [Symbol] Unique name for the traffic source attachment resource
        # @param attributes [Hash] Configuration attributes for the attachment
        # @return [AutoScaling::AutoscalingTrafficSourceAttachment::AutoscalingTrafficSourceAttachmentReference] Reference to the created attachment
        def aws_autoscaling_traffic_source_attachment(name, attributes = {})
          resource = AutoScaling::AutoscalingTrafficSourceAttachment.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AutoScaling::AutoscalingTrafficSourceAttachment::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an auto scaling warm pool for maintaining pre-initialized instances
        #
        # @param name [Symbol] Unique name for the auto scaling warm pool resource
        # @param attributes [Hash] Configuration attributes for the warm pool
        # @return [AutoScaling::AutoscalingWarmPool::AutoscalingWarmPoolReference] Reference to the created warm pool
        def aws_autoscaling_warm_pool(name, attributes = {})
          resource = AutoScaling::AutoscalingWarmPool.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AutoScaling::AutoscalingWarmPool::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an auto scaling group tag for resource tagging
        #
        # @param name [Symbol] Unique name for the auto scaling group tag resource
        # @param attributes [Hash] Configuration attributes for the tag
        # @return [AutoScaling::AutoscalingGroupTag::AutoscalingGroupTagReference] Reference to the created tag
        def aws_autoscaling_group_tag(name, attributes = {})
          resource = AutoScaling::AutoscalingGroupTag.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AutoScaling::AutoscalingGroupTag::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a launch configuration for auto scaling group instance templates
        #
        # @param name [Symbol] Unique name for the launch configuration resource
        # @param attributes [Hash] Configuration attributes for the launch configuration
        # @return [AutoScaling::LaunchConfiguration::LaunchConfigurationReference] Reference to the created launch configuration
        def aws_launch_configuration(name, attributes = {})
          resource = AutoScaling::LaunchConfiguration.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AutoScaling::LaunchConfiguration::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a placement group for controlling instance placement strategy
        #
        # @param name [Symbol] Unique name for the placement group resource
        # @param attributes [Hash] Configuration attributes for the placement group
        # @return [AutoScaling::PlacementGroup::PlacementGroupReference] Reference to the created placement group
        def aws_placement_group(name, attributes = {})
          resource = AutoScaling::PlacementGroup.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AutoScaling::PlacementGroup::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an auto scaling policy step adjustment for step scaling configuration
        #
        # @param name [Symbol] Unique name for the policy step adjustment resource
        # @param attributes [Hash] Configuration attributes for the step adjustment
        # @return [AutoScaling::AutoscalingPolicyStepAdjustment::AutoscalingPolicyStepAdjustmentReference] Reference to the created step adjustment
        def aws_autoscaling_policy_step_adjustment(name, attributes = {})
          resource = AutoScaling::AutoscalingPolicyStepAdjustment.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AutoScaling::AutoscalingPolicyStepAdjustment::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an auto scaling policy target tracking scaling policy for automatic scaling
        #
        # @param name [Symbol] Unique name for the target tracking scaling policy resource
        # @param attributes [Hash] Configuration attributes for the policy
        # @return [AutoScaling::AutoscalingPolicyTargetTrackingScalingPolicy::AutoscalingPolicyTargetTrackingScalingPolicyReference] Reference to the created policy
        def aws_autoscaling_policy_target_tracking_scaling_policy(name, attributes = {})
          resource = AutoScaling::AutoscalingPolicyTargetTrackingScalingPolicy.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AutoScaling::AutoscalingPolicyTargetTrackingScalingPolicy::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end
      end
    end
  end
end