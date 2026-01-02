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
        # Computed properties for SageMaker Endpoint
        module SageMakerEndpointComputedProperties
          def estimated_monthly_cost
            # Endpoint itself has no cost, costs come from the underlying endpoint configuration
            # This would typically be calculated based on the endpoint config instances
            base_cost = 0.0

            # Add monitoring and logging overhead
            monitoring_cost = has_deployment_config? ? 5.0 : 0.0

            base_cost + monitoring_cost
          end

          def has_deployment_config?
            !deployment_config.nil?
          end

          def has_blue_green_deployment?
            deployment_config&.dig(:blue_green_update_policy) != nil
          end

          def has_auto_rollback?
            deployment_config&.dig(:auto_rollback_configuration) != nil
          end

          def supports_canary_deployments?
            return false unless has_blue_green_deployment?

            traffic_type = deployment_config.dig(:blue_green_update_policy, :traffic_routing_configuration, :type)
            traffic_type == 'CANARY'
          end

          def supports_linear_deployments?
            return false unless has_blue_green_deployment?

            traffic_type = deployment_config.dig(:blue_green_update_policy, :traffic_routing_configuration, :type)
            traffic_type == 'LINEAR'
          end

          def deployment_strategy
            return 'all-at-once' unless has_blue_green_deployment?

            traffic_type = deployment_config.dig(:blue_green_update_policy, :traffic_routing_configuration, :type)
            traffic_type&.downcase&.gsub('_', '-') || 'all-at-once'
          end

          def traffic_routing_wait_time
            return 0 unless has_blue_green_deployment?

            deployment_config.dig(:blue_green_update_policy, :traffic_routing_configuration, :wait_interval_in_seconds) || 0
          end

          def termination_wait_time
            return 0 unless has_blue_green_deployment?

            deployment_config.dig(:blue_green_update_policy, :termination_wait_in_seconds) || 0
          end

          def max_deployment_timeout
            return 3600 unless has_blue_green_deployment? # Default 1 hour

            deployment_config.dig(:blue_green_update_policy, :maximum_execution_timeout_in_seconds) || 3600
          end

          def rollback_alarm_count
            return 0 unless has_auto_rollback?

            deployment_config.dig(:auto_rollback_configuration, :alarms)&.size || 0
          end

          def rollback_alarm_names
            return [] unless has_auto_rollback?

            alarms = deployment_config.dig(:auto_rollback_configuration, :alarms) || []
            alarms.map { |alarm| alarm[:alarm_name] }
          end
        end
      end
    end
  end
end
