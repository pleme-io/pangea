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
        module_function

        # Returns a proc that builds ECS parameters in DSL context
        # @param ecs_params [Hash] ECS parameters configuration
        # @return [Proc] Block to be instance_exec'd in DSL context
        def ecs_parameters_block(ecs_params)
          proc do
            task_definition_arn ecs_params[:task_definition_arn]
            task_count ecs_params[:task_count] if ecs_params[:task_count]
            launch_type ecs_params[:launch_type] if ecs_params[:launch_type]
            platform_version ecs_params[:platform_version] if ecs_params[:platform_version]
            group ecs_params[:group] if ecs_params[:group]

            if ecs_params[:network_configuration]
              instance_exec(ecs_params[:network_configuration], &EcsTargetBuilder.network_config_block)
            end
            EcsTargetBuilder.build_capacity_strategies(self, ecs_params[:capacity_provider_strategy])
            EcsTargetBuilder.build_placement_constraints(self, ecs_params[:placement_constraint])
            EcsTargetBuilder.build_placement_strategies(self, ecs_params[:placement_strategy])
            EcsTargetBuilder.build_tags(self, ecs_params[:tags])
          end
        end

        def network_config_block
          proc do |network_config|
            network_configuration do
              awsvpc_configuration do
                subnets network_config[:awsvpc_configuration][:subnets]
                security_groups network_config[:awsvpc_configuration][:security_groups] if network_config[:awsvpc_configuration][:security_groups]
                assign_public_ip network_config[:awsvpc_configuration][:assign_public_ip] if network_config[:awsvpc_configuration][:assign_public_ip]
              end
            end
          end
        end

        def build_capacity_strategies(builder, strategies)
          return unless strategies

          strategies.each do |strategy|
            builder.capacity_provider_strategy do
              capacity_provider strategy[:capacity_provider]
              weight strategy[:weight] if strategy[:weight]
              base strategy[:base] if strategy[:base]
            end
          end
        end

        def build_placement_constraints(builder, constraints)
          return unless constraints

          constraints.each do |constraint|
            builder.placement_constraint do
              type constraint[:type] if constraint[:type]
              expression constraint[:expression] if constraint[:expression]
            end
          end
        end

        def build_placement_strategies(builder, strategies)
          return unless strategies

          strategies.each do |strategy|
            builder.placement_strategy do
              type strategy[:type] if strategy[:type]
              field strategy[:field] if strategy[:field]
            end
          end
        end

        def build_tags(builder, ecs_tags)
          return unless ecs_tags

          builder.tags do
            ecs_tags.each { |key, value| public_send(key, value) }
          end
        end
      end
    end
  end
end
