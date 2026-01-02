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
require 'pangea/resources/aws_cloudwatch_event_target/types'
require 'pangea/resources/aws_cloudwatch_event_target/target_builders'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      include CloudWatchEventTargetBuilders

      # Create an AWS CloudWatch Event Target with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudWatch Event Target attributes
      # @option attributes [String] :rule The name of the rule
      # @option attributes [String] :arn ARN of the target resource
      # @option attributes [String] :target_id Unique target ID
      # @option attributes [String] :event_bus_name Event bus name (default: "default")
      # @option attributes [String] :input JSON text to pass to target
      # @option attributes [String] :input_path JSONPath to extract from event
      # @option attributes [Hash] :input_transformer Input transformation configuration
      # @option attributes [String] :role_arn IAM role for the target
      # @option attributes [Hash] :ecs_target ECS task configuration
      # @option attributes [Hash] :batch_target Batch job configuration
      # @option attributes [Hash] :retry_policy Retry policy configuration
      # @option attributes [Hash] :dead_letter_config Dead letter queue configuration
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Lambda function target
      #   lambda_target = aws_cloudwatch_event_target(:lambda_processor, {
      #     rule: event_rule.name,
      #     arn: processor_lambda.arn
      #   })
      #
      # @example ECS task target with retry policy
      #   ecs_target = aws_cloudwatch_event_target(:ecs_task, {
      #     rule: scheduled_rule.name,
      #     arn: ecs_cluster.arn,
      #     role_arn: ecs_events_role.arn,
      #     ecs_target: { task_definition_arn: task_definition.arn, task_count: 1 },
      #     retry_policy: { maximum_retry_attempts: 2, maximum_event_age_in_seconds: 3600 }
      #   })
      def aws_cloudwatch_event_target(name, attributes = {})
        target_attrs = Types::Types::CloudWatchEventTargetAttributes.new(attributes)

        resource(:aws_cloudwatch_event_target, name) do
          rule target_attrs.rule
          arn target_attrs.arn
          target_id target_attrs.target_id if target_attrs.target_id
          event_bus_name target_attrs.event_bus_name if target_attrs.event_bus_name != 'default'
          build_input_configuration(self, target_attrs)
          role_arn target_attrs.role_arn if target_attrs.role_arn
          build_target_configurations(self, target_attrs)
          build_error_handling(self, target_attrs)
        end

        build_resource_reference(name, target_attrs)
      end

      private

      def build_input_configuration(context, target_attrs)
        if target_attrs.input
          context.input target_attrs.input
        elsif target_attrs.input_path
          context.input_path target_attrs.input_path
        elsif target_attrs.input_transformer
          context.input_transformer do
            input_paths_map target_attrs.input_transformer.input_paths_map if target_attrs.input_transformer.input_paths_map.any?
            input_template target_attrs.input_transformer.input_template
          end
        end
      end

      def build_target_configurations(context, target_attrs)
        build_ecs_target(context, target_attrs.ecs_target) if target_attrs.ecs_target
        build_batch_target(context, target_attrs.batch_target) if target_attrs.batch_target
        build_kinesis_target(context, target_attrs.kinesis_target) if target_attrs.kinesis_target
        build_sqs_target(context, target_attrs.sqs_target) if target_attrs.sqs_target
        build_http_target(context, target_attrs.http_target) if target_attrs.http_target
        build_run_command_targets(context, target_attrs.run_command_targets) if target_attrs.run_command_targets.any?
      end

      def build_error_handling(context, target_attrs)
        if target_attrs.retry_policy
          context.retry_policy do
            maximum_retry_attempts target_attrs.retry_policy.maximum_retry_attempts if target_attrs.retry_policy.maximum_retry_attempts
            maximum_event_age_in_seconds target_attrs.retry_policy.maximum_event_age_in_seconds if target_attrs.retry_policy.maximum_event_age_in_seconds
          end
        end

        if target_attrs.dead_letter_config
          context.dead_letter_config do
            arn target_attrs.dead_letter_config.arn
          end
        end
      end

      def build_resource_reference(name, target_attrs)
        ResourceReference.new(
          type: 'aws_cloudwatch_event_target',
          name: name,
          resource_attributes: target_attrs.to_h,
          outputs: {
            id: "${aws_cloudwatch_event_target.#{name}.id}",
            arn: "${aws_cloudwatch_event_target.#{name}.arn}",
            rule: "${aws_cloudwatch_event_target.#{name}.rule}",
            target_id: "${aws_cloudwatch_event_target.#{name}.target_id}"
          },
          computed_properties: {
            target_service: target_attrs.target_service,
            requires_role: target_attrs.requires_role?,
            has_input_transformation: target_attrs.has_input_transformation?,
            has_retry_policy: target_attrs.has_retry_policy?,
            has_dead_letter_queue: target_attrs.has_dead_letter_queue?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
