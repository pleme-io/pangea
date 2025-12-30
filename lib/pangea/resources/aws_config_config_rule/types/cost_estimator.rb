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
        # Cost estimation for AWS Config Config Rule
        module ConfigConfigRuleCostEstimator
          COST_PER_EVALUATION = 0.001
          LAMBDA_COST_PER_GB_SECOND = 0.0000166667
          DEFAULT_LAMBDA_MEMORY_MB = 128
          DEFAULT_LAMBDA_EXECUTION_MS = 5000
          DEFAULT_CHANGE_TRIGGERED_EVALUATIONS = 100

          FREQUENCY_EVALUATIONS = {
            'One_Hour' => 30 * 24,
            'Three_Hours' => 30 * 8,
            'Six_Hours' => 30 * 4,
            'Twelve_Hours' => 30 * 2,
            'TwentyFour_Hours' => 30
          }.freeze

          module_function

          def estimate_monthly_cost(attributes)
            base_evaluations = calculate_base_evaluations(attributes)
            evaluations = apply_resource_scope_multiplier(base_evaluations, attributes)

            evaluation_cost = evaluations * COST_PER_EVALUATION
            lambda_cost = calculate_lambda_cost(evaluations, attributes)

            (evaluation_cost + lambda_cost).round(4)
          end

          def calculate_base_evaluations(attributes)
            if attributes.has_periodic_execution?
              FREQUENCY_EVALUATIONS.fetch(attributes.maximum_execution_frequency, 30)
            else
              DEFAULT_CHANGE_TRIGGERED_EVALUATIONS
            end
          end

          def apply_resource_scope_multiplier(base_evaluations, attributes)
            return base_evaluations unless attributes.has_resource_type_scope?

            resource_count = attributes.scope[:compliance_resource_types].length
            resource_multiplier = [resource_count / 5.0, 1.0].max
            (base_evaluations * resource_multiplier).to_i
          end

          def calculate_lambda_cost(evaluations, attributes)
            return 0.0 unless attributes.is_custom_lambda?

            gb_seconds = (DEFAULT_LAMBDA_MEMORY_MB / 1024.0) *
                         (DEFAULT_LAMBDA_EXECUTION_MS / 1000.0) *
                         evaluations
            gb_seconds * LAMBDA_COST_PER_GB_SECOND
          end
        end
      end
    end
  end
end
