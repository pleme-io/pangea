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
        # Deployment analysis methods for SageMaker Endpoint
        module SageMakerEndpointDeploymentAnalysis
          # Deployment capability analysis
          def deployment_capabilities
            {
              strategy: deployment_strategy,
              supports_canary: supports_canary_deployments?,
              supports_linear: supports_linear_deployments?,
              supports_auto_rollback: has_auto_rollback?,
              traffic_wait_time: traffic_routing_wait_time,
              termination_wait_time: termination_wait_time,
              max_timeout: max_deployment_timeout,
              rollback_alarms: rollback_alarm_count
            }
          end

          # Canary deployment configuration
          def canary_configuration
            return nil unless supports_canary_deployments?

            canary_size = deployment_config.dig(:blue_green_update_policy, :traffic_routing_configuration, :canary_size)
            return nil unless canary_size

            {
              type: canary_size[:type],
              value: canary_size[:value],
              unit: canary_size[:type] == 'INSTANCE_COUNT' ? 'instances' : 'percent'
            }
          end

          # Linear deployment configuration
          def linear_configuration
            return nil unless supports_linear_deployments?

            linear_step = deployment_config.dig(:blue_green_update_policy, :traffic_routing_configuration, :linear_step_size)
            return nil unless linear_step

            {
              type: linear_step[:type],
              value: linear_step[:value],
              unit: linear_step[:type] == 'INSTANCE_COUNT' ? 'instances' : 'percent'
            }
          end

          # Security and operational assessment
          def operational_score
            score = 0
            score += 30 if has_blue_green_deployment?
            score += 25 if has_auto_rollback?
            score += 20 if supports_canary_deployments? || supports_linear_deployments?
            score += 15 if rollback_alarm_count >= 2 # Multiple monitoring points
            score += 10 if traffic_routing_wait_time > 0 # Allows monitoring before full deployment

            [score, 100].min
          end

          def operational_status
            issues = []
            issues << "No blue-green deployment strategy configured" unless has_blue_green_deployment?
            issues << "No auto-rollback configuration" unless has_auto_rollback?
            issues << "Immediate traffic switching without monitoring period" if has_blue_green_deployment? && traffic_routing_wait_time == 0
            issues << "No rollback monitoring alarms configured" if has_auto_rollback? && rollback_alarm_count == 0
            issues << "Single alarm for rollback - consider multiple metrics" if rollback_alarm_count == 1

            {
              status: issues.empty? ? 'optimal' : 'needs_improvement',
              issues: issues
            }
          end

          # Endpoint summary for monitoring and management
          def endpoint_summary
            {
              endpoint_name: endpoint_name,
              endpoint_config_name: endpoint_config_name,
              deployment_strategy: deployment_strategy,
              operational_score: operational_score,
              estimated_monthly_cost: estimated_monthly_cost,
              capabilities: deployment_capabilities,
              canary_config: canary_configuration,
              linear_config: linear_configuration,
              rollback_alarms: rollback_alarm_names
            }
          end
        end
      end
    end
  end
end
