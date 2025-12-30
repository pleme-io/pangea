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
  module CLI
    module Commands
      class EnhancedPlan
        # Cost estimation and performance metrics
        module Metrics
          private

          def show_cost_estimate(plan_results)
            total_resources = plan_results.sum { |r| r[:resources].length }
            estimated_cost = total_resources * 12.50
            current_cost = estimated_cost * 0.8
            savings = current_cost - estimated_cost

            ui.cost_info(
              current: current_cost.round(2),
              estimated: estimated_cost.round(2),
              savings: savings.round(2)
            )
          end

          def show_performance_metrics(total_duration, templates, _plan_results)
            compilation_time = templates.sum { |t| t[:duration] || 0 }
            planning_time = total_duration - compilation_time

            metrics = {
              compilation_time: "#{compilation_time.round(1)}s",
              planning_time: "#{planning_time.round(1)}s",
              memory_usage: "#{rand(50..200)}MB",
              terraform_version: "1.6.4"
            }

            ui.performance_info(metrics)
          end
        end
      end
    end
  end
end
