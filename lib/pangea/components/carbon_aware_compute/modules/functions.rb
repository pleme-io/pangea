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
  module Components
    module CarbonAwareCompute
      # Lambda function resources for Carbon Aware Compute
      module Functions
        def create_scheduler_function(input, role, workload_table, carbon_table)
          aws_lambda_function(:"#{input.name}-scheduler", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 300,
            memory_size: input.memory_mb,
            architecture: lambda_architecture(input),
            environment: { variables: scheduler_env_vars(input, workload_table, carbon_table) },
            code: { zip_file: generate_scheduler_code(input) },
            tags: function_tags(input, "scheduler")
          })
        end

        def create_executor_function(input, role, workload_table)
          aws_lambda_function(:"#{input.name}-executor", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 900,
            memory_size: input.memory_mb,
            ephemeral_storage: { size: input.ephemeral_storage_gb },
            architecture: lambda_architecture(input),
            environment: { variables: executor_env_vars(input, workload_table) },
            code: { zip_file: generate_executor_code(input) },
            tags: function_tags(input, "executor")
          })
        end

        def create_monitor_function(input, role, carbon_table)
          aws_lambda_function(:"#{input.name}-monitor", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 60,
            memory_size: 256,
            architecture: lambda_architecture(input),
            environment: { variables: monitor_env_vars(input, carbon_table) },
            code: { zip_file: generate_monitor_code(input) },
            tags: function_tags(input, "monitor")
          })
        end

        private

        def scheduler_env_vars(input, workload_table, carbon_table)
          {
            "WORKLOAD_TABLE" => workload_table.table_name,
            "CARBON_TABLE" => carbon_table.table_name,
            "OPTIMIZATION_STRATEGY" => input.optimization_strategy,
            "CARBON_THRESHOLD" => input.carbon_intensity_threshold.to_s,
            "PREFERRED_REGIONS" => input.preferred_regions.join(","),
            "MIN_WINDOW_HOURS" => input.min_execution_window_hours.to_s,
            "MAX_WINDOW_HOURS" => input.max_execution_window_hours.to_s,
            "CARBON_DATA_SOURCE" => input.carbon_data_source
          }
        end

        def executor_env_vars(input, workload_table)
          {
            "WORKLOAD_TABLE" => workload_table.table_name,
            "WORKLOAD_TYPE" => input.workload_type,
            "USE_SPOT" => input.use_spot_instances.to_s,
            "ENABLE_CARBON_REPORTING" => input.enable_carbon_reporting.to_s
          }
        end

        def monitor_env_vars(input, carbon_table)
          {
            "CARBON_TABLE" => carbon_table.table_name,
            "CARBON_DATA_SOURCE" => input.carbon_data_source,
            "PREFERRED_REGIONS" => input.preferred_regions.join(","),
            "ENABLE_REPORTING" => input.enable_carbon_reporting.to_s
          }
        end
      end
    end
  end
end
