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

module Pangea
  module Resources
    module AWS
      # Builder module for ECS target parameters in EventBridge targets
      module EcsTargetBuilder
        # Builds ECS parameters block for EventBridge target
        # @param builder [Object] The DSL builder context
        # @param ecs_params [Hash] ECS parameters configuration
        def build_ecs_parameters(builder, ecs_params)
          builder.ecs_parameters do
            task_definition_arn ecs_params[:task_definition_arn]
            task_count ecs_params[:task_count] if ecs_params[:task_count]
            launch_type ecs_params[:launch_type] if ecs_params[:launch_type]
            platform_version ecs_params[:platform_version] if ecs_params[:platform_version]
            group ecs_params[:group] if ecs_params[:group]

            build_network_configuration(self, ecs_params[:network_configuration]) if ecs_params[:network_configuration]
            build_capacity_provider_strategy(self, ecs_params[:capacity_provider_strategy]) if ecs_params[:capacity_provider_strategy]
            build_placement_constraints(self, ecs_params[:placement_constraint]) if ecs_params[:placement_constraint]
            build_placement_strategy(self, ecs_params[:placement_strategy]) if ecs_params[:placement_strategy]
            build_ecs_tags(self, ecs_params[:tags]) if ecs_params[:tags]
          end
        end

        private

        def build_network_configuration(builder, network_config)
          builder.network_configuration do
            awsvpc_configuration do
              subnets network_config[:awsvpc_configuration][:subnets]
              security_groups network_config[:awsvpc_configuration][:security_groups] if network_config[:awsvpc_configuration][:security_groups]
              assign_public_ip network_config[:awsvpc_configuration][:assign_public_ip] if network_config[:awsvpc_configuration][:assign_public_ip]
            end
          end
        end

        def build_capacity_provider_strategy(builder, strategies)
          strategies.each do |strategy|
            builder.capacity_provider_strategy do
              capacity_provider strategy[:capacity_provider]
              weight strategy[:weight] if strategy[:weight]
              base strategy[:base] if strategy[:base]
            end
          end
        end

        def build_placement_constraints(builder, constraints)
          constraints.each do |constraint|
            builder.placement_constraint do
              type constraint[:type] if constraint[:type]
              expression constraint[:expression] if constraint[:expression]
            end
          end
        end

        def build_placement_strategy(builder, strategies)
          strategies.each do |strategy|
            builder.placement_strategy do
              type strategy[:type] if strategy[:type]
              field strategy[:field] if strategy[:field]
            end
          end
        end

        def build_ecs_tags(builder, ecs_tags)
          builder.tags do
            ecs_tags.each do |key, value|
              public_send(key, value)
            end
          end
        end
      end
    end
  end
end
