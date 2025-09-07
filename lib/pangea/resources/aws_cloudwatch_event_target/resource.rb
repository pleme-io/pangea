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
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
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
      # @example SNS topic with input transformation
      #   sns_target = aws_cloudwatch_event_target(:notification, {
      #     rule: alert_rule.name,
      #     arn: notification_topic.arn,
      #     input_transformer: {
      #       input_paths_map: {
      #         instance: "$.detail.instance",
      #         status: "$.detail.status"
      #       },
      #       input_template: '"Instance <instance> is now <status>"'
      #     }
      #   })
      #
      # @example ECS task target with retry policy
      #   ecs_target = aws_cloudwatch_event_target(:ecs_task, {
      #     rule: scheduled_rule.name,
      #     arn: ecs_cluster.arn,
      #     role_arn: ecs_events_role.arn,
      #     ecs_target: {
      #       task_definition_arn: task_definition.arn,
      #       task_count: 1,
      #       launch_type: "FARGATE",
      #       network_configuration: {
      #         awsvpc_configuration: {
      #           subnets: subnet_ids,
      #           security_groups: [security_group.id],
      #           assign_public_ip: "ENABLED"
      #         }
      #       }
      #     },
      #     retry_policy: {
      #       maximum_retry_attempts: 2,
      #       maximum_event_age_in_seconds: 3600
      #     }
      #   })
      def aws_cloudwatch_event_target(name, attributes = {})
        # Validate attributes using dry-struct
        target_attrs = Types::Types::CloudWatchEventTargetAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudwatch_event_target, name) do
          rule target_attrs.rule
          arn target_attrs.arn
          
          # Optional target ID
          target_id target_attrs.target_id if target_attrs.target_id
          
          # Event bus name if not default
          event_bus_name target_attrs.event_bus_name if target_attrs.event_bus_name != 'default'
          
          # Input configuration (mutually exclusive)
          if target_attrs.input
            input target_attrs.input
          elsif target_attrs.input_path
            input_path target_attrs.input_path
          elsif target_attrs.input_transformer
            input_transformer do
              input_paths_map target_attrs.input_transformer.input_paths_map if target_attrs.input_transformer.input_paths_map.any?
              input_template target_attrs.input_transformer.input_template
            end
          end
          
          # IAM role if required
          role_arn target_attrs.role_arn if target_attrs.role_arn
          
          # Target-specific configurations
          if target_attrs.ecs_target
            ecs_target do
              task_definition_arn target_attrs.ecs_target[:task_definition_arn]
              task_count target_attrs.ecs_target[:task_count] if target_attrs.ecs_target[:task_count]
              launch_type target_attrs.ecs_target[:launch_type] if target_attrs.ecs_target[:launch_type]
              platform_version target_attrs.ecs_target[:platform_version] if target_attrs.ecs_target[:platform_version]
              group target_attrs.ecs_target[:group] if target_attrs.ecs_target[:group]
              
              if target_attrs.ecs_target[:network_configuration]
                network_configuration do
                  if target_attrs.ecs_target[:network_configuration][:awsvpc_configuration]
                    awsvpc_configuration do
                      subnets target_attrs.ecs_target[:network_configuration][:awsvpc_configuration][:subnets]
                      security_groups target_attrs.ecs_target[:network_configuration][:awsvpc_configuration][:security_groups] if target_attrs.ecs_target[:network_configuration][:awsvpc_configuration][:security_groups]
                      assign_public_ip target_attrs.ecs_target[:network_configuration][:awsvpc_configuration][:assign_public_ip] if target_attrs.ecs_target[:network_configuration][:awsvpc_configuration][:assign_public_ip]
                    end
                  end
                end
              end
              
              if target_attrs.ecs_target[:placement_constraints]
                target_attrs.ecs_target[:placement_constraints].each do |constraint|
                  placement_constraint do
                    type constraint[:type]
                    expression constraint[:expression] if constraint[:expression]
                  end
                end
              end
            end
          end
          
          if target_attrs.batch_target
            batch_target do
              job_definition target_attrs.batch_target[:job_definition]
              job_name target_attrs.batch_target[:job_name]
              array_size target_attrs.batch_target[:array_size] if target_attrs.batch_target[:array_size]
              job_attempts target_attrs.batch_target[:job_attempts] if target_attrs.batch_target[:job_attempts]
            end
          end
          
          if target_attrs.kinesis_target
            kinesis_target do
              partition_key_path target_attrs.kinesis_target[:partition_key_path] if target_attrs.kinesis_target[:partition_key_path]
            end
          end
          
          if target_attrs.sqs_target
            sqs_target do
              message_group_id target_attrs.sqs_target[:message_group_id] if target_attrs.sqs_target[:message_group_id]
            end
          end
          
          if target_attrs.http_target
            http_target do
              endpoint target_attrs.http_target[:endpoint] if target_attrs.http_target[:endpoint]
              header_parameters target_attrs.http_target[:header_parameters] if target_attrs.http_target[:header_parameters]
              query_string_parameters target_attrs.http_target[:query_string_parameters] if target_attrs.http_target[:query_string_parameters]
              path_parameter_values target_attrs.http_target[:path_parameter_values] if target_attrs.http_target[:path_parameter_values]
            end
          end
          
          # Run command targets
          if target_attrs.run_command_targets.any?
            target_attrs.run_command_targets.each do |run_command|
              run_command_targets do
                key run_command[:key]
                values run_command[:values]
              end
            end
          end
          
          # Error handling
          if target_attrs.retry_policy
            retry_policy do
              maximum_retry_attempts target_attrs.retry_policy.maximum_retry_attempts if target_attrs.retry_policy.maximum_retry_attempts
              maximum_event_age_in_seconds target_attrs.retry_policy.maximum_event_age_in_seconds if target_attrs.retry_policy.maximum_event_age_in_seconds
            end
          end
          
          if target_attrs.dead_letter_config
            dead_letter_config do
              arn target_attrs.dead_letter_config.arn
            end
          end
        end
        
        # Return resource reference with available outputs
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