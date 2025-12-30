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
require 'pangea/resources/aws_ecs_service/types'
require 'pangea/resources/aws_ecs_service/dsl_builders'
require 'pangea/resources/aws_ecs_service/reference_builder'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS ECS Service with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ECS service attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ecs_service(name, attributes = {})
        # Validate attributes using dry-struct
        service_attrs = AWS::Types::Types::EcsServiceAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ecs_service, name) do
          extend EcsServiceConnectDsl

          build_core_config(service_attrs)
          build_scheduling_config(service_attrs)
          build_launch_config(service_attrs)
          build_capacity_provider_strategy(service_attrs)
          build_load_balancers(service_attrs)
          build_network_config(service_attrs)
          build_service_registries(service_attrs)
          build_deployment_config(service_attrs)
          build_placement_config(service_attrs)
          build_additional_config(service_attrs)
          build_service_connect_config(service_attrs)
          build_lifecycle_config(service_attrs)
          build_tags(service_attrs)
        end

        EcsServiceReferenceBuilder.build(name, service_attrs)
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
