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
        module RedshiftParameterGroupInstanceMethods
          def parameter_value(name)
            param = parameters.find { |p| p[:name] == name }
            param ? param[:value] : nil
          end

          def has_parameter?(name)
            parameters.any? { |p| p[:name] == name }
          end

          def has_wlm_configuration?
            has_parameter?('wlm_json_configuration')
          end

          def query_monitoring_enabled?
            parameter_value('enable_user_activity_logging') == 'true'
          end

          def result_caching_enabled?
            parameter_value('enable_result_cache_for_session') != 'false'
          end

          def concurrency_scaling_enabled?
            max_clusters = parameter_value('max_concurrency_scaling_clusters')
            max_clusters && max_clusters.to_i.positive?
          end

          def concurrency_scaling_limit
            max_clusters = parameter_value('max_concurrency_scaling_clusters')
            max_clusters ? max_clusters.to_i : 0
          end

          def auto_analyze_enabled?
            parameter_value('auto_analyze') != 'false'
          end

          def generated_description
            description || "Redshift parameter group for #{name}"
          end

          def performance_impact_score
            score = calculate_base_performance_score
            score = apply_timeout_adjustment(score)
            score.round(2)
          end

          private

          def calculate_base_performance_score
            score = 1.0
            score *= 1.2 if result_caching_enabled?
            score *= 1.3 if concurrency_scaling_enabled?
            score *= 1.1 if auto_analyze_enabled?
            score
          end

          def apply_timeout_adjustment(score)
            return score unless has_parameter?('statement_timeout')

            timeout = parameter_value('statement_timeout').to_i
            score *= 0.9 if timeout.positive? && timeout < 300_000
            score
          end
        end
      end
    end
  end
end
