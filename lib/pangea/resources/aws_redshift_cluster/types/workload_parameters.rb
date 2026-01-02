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

require 'json'

module Pangea
  module Resources
    module AWS
      module Types
        # Default cluster parameter group settings by workload type
        module RedshiftWorkloadParameters
          ETL_PARAMETERS = {
            'max_concurrency_scaling_clusters' => '1',
            'enable_user_activity_logging' => 'true',
            'statement_timeout' => '0',
            'wlm_json_configuration' => JSON.generate([{
              'query_group' => 'etl',
              'memory_percent_to_use' => 70,
              'max_execution_time' => 0
            }])
          }.freeze

          ANALYTICS_PARAMETERS = {
            'max_concurrency_scaling_clusters' => '3',
            'enable_user_activity_logging' => 'true',
            'statement_timeout' => '600000',
            'search_path' => 'analytics,public',
            'wlm_json_configuration' => JSON.generate([{
              'query_group' => 'analytics',
              'memory_percent_to_use' => 50,
              'max_execution_time' => 300_000
            }])
          }.freeze

          MIXED_PARAMETERS = {
            'max_concurrency_scaling_clusters' => '2',
            'enable_user_activity_logging' => 'true',
            'auto_analyze' => 'true',
            'datestyle' => 'ISO, MDY'
          }.freeze

          def self.for_workload(workload)
            case workload.to_s
            when 'etl' then ETL_PARAMETERS
            when 'analytics' then ANALYTICS_PARAMETERS
            when 'mixed' then MIXED_PARAMETERS
            else {}
            end
          end
        end
      end
    end
  end
end
