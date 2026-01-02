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
    module SustainableMLTraining
      # Lambda functions for ML optimization
      module Functions
        def create_carbon_scheduler_function(input, role, state_table, carbon_table)
          aws_lambda_function(:"#{input.name}-carbon-scheduler", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 300,
            memory_size: 512,
            environment: {
              variables: {
                "STATE_TABLE" => state_table.table_name,
                "CARBON_TABLE" => carbon_table.table_name,
                "CARBON_THRESHOLD" => input.carbon_intensity_threshold.to_s,
                "PREFERRED_REGIONS" => input.preferred_training_regions.join(","),
                "TRAINING_STRATEGY" => input.training_strategy
              }
            },
            code: {
              zip_file: generate_carbon_scheduler_code(input)
            },
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "Function" => "carbon-scheduler"
            )
          })
        end

        def create_training_optimizer_function(input, role, state_table)
          aws_lambda_function(:"#{input.name}-training-optimizer", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 900,
            memory_size: 1024,
            environment: {
              variables: {
                "STATE_TABLE" => state_table.table_name,
                "COMPUTE_OPTIMIZATION" => input.compute_optimization,
                "ENABLE_COMPRESSION" => input.enable_model_compression.to_s,
                "TARGET_REDUCTION" => input.target_model_size_reduction.to_s,
                "EARLY_STOPPING" => input.enable_early_stopping.to_s,
                "PATIENCE" => input.early_stopping_patience.to_s
              }
            },
            code: {
              zip_file: generate_training_optimizer_code(input)
            },
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "Function" => "training-optimizer"
            )
          })
        end

        def create_efficiency_monitor_function(input, role, carbon_table)
          aws_lambda_function(:"#{input.name}-efficiency-monitor", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 300,
            memory_size: 512,
            environment: {
              variables: {
                "CARBON_TABLE" => carbon_table.table_name,
                "TRACK_CARBON" => input.track_carbon_emissions.to_s,
                "TRACK_ENERGY" => input.track_energy_usage.to_s,
                "MODEL_TYPE" => input.model_type
              }
            },
            code: {
              zip_file: generate_efficiency_monitor_code(input)
            },
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "Function" => "efficiency-monitor"
            )
          })
        end
      end
    end
  end
end
