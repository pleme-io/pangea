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


require 'pangea/resources/base'
require 'pangea/resources/aws_sagemaker_endpoint/types'
require 'pangea/resource_registry'
require_relative 'reference_attributes'

module Pangea
  module Resources
    module AWS
      # SageMaker Endpoint resource for deploying models for real-time inference
      # 
      # An endpoint hosts models for real-time inference using the infrastructure
      # defined in an endpoint configuration. Supports blue-green deployments,
      # auto-rollback, and advanced deployment strategies for production ML systems.
      #
      # @example Basic real-time inference endpoint
      #   aws_sagemaker_endpoint(:fraud_endpoint, {
      #     endpoint_name: "fraud-detection-endpoint",
      #     endpoint_config_name: fraud_config_ref.name
      #   })
      #
      # @example Production endpoint with blue-green deployment
      #   aws_sagemaker_endpoint(:production_endpoint, {
      #     endpoint_name: "fraud-production-endpoint",
      #     endpoint_config_name: fraud_config_ref.name,
      #     deployment_config: {
      #       blue_green_update_policy: {
      #         traffic_routing_configuration: {
      #           type: "CANARY",
      #           wait_interval_in_seconds: 600,
      #           canary_size: {
      #             type: "CAPACITY_PERCENT",
      #             value: 10
      #           }
      #         },
      #         termination_wait_in_seconds: 300,
      #         maximum_execution_timeout_in_seconds: 3600
      #       },
      #       auto_rollback_configuration: {
      #         alarms: [
      #           { alarm_name: model_latency_alarm_ref.alarm_name },
      #           { alarm_name: model_error_rate_alarm_ref.alarm_name },
      #           { alarm_name: model_invocation_4xx_alarm_ref.alarm_name },
      #           { alarm_name: model_invocation_5xx_alarm_ref.alarm_name }
      #         ]
      #       }
      #     },
      #     tags: {
      #       Environment: "production",
      #       Service: "fraud-detection",
      #       DeploymentStrategy: "blue-green",
      #       MonitoringLevel: "enhanced"
      #     }
      #   })
      #
      # @example Linear deployment strategy
      #   aws_sagemaker_endpoint(:gradual_deployment_endpoint, {
      #     endpoint_name: "gradual-rollout-endpoint",
      #     endpoint_config_name: new_config_ref.name,
      #     deployment_config: {
      #       blue_green_update_policy: {
      #         traffic_routing_configuration: {
      #           type: "LINEAR",
      #           wait_interval_in_seconds: 300,
      #           linear_step_size: {
      #             type: "CAPACITY_PERCENT",
      #             value: 20
      #           }
      #         },
      #         termination_wait_in_seconds: 600,
      #         maximum_execution_timeout_in_seconds: 7200
      #       },
      #       auto_rollback_configuration: {
      #         alarms: [
      #           { alarm_name: endpoint_latency_p99_alarm_ref.alarm_name },
      #           { alarm_name: endpoint_error_rate_alarm_ref.alarm_name }
      #         ]
      #       }
      #     }
      #   })
      #
      # @example All-at-once deployment with comprehensive monitoring
      #   aws_sagemaker_endpoint(:fast_deployment_endpoint, {
      #     endpoint_name: "fast-update-endpoint",
      #     endpoint_config_name: updated_config_ref.name,
      #     deployment_config: {
      #       blue_green_update_policy: {
      #         traffic_routing_configuration: {
      #           type: "ALL_AT_ONCE",
      #           wait_interval_in_seconds: 0
      #         },
      #         termination_wait_in_seconds: 120,
      #         maximum_execution_timeout_in_seconds: 1800
      #       },
      #       auto_rollback_configuration: {
      #         alarms: [
      #           { alarm_name: critical_error_alarm_ref.alarm_name },
      #           { alarm_name: availability_alarm_ref.alarm_name },
      #           { alarm_name: performance_alarm_ref.alarm_name }
      #         ]
      #       }
      #     },
      #     tags: {
      #       DeploymentType: "emergency-fix",
      #       RollbackEnabled: "true"
      #     }
      #   })
      class SageMakerEndpoint < Base
        def self.resource_type
          'aws_sagemaker_endpoint'
        end
        
        def self.attribute_struct
          Types::SageMakerEndpointAttributes
        end
      end
      
      # Resource function for aws_sagemaker_endpoint
      # 
      # @param name [Symbol] The resource name
      # @param attributes [Hash] The resource attributes
      # @return [ResourceReference] Reference to the created resource
      def aws_sagemaker_endpoint(name, attributes)
        resource = SageMakerEndpoint.new(
          name: name,
          attributes: attributes
        )
        
        add_resource(resource)
        
        # Return resource reference with computed attributes
        ResourceReference.new(
          name: name,
          type: :aws_sagemaker_endpoint,
          attributes: SageMakerEndpointReferenceAttributes.build(name, attributes)
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)