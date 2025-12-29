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
    module SpotInstanceCarbonOptimizer
      # Lambda function creation methods
      module Functions
        def create_carbon_monitor_function(input, role, carbon_table)
          aws_lambda_function(:"#{input.name}-carbon-monitor", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 300,
            memory_size: 512,
            environment: {
              variables: {
                "CARBON_TABLE": carbon_table.table_name,
                "ALLOWED_REGIONS": input.allowed_regions.join(","),
                "RENEWABLE_MINIMUM": input.renewable_percentage_minimum.to_s,
                "REPORTING_INTERVAL": input.carbon_reporting_interval_minutes.to_s
              }
            },
            code: {
              zip_file: generate_carbon_monitor_code(input)
            },
            tags: input.tags.merge(
              "Component" => "spot-carbon-optimizer",
              "Function" => "carbon-monitor"
            )
          })
        end

        def create_fleet_optimizer_function(input, role, state_table, carbon_table)
          aws_lambda_function(:"#{input.name}-fleet-optimizer", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 900,
            memory_size: 1024,
            environment: {
              variables: {
                "FLEET_STATE_TABLE": state_table.table_name,
                "CARBON_TABLE": carbon_table.table_name,
                "OPTIMIZATION_STRATEGY": input.optimization_strategy,
                "CARBON_THRESHOLD": input.carbon_intensity_threshold.to_s,
                "TARGET_CAPACITY": input.target_capacity.to_s,
                "ALLOWED_REGIONS": input.allowed_regions.join(","),
                "PREFERRED_REGIONS": input.preferred_regions.join(",")
              }
            },
            code: {
              zip_file: generate_fleet_optimizer_code(input)
            },
            tags: input.tags.merge(
              "Component" => "spot-carbon-optimizer",
              "Function" => "fleet-optimizer"
            )
          })
        end

        def create_migration_orchestrator_function(input, role, state_table, history_table)
          aws_lambda_function(:"#{input.name}-migration-orchestrator", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 900,
            memory_size: 512,
            environment: {
              variables: {
                "FLEET_STATE_TABLE": state_table.table_name,
                "MIGRATION_HISTORY_TABLE": history_table.table_name,
                "MIGRATION_STRATEGY": input.migration_strategy,
                "MIGRATION_THRESHOLD": input.migration_threshold_minutes.to_s,
                "WORKLOAD_TYPE": input.workload_type,
                "ENABLE_CROSS_REGION": input.enable_cross_region_migration.to_s
              }
            },
            code: {
              zip_file: generate_migration_orchestrator_code(input)
            },
            tags: input.tags.merge(
              "Component" => "spot-carbon-optimizer",
              "Function" => "migration-orchestrator"
            )
          })
        end
      end
    end
  end
end
