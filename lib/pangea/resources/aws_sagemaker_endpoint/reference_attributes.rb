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
      # Builds reference attributes for SageMaker Endpoint resources
      module SageMakerEndpointReferenceAttributes
        module_function

        # Builds the complete attributes hash for ResourceReference
        # @param name [Symbol] The resource name
        # @param attributes [Hash] The resource attributes
        # @return [Hash] The reference attributes
        def build(name, attributes)
          {
            # Direct attributes
            id: "${aws_sagemaker_endpoint.#{name}.id}",
            arn: "${aws_sagemaker_endpoint.#{name}.arn}",
            name: "${aws_sagemaker_endpoint.#{name}.name}",
            endpoint_name: "${aws_sagemaker_endpoint.#{name}.name}",
            endpoint_config_name: "${aws_sagemaker_endpoint.#{name}.endpoint_config_name}",

            # Computed attributes
            creation_time: "${aws_sagemaker_endpoint.#{name}.creation_time}",
            last_modified_time: "${aws_sagemaker_endpoint.#{name}.last_modified_time}",
            endpoint_status: "${aws_sagemaker_endpoint.#{name}.endpoint_status}",

            # Helper attributes for integration
            inference_url: "https://runtime.sagemaker.${data.aws_region.current.name}.amazonaws.com/endpoints/${aws_sagemaker_endpoint.#{name}.name}/invocations",

            # Deployment configuration attributes
            has_deployment_config: !attributes[:deployment_config].nil?,
            has_blue_green: !attributes.dig(:deployment_config, :blue_green_update_policy).nil?,
            has_auto_rollback: !attributes.dig(:deployment_config, :auto_rollback_configuration).nil?,

            deployment_strategy: compute_deployment_strategy(attributes),
            supports_canary: traffic_routing_type(attributes) == 'CANARY',
            supports_linear: traffic_routing_type(attributes) == 'LINEAR',

            # Monitoring and rollback attributes
            rollback_alarm_count: attributes.dig(:deployment_config, :auto_rollback_configuration, :alarms)&.size || 0,
            rollback_alarms: extract_alarm_names(attributes),

            # Timing configuration
            traffic_wait_time: attributes.dig(:deployment_config, :blue_green_update_policy, :traffic_routing_configuration, :wait_interval_in_seconds) || 0,
            termination_wait_time: attributes.dig(:deployment_config, :blue_green_update_policy, :termination_wait_in_seconds) || 0,
            max_deployment_timeout: attributes.dig(:deployment_config, :blue_green_update_policy, :maximum_execution_timeout_in_seconds) || 3600,

            # Canary configuration (if applicable)
            canary_size: compute_canary_size(attributes),

            # Linear configuration (if applicable)
            linear_step_size: compute_linear_step_size(attributes),

            # Operational score
            operational_score: compute_operational_score(attributes)
          }
        end

        # Extracts traffic routing type from attributes
        def traffic_routing_type(attributes)
          attributes.dig(:deployment_config, :blue_green_update_policy, :traffic_routing_configuration, :type)
        end

        # Computes deployment strategy from attributes
        def compute_deployment_strategy(attributes)
          if attributes.dig(:deployment_config, :blue_green_update_policy)
            traffic_type = traffic_routing_type(attributes)
            traffic_type&.downcase&.gsub('_', '-') || 'all-at-once'
          else
            'all-at-once'
          end
        end

        # Extracts alarm names from rollback configuration
        def extract_alarm_names(attributes)
          attributes.dig(:deployment_config, :auto_rollback_configuration, :alarms)&.map { |a| a[:alarm_name] } || []
        end

        # Computes canary size configuration if applicable
        def compute_canary_size(attributes)
          return nil unless traffic_routing_type(attributes) == 'CANARY'

          canary = attributes.dig(:deployment_config, :blue_green_update_policy, :traffic_routing_configuration, :canary_size)
          canary ? { type: canary[:type], value: canary[:value] } : nil
        end

        # Computes linear step size configuration if applicable
        def compute_linear_step_size(attributes)
          return nil unless traffic_routing_type(attributes) == 'LINEAR'

          linear = attributes.dig(:deployment_config, :blue_green_update_policy, :traffic_routing_configuration, :linear_step_size)
          linear ? { type: linear[:type], value: linear[:value] } : nil
        end

        # Computes operational score using Types struct
        def compute_operational_score(attributes)
          endpoint_attrs = Types::SageMakerEndpointAttributes.new(attributes)
          endpoint_attrs.operational_score
        rescue StandardError
          0
        end
      end
    end
  end
end
