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
        module RedshiftParameterGroupClassMethods
          def parameters_for_workload(workload)
            case workload.to_s
            when 'etl' then etl_parameters
            when 'analytics' then analytics_parameters
            when 'reporting' then reporting_parameters
            when 'mixed' then mixed_parameters
            else []
            end
          end

          def wlm_configuration(queues)
            config = queues.map { |queue| build_wlm_queue(queue) }
            { name: 'wlm_json_configuration', value: JSON.generate(config) }
          end

          def query_monitoring_rules(rules)
            config = rules.map { |rule| build_monitoring_rule(rule) }
            { name: 'query_monitoring_rules', value: JSON.generate(config) }
          end

          private

          def etl_parameters
            [
              { name: 'max_concurrency_scaling_clusters', value: '1' },
              { name: 'enable_user_activity_logging', value: 'true' },
              { name: 'statement_timeout', value: '0' },
              { name: 'query_group', value: 'etl' },
              { name: 'enable_result_cache_for_session', value: 'true' },
              { name: 'auto_analyze', value: 'true' },
              { name: 'datestyle', value: 'ISO, MDY' },
              { name: 'extra_float_digits', value: '0' }
            ]
          end

          def analytics_parameters
            [
              { name: 'max_concurrency_scaling_clusters', value: '3' },
              { name: 'enable_user_activity_logging', value: 'true' },
              { name: 'statement_timeout', value: '600000' },
              { name: 'query_group', value: 'analytics' },
              { name: 'enable_result_cache_for_session', value: 'true' },
              { name: 'search_path', value: 'analytics,public' },
              { name: 'require_ssl', value: 'true' }
            ]
          end

          def reporting_parameters
            [
              { name: 'max_concurrency_scaling_clusters', value: '2' },
              { name: 'enable_user_activity_logging', value: 'true' },
              { name: 'statement_timeout', value: '300000' },
              { name: 'query_group', value: 'reporting' },
              { name: 'enable_result_cache_for_session', value: 'true' },
              { name: 'use_fips_ssl', value: 'true' }
            ]
          end

          def mixed_parameters
            [
              { name: 'max_concurrency_scaling_clusters', value: '2' },
              { name: 'enable_user_activity_logging', value: 'true' },
              { name: 'auto_analyze', value: 'true' },
              { name: 'enable_result_cache_for_session', value: 'true' }
            ]
          end

          def build_wlm_queue(queue)
            {
              query_group: queue[:name],
              memory_percent_to_use: queue[:memory_percent] || 25,
              max_execution_time: queue[:timeout_ms] || 0,
              user_group: queue[:user_group] || [],
              query_group_wild_card: queue[:wildcard] || 0,
              priority: queue[:priority] || 'normal'
            }
          end

          def build_monitoring_rule(rule)
            {
              rule_name: rule[:name],
              predicate: rule[:conditions],
              action: rule[:action] || 'log',
              priority: rule[:priority] || 1
            }
          end
        end
      end
    end
  end
end
