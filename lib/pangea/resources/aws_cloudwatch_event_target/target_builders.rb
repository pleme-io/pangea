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
      # Helper methods for building CloudWatch Event Target configurations
      module CloudWatchEventTargetBuilders
        private

        def build_ecs_target(context, ecs_config)
          context.ecs_target do
            task_definition_arn ecs_config[:task_definition_arn]
            task_count ecs_config[:task_count] if ecs_config[:task_count]
            launch_type ecs_config[:launch_type] if ecs_config[:launch_type]
            platform_version ecs_config[:platform_version] if ecs_config[:platform_version]
            group ecs_config[:group] if ecs_config[:group]
            build_network_configuration(self, ecs_config[:network_configuration]) if ecs_config[:network_configuration]
            build_placement_constraints(self, ecs_config[:placement_constraints]) if ecs_config[:placement_constraints]
          end
        end

        def build_network_configuration(context, network_config)
          context.network_configuration do
            if network_config[:awsvpc_configuration]
              awsvpc_configuration do
                subnets network_config[:awsvpc_configuration][:subnets]
                security_groups network_config[:awsvpc_configuration][:security_groups] if network_config[:awsvpc_configuration][:security_groups]
                assign_public_ip network_config[:awsvpc_configuration][:assign_public_ip] if network_config[:awsvpc_configuration][:assign_public_ip]
              end
            end
          end
        end

        def build_placement_constraints(context, constraints)
          constraints.each do |constraint|
            context.placement_constraint do
              type constraint[:type]
              expression constraint[:expression] if constraint[:expression]
            end
          end
        end

        def build_batch_target(context, batch_config)
          context.batch_target do
            job_definition batch_config[:job_definition]
            job_name batch_config[:job_name]
            array_size batch_config[:array_size] if batch_config[:array_size]
            job_attempts batch_config[:job_attempts] if batch_config[:job_attempts]
          end
        end

        def build_kinesis_target(context, kinesis_config)
          context.kinesis_target do
            partition_key_path kinesis_config[:partition_key_path] if kinesis_config[:partition_key_path]
          end
        end

        def build_sqs_target(context, sqs_config)
          context.sqs_target do
            message_group_id sqs_config[:message_group_id] if sqs_config[:message_group_id]
          end
        end

        def build_http_target(context, http_config)
          context.http_target do
            endpoint http_config[:endpoint] if http_config[:endpoint]
            header_parameters http_config[:header_parameters] if http_config[:header_parameters]
            query_string_parameters http_config[:query_string_parameters] if http_config[:query_string_parameters]
            path_parameter_values http_config[:path_parameter_values] if http_config[:path_parameter_values]
          end
        end

        def build_run_command_targets(context, run_command_targets)
          run_command_targets.each do |run_command|
            context.run_command_targets do
              key run_command[:key]
              values run_command[:values]
            end
          end
        end
      end
    end
  end
end
