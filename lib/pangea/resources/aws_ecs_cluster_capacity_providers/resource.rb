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
require 'pangea/resources/aws_ecs_cluster_capacity_providers/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create AWS ECS Cluster Capacity Providers association with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ECS cluster capacity providers attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ecs_cluster_capacity_providers(name, attributes = {})
        # Validate attributes using dry-struct
        providers_attrs = Types::EcsClusterCapacityProvidersAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ecs_cluster_capacity_providers, name) do
          # Cluster name
          cluster_name providers_attrs.cluster_name
          
          # Capacity providers
          capacity_providers providers_attrs.capacity_providers if providers_attrs.capacity_providers.any?
          
          # Default capacity provider strategy
          providers_attrs.default_capacity_provider_strategy.each do |strategy|
            default_capacity_provider_strategy do
              capacity_provider strategy.capacity_provider
              weight strategy.weight
              base strategy.base if strategy.base > 0
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ecs_cluster_capacity_providers',
          name: name,
          resource_attributes: providers_attrs.to_h,
          outputs: {
            id: "${aws_ecs_cluster_capacity_providers.#{name}.id}",
            cluster_name: "${aws_ecs_cluster_capacity_providers.#{name}.cluster_name}"
          },
          computed_properties: {
            using_fargate: providers_attrs.using_fargate?,
            using_ec2: providers_attrs.using_ec2?,
            using_custom_providers: providers_attrs.using_custom_providers?,
            primary_capacity_provider: providers_attrs.primary_capacity_provider,
            capacity_distribution: providers_attrs.capacity_distribution,
            spot_prioritized: providers_attrs.spot_prioritized?,
            estimated_spot_savings_percent: providers_attrs.estimated_spot_savings_percent,
            provider_count: providers_attrs.capacity_providers.size,
            has_default_strategy: providers_attrs.default_capacity_provider_strategy.any?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)