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
    module GreenDataLifecycle
      # Lambda function resources for Green Data Lifecycle component
      module Functions
        private

        def create_access_analyzer_function(input, role, bucket)
          aws_lambda_function(:"#{input.name}-access-analyzer", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 300,
            memory_size: 512,
            environment: {
              variables: access_analyzer_env_vars(input, bucket)
            },
            code: { zip_file: generate_access_analyzer_code(input) },
            tags: function_tags(input, "access-analyzer")
          })
        end

        def create_carbon_optimizer_function(input, role, bucket)
          aws_lambda_function(:"#{input.name}-carbon-optimizer", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 900,
            memory_size: 1024,
            environment: {
              variables: carbon_optimizer_env_vars(input, bucket)
            },
            code: { zip_file: generate_carbon_optimizer_code(input) },
            tags: function_tags(input, "carbon-optimizer")
          })
        end

        def create_lifecycle_manager_function(input, role, bucket)
          aws_lambda_function(:"#{input.name}-lifecycle-manager", {
            runtime: "python3.11",
            handler: "index.handler",
            role: role.arn,
            timeout: 900,
            memory_size: 512,
            environment: {
              variables: lifecycle_manager_env_vars(input, bucket)
            },
            code: { zip_file: generate_lifecycle_manager_code(input) },
            tags: function_tags(input, "lifecycle-manager")
          })
        end

        def access_analyzer_env_vars(input, bucket)
          {
            "BUCKET_NAME" => bucket.bucket,
            "ANALYSIS_WINDOW_DAYS" => input.access_pattern_window_days.to_s,
            "OPTIMIZE_READ_HEAVY" => input.optimize_for_read_heavy.to_s,
            "MONITOR_PATTERNS" => input.monitor_access_patterns.to_s
          }
        end

        def carbon_optimizer_env_vars(input, bucket)
          {
            "BUCKET_NAME" => bucket.bucket,
            "CARBON_THRESHOLD" => input.carbon_threshold_gco2_per_gb.to_s,
            "PREFER_RENEWABLE" => input.prefer_renewable_regions.to_s,
            "LIFECYCLE_STRATEGY" => input.lifecycle_strategy
          }
        end

        def lifecycle_manager_env_vars(input, bucket)
          {
            "BUCKET_NAME" => bucket.bucket,
            "COMPLIANCE_MODE" => input.compliance_mode.to_s,
            "DELETION_PROTECTION" => input.deletion_protection.to_s,
            "LEGAL_HOLD_TAGS" => input.legal_hold_tags.join(",")
          }
        end
      end
    end
  end
end
