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
      module Types
        # Instance methods for Athena Workgroup attributes
        module AthenaWorkgroupInstanceMethods
          # Check if workgroup is enabled
          def enabled?
            state == 'ENABLED'
          end

          # Check if workgroup has output location
          def has_output_location?
            configuration &&
              configuration[:result_configuration] &&
              configuration[:result_configuration][:output_location]
          end

          # Check if workgroup enforces configuration
          def enforces_configuration?
            configuration && configuration[:enforce_workgroup_configuration] == true
          end

          # Check if CloudWatch metrics are enabled
          def cloudwatch_metrics_enabled?
            configuration && configuration[:publish_cloudwatch_metrics_enabled] == true
          end

          # Get encryption type
          def encryption_type
            return nil unless configuration &&
                              configuration[:result_configuration] &&
                              configuration[:result_configuration][:encryption_configuration]

            configuration[:result_configuration][:encryption_configuration][:encryption_option]
          end

          # Check if using KMS encryption
          def uses_kms?
            %w[SSE_KMS CSE_KMS].include?(encryption_type)
          end

          # Check if workgroup has query limits
          def has_query_limits?
            configuration && configuration[:bytes_scanned_cutoff_per_query]
          end

          # Calculate query limit in GB
          def query_limit_gb
            return nil unless has_query_limits?

            configuration[:bytes_scanned_cutoff_per_query] / 1_073_741_824.0
          end

          # Estimate monthly cost based on configuration
          def estimated_monthly_cost_usd
            # Base cost: $5 per TB scanned
            # Assume average queries based on workgroup type
            avg_tb_per_month = estimate_avg_tb_per_month

            # Reduce estimate if query limits are set
            if has_query_limits?
              max_tb_per_query = query_limit_gb / 1024.0
              avg_tb_per_month = [avg_tb_per_month, max_tb_per_query * 1000].min
            end

            avg_tb_per_month * 5.0
          end

          private

          def estimate_avg_tb_per_month
            case name
            when /primary|default/i
              2.0
            when /development|dev/i
              0.5
            when /production|prod/i
              5.0
            else
              1.0
            end
          end
        end
      end
    end
  end
end
