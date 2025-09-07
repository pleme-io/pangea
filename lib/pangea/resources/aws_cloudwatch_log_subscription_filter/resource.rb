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
require 'pangea/resources/aws_cloudwatch_log_subscription_filter/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudWatch Log Subscription Filter with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudWatch Log Subscription Filter attributes
      # @option attributes [String] :name The name of the subscription filter
      # @option attributes [String] :log_group_name The log group to read from
      # @option attributes [String] :destination_arn ARN of the destination
      # @option attributes [String] :filter_pattern The filter pattern (empty for all logs)
      # @option attributes [String] :role_arn IAM role for the subscription
      # @option attributes [String] :distribution Log distribution method
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Stream all logs to Kinesis
      #   subscription = aws_cloudwatch_log_subscription_filter(:all_logs, {
      #     name: "stream-all-logs",
      #     log_group_name: app_log_group.name,
      #     destination_arn: kinesis_stream.arn,
      #     role_arn: kinesis_role.arn
      #   })
      #
      # @example Filter and stream errors to Lambda
      #   error_subscription = aws_cloudwatch_log_subscription_filter(:error_processor, {
      #     name: "process-errors",
      #     log_group_name: "/aws/lambda/my-function",
      #     destination_arn: error_processor_lambda.arn,
      #     filter_pattern: "[time, level=ERROR, ...]",
      #     role_arn: lambda_invoke_role.arn
      #   })
      #
      # @example Cross-account log streaming
      #   cross_account = aws_cloudwatch_log_subscription_filter(:cross_account, {
      #     name: "cross-account-logs",
      #     log_group_name: production_logs.name,
      #     destination_arn: ref(:aws_cloudwatch_log_destination, :central_logs, :arn),
      #     filter_pattern: '{ $.environment = "production" }',
      #     distribution: "ByLogStream"
      #   })
      def aws_cloudwatch_log_subscription_filter(name, attributes = {})
        # Validate attributes using dry-struct
        filter_attrs = Types::Types::CloudWatchLogSubscriptionFilterAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudwatch_log_subscription_filter, name) do
          name filter_attrs.name
          log_group_name filter_attrs.log_group_name
          destination_arn filter_attrs.destination_arn
          filter_pattern filter_attrs.filter_pattern
          distribution filter_attrs.distribution
          
          # Role ARN is required for some destinations
          role_arn filter_attrs.role_arn if filter_attrs.role_arn
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudwatch_log_subscription_filter',
          name: name,
          resource_attributes: filter_attrs.to_h,
          outputs: {
            id: "${aws_cloudwatch_log_subscription_filter.#{name}.id}",
            name: "${aws_cloudwatch_log_subscription_filter.#{name}.name}",
            log_group_name: "${aws_cloudwatch_log_subscription_filter.#{name}.log_group_name}",
            destination_arn: "${aws_cloudwatch_log_subscription_filter.#{name}.destination_arn}",
            filter_pattern: "${aws_cloudwatch_log_subscription_filter.#{name}.filter_pattern}",
            role_arn: "${aws_cloudwatch_log_subscription_filter.#{name}.role_arn}",
            distribution: "${aws_cloudwatch_log_subscription_filter.#{name}.distribution}"
          },
          computed_properties: {
            destination_service: filter_attrs.destination_service,
            is_cross_account: filter_attrs.is_cross_account?,
            requires_role: filter_attrs.requires_role?,
            has_filter_pattern: filter_attrs.has_filter_pattern?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)