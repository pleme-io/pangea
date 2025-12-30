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
        # Instance methods for AWS Glue Job attributes
        module GlueJobInstanceMethods
          # Check if job uses modern worker configuration
          def uses_worker_configuration?
            worker_type && number_of_workers
          end

          # Check if job is streaming
          def is_streaming_job?
            command[:name] == 'gluestreaming'
          end

          # Check if job is Python shell
          def is_python_shell_job?
            command[:name] == 'pythonshell'
          end

          # Check if job is ETL
          def is_etl_job?
            command[:name].nil? || command[:name] == 'glueetl'
          end

          # Get effective Glue version (with defaults)
          def effective_glue_version
            glue_version || (is_python_shell_job? ? '1.0' : '2.0')
          end

          # Get effective Python version
          def effective_python_version
            command[:python_version] || (effective_glue_version >= '2.0' ? '3' : '2')
          end

          # Calculate estimated DPU capacity
          def estimated_dpu_capacity
            if uses_worker_configuration?
              calculate_worker_dpu_capacity
            elsif max_capacity
              max_capacity
            elsif is_python_shell_job?
              0.0625 # Python shell default
            else
              2.0 # ETL job default
            end
          end

          # Estimate hourly cost based on DPU usage
          def estimated_hourly_cost_usd
            dpu_capacity = estimated_dpu_capacity
            # AWS Glue pricing (approximate, varies by region)
            cost_per_dpu_hour = 0.44
            (dpu_capacity * cost_per_dpu_hour).round(4)
          end

          # Check if job configuration is optimal
          def configuration_warnings
            warnings = []
            warnings << 'Consider upgrading to Glue 2.0+ for better performance and features' if glue_version && glue_version < '2.0'
            warnings << 'Consider specifying worker configuration for better resource control' if !uses_worker_configuration? && !max_capacity && !is_python_shell_job?
            warnings << 'Very long timeout (>24h) may indicate job optimization opportunities' if timeout && timeout > 1440
            warnings << 'Consider enabling CloudWatch metrics for streaming jobs' if is_streaming_job? && !default_arguments.key?('--enable-metrics')
            warnings
          end

          private

          def calculate_worker_dpu_capacity
            dpu_multiplier = {
              'Standard' => 1.0, 'G.1X' => 1.0, 'G.2X' => 2.0,
              'G.025X' => 0.25, 'G.4X' => 4.0, 'G.8X' => 8.0, 'Z.2X' => 2.0
            }
            number_of_workers * (dpu_multiplier[worker_type] || 1.0)
          end
        end
      end
    end
  end
end
