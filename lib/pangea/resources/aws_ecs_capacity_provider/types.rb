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

module Pangea
  module Resources
    module AWS
      module EcsCapacityProvider
        # Common types for ECS Capacity Provider configurations
        class Types < Dry::Types::Module
          include Dry.Types()

          # Capacity Provider Name constraint
          CapacityProviderName = String.constrained(
            min_size: 1,
            max_size: 255,
            format: /\A[a-zA-Z0-9\-_]+\z/
          )
          
          # Auto Scaling Group ARN constraint
          AutoScalingGroupArn = String.constrained(
            format: /\Aarn:aws:autoscaling:[a-z0-9\-]*:[0-9]{12}:autoScalingGroup:[a-f0-9\-]+:autoScalingGroupName\/[a-zA-Z0-9\-_.]+\z/
          )
          
          # Managed scaling status
          ManagedScalingStatus = String.enum('ENABLED', 'DISABLED')
          
          # Managed termination protection
          ManagedTerminationProtection = String.enum('ENABLED', 'DISABLED')
          
          # Auto Scaling Group Provider configuration
          AutoScalingGroupProvider = Hash.schema({
            auto_scaling_group_arn: AutoScalingGroupArn,
            managed_scaling?: Hash.schema({
              instance_warmup_period?: Integer.constrained(gteq: 1, lteq: 10000).optional,
              maximum_scaling_step_size?: Integer.constrained(gteq: 1, lteq: 10000).optional,
              minimum_scaling_step_size?: Integer.constrained(gteq: 1, lteq: 10000).optional,
              status?: ManagedScalingStatus.optional,
              target_capacity?: Integer.constrained(gteq: 1, lteq: 100).optional
            }).optional,
            managed_termination_protection?: ManagedTerminationProtection.optional
          })
        end

        # ECS Capacity Provider attributes with comprehensive validation
        class EcsCapacityProviderAttributes < Dry::Struct
          include Types[self]
          
          # Required attributes
          attribute :name, CapacityProviderName
          
          # Optional attributes
          attribute? :auto_scaling_group_provider, AutoScalingGroupProvider.optional
          attribute? :tags, Hash.map(String, String).default({}.freeze)
          
          # Computed properties
          def has_auto_scaling_group?
            !auto_scaling_group_provider.nil?
          end
          
          def auto_scaling_group_name
            return nil unless has_auto_scaling_group?
            auto_scaling_group_provider[:auto_scaling_group_arn].split('/')[-1]
          end
          
          def managed_scaling_enabled?
            return false unless has_auto_scaling_group?
            return false unless auto_scaling_group_provider[:managed_scaling]
            auto_scaling_group_provider[:managed_scaling][:status] == 'ENABLED'
          end
          
          def managed_termination_protection_enabled?
            return false unless has_auto_scaling_group?
            auto_scaling_group_provider[:managed_termination_protection] == 'ENABLED'
          end
          
          def target_capacity_percentage
            return nil unless has_auto_scaling_group?
            return nil unless auto_scaling_group_provider[:managed_scaling]
            auto_scaling_group_provider[:managed_scaling][:target_capacity]
          end
          
          def instance_warmup_period
            return nil unless has_auto_scaling_group?
            return nil unless auto_scaling_group_provider[:managed_scaling]
            auto_scaling_group_provider[:managed_scaling][:instance_warmup_period] || 300
          end
          
          def fargate_provider?
            !has_auto_scaling_group?
          end
          
          def ec2_provider?
            has_auto_scaling_group?
          end
        end
      end
    end
  end
end