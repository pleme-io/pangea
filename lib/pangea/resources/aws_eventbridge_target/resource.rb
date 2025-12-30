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
require 'pangea/resources/reference'
require 'pangea/resources/aws_eventbridge_target/types'
require 'pangea/resource_registry'
require_relative 'ecs_target_builder'
require_relative 'batch_target_builder'

module Pangea
  module Resources
    module AWS
      # Create an AWS EventBridge Target with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] EventBridge target attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_eventbridge_target(name, attributes = {})
        # Validate attributes using dry-struct
        target_attrs = Types::EventBridgeTargetAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudwatch_event_target, name) do
          rule target_attrs.rule
          event_bus_name target_attrs.event_bus_name
          target_id target_attrs.target_id
          arn target_attrs.arn
          
          # Role ARN for target invocation
          role_arn target_attrs.role_arn if target_attrs.role_arn
          
          # Input configuration (mutually exclusive)
          input target_attrs.input if target_attrs.input
          input_path target_attrs.input_path if target_attrs.input_path
          
          # Input transformer
          if target_attrs.input_transformer
            input_transformer do
              input_paths target_attrs.input_transformer[:input_paths] if target_attrs.input_transformer[:input_paths]
              input_template target_attrs.input_transformer[:input_template]
            end
          end
          
          # Retry policy
          if target_attrs.retry_policy
            retry_policy do
              maximum_retry_attempts target_attrs.retry_policy[:maximum_retry_attempts] if target_attrs.retry_policy[:maximum_retry_attempts]
              maximum_event_age_in_seconds target_attrs.retry_policy[:maximum_event_age_in_seconds] if target_attrs.retry_policy[:maximum_event_age_in_seconds]
            end
          end
          
          # Dead letter config
          if target_attrs.dead_letter_config
            dead_letter_config do
              arn target_attrs.dead_letter_config[:arn] if target_attrs.dead_letter_config[:arn]
            end
          end
          
          # HTTP parameters (for API destinations)
          if target_attrs.http_parameters
            http_parameters do
              path_parameter_values target_attrs.http_parameters[:path_parameter_values] if target_attrs.http_parameters[:path_parameter_values]
              header_parameters target_attrs.http_parameters[:header_parameters] if target_attrs.http_parameters[:header_parameters]
              query_string_parameters target_attrs.http_parameters[:query_string_parameters] if target_attrs.http_parameters[:query_string_parameters]
            end
          end
          
          # Kinesis parameters
          if target_attrs.kinesis_parameters
            kinesis_parameters do
              partition_key_path target_attrs.kinesis_parameters[:partition_key_path] if target_attrs.kinesis_parameters[:partition_key_path]
            end
          end
          
          # SQS parameters
          if target_attrs.sqs_parameters
            sqs_parameters do
              message_group_id target_attrs.sqs_parameters[:message_group_id] if target_attrs.sqs_parameters[:message_group_id]
            end
          end
          
          # ECS parameters
          if target_attrs.ecs_parameters
            ecs_parameters(&EcsTargetBuilder.ecs_parameters_block(target_attrs.ecs_parameters))
          end
          
          # Batch parameters
          if target_attrs.batch_parameters
            batch_parameters(&BatchTargetBuilder.batch_parameters_block(target_attrs.batch_parameters))
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudwatch_event_target',
          name: name,
          resource_attributes: target_attrs.to_h,
          outputs: {
            id: "${aws_cloudwatch_event_target.#{name}.id}",
            rule: "${aws_cloudwatch_event_target.#{name}.rule}",
            target_id: "${aws_cloudwatch_event_target.#{name}.target_id}",
            arn: "${aws_cloudwatch_event_target.#{name}.arn}",
            event_bus_name: "${aws_cloudwatch_event_target.#{name}.event_bus_name}"
          },
          computed_properties: {
            target_type: target_attrs.target_type,
            is_lambda_target: target_attrs.is_lambda_target?,
            is_sqs_target: target_attrs.is_sqs_target?,
            is_sns_target: target_attrs.is_sns_target?,
            is_kinesis_target: target_attrs.is_kinesis_target?,
            is_ecs_target: target_attrs.is_ecs_target?,
            is_batch_target: target_attrs.is_batch_target?,
            is_api_gateway_target: target_attrs.is_api_gateway_target?,
            is_fifo_sqs: target_attrs.is_fifo_sqs?,
            has_role: target_attrs.has_role?,
            has_input_transformation: target_attrs.has_input_transformation?,
            has_retry_policy: target_attrs.has_retry_policy?,
            has_dead_letter_queue: target_attrs.has_dead_letter_queue?,
            uses_default_bus: target_attrs.uses_default_bus?,
            uses_custom_bus: target_attrs.uses_custom_bus?,
            max_retry_attempts: target_attrs.max_retry_attempts,
            max_event_age_hours: target_attrs.max_event_age_hours,
            estimated_monthly_cost: target_attrs.estimated_monthly_cost,
            target_service: target_attrs.target_service,
            reliability_features: target_attrs.reliability_features
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)