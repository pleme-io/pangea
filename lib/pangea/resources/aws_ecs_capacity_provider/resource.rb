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
require 'pangea/resources/aws_ecs_capacity_provider/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS ECS Capacity Provider with type-safe attributes
      #
      # ECS Capacity Providers manage the infrastructure that your tasks run on.
      # They can be used to control the Auto Scaling of EC2 instances in your
      # cluster or to use AWS Fargate for serverless containers.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ECS capacity provider attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ecs_capacity_provider(name, attributes = {})
        # Validate attributes using dry-struct
        provider_attrs = EcsCapacityProvider::Types::EcsCapacityProviderAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ecs_capacity_provider, name) do
          # Required attributes
          name provider_attrs.name
          
          # Auto Scaling Group Provider configuration
          if provider_attrs.auto_scaling_group_provider
            auto_scaling_group_provider do
              auto_scaling_group_arn provider_attrs.auto_scaling_group_provider[:auto_scaling_group_arn]
              
              # Managed scaling configuration
              if provider_attrs.auto_scaling_group_provider[:managed_scaling]
                managed_scaling do
                  scaling_config = provider_attrs.auto_scaling_group_provider[:managed_scaling]
                  
                  instance_warmup_period scaling_config[:instance_warmup_period] if scaling_config[:instance_warmup_period]
                  maximum_scaling_step_size scaling_config[:maximum_scaling_step_size] if scaling_config[:maximum_scaling_step_size]
                  minimum_scaling_step_size scaling_config[:minimum_scaling_step_size] if scaling_config[:minimum_scaling_step_size]
                  status scaling_config[:status] if scaling_config[:status]
                  target_capacity scaling_config[:target_capacity] if scaling_config[:target_capacity]
                end
              end
              
              # Managed termination protection
              if provider_attrs.auto_scaling_group_provider[:managed_termination_protection]
                managed_termination_protection provider_attrs.auto_scaling_group_provider[:managed_termination_protection]
              end
            end
          end
          
          # Apply tags
          if provider_attrs.tags.any?
            tags do
              provider_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ecs_capacity_provider',
          name: name,
          resource_attributes: provider_attrs.to_h,
          outputs: {
            id: "${aws_ecs_capacity_provider.#{name}.id}",
            arn: "${aws_ecs_capacity_provider.#{name}.arn}",
            name: "${aws_ecs_capacity_provider.#{name}.name}",
            tags_all: "${aws_ecs_capacity_provider.#{name}.tags_all}"
          },
          computed: {
            has_auto_scaling_group: provider_attrs.has_auto_scaling_group?,
            auto_scaling_group_name: provider_attrs.auto_scaling_group_name,
            managed_scaling_enabled: provider_attrs.managed_scaling_enabled?,
            managed_termination_protection_enabled: provider_attrs.managed_termination_protection_enabled?,
            target_capacity_percentage: provider_attrs.target_capacity_percentage,
            instance_warmup_period: provider_attrs.instance_warmup_period,
            fargate_provider: provider_attrs.fargate_provider?,
            ec2_provider: provider_attrs.ec2_provider?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)