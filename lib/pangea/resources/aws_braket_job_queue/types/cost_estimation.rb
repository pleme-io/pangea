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
        # Cost estimation and efficiency methods for BraketJobQueue
        module BraketJobQueueCostEstimation
          # Cost factors based on device type and provider (per minute/shot)
          COST_FACTORS = {
            'AMAZON' => { 'SIMULATOR' => 0.075, default: 1.0 },
            'IONQ' => { 'QPU' => 0.01, default: 1.0 },
            'RIGETTI' => { 'QPU' => 0.00035, default: 1.0 },
            'OQC' => { 'QPU' => 0.00035, default: 1.0 }
          }.freeze

          DEFAULT_COST_FACTOR = 1.0

          def estimated_cost_factor
            provider_costs = COST_FACTORS[device_provider]
            return DEFAULT_COST_FACTOR unless provider_costs

            provider_costs.fetch(device_type, provider_costs.fetch(:default, DEFAULT_COST_FACTOR))
          end

          def efficiency_score
            score = 100

            # Reduce score for disabled queues
            score -= 50 if is_disabled?

            # Reduce score for very low priority
            score -= 20 if priority < 100

            # Add score for proper timeout configuration
            score += 10 if has_timeout? && timeout_hours > 0 && timeout_hours < 24

            # Add score for multiple compute environments (load balancing)
            score += 15 if compute_environment_count > 1

            # Add score for scheduling policy
            score += 5 if has_scheduling_policy?

            [score, 0].max
          end
        end
      end
    end
  end
end
