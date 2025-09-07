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
require 'pangea/resources/aws_cloudwatch_log_destination/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudWatch Log Destination with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudWatch Log Destination attributes
      # @option attributes [String] :name The name of the destination
      # @option attributes [String] :role_arn IAM role ARN for the destination
      # @option attributes [String] :target_arn ARN of the target AWS resource
      # @option attributes [Hash] :tags Tags to apply to the destination
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Basic log destination for Kinesis
      #   destination = aws_cloudwatch_log_destination(:central_logs, {
      #     name: "central-log-aggregation",
      #     role_arn: iam_role.arn,
      #     target_arn: kinesis_stream.arn
      #   })
      #
      # @example Cross-account log destination
      #   destination = aws_cloudwatch_log_destination(:cross_account_logs, {
      #     name: "cross-account-log-destination",
      #     role_arn: ref(:aws_iam_role, :log_destination_role, :arn),
      #     target_arn: ref(:aws_kinesis_stream, :central_log_stream, :arn),
      #     tags: {
      #       Purpose: "cross-account-aggregation",
      #       ManagedBy: "platform-team"
      #     }
      #   })
      #
      # @example Multi-region log aggregation
      #   destination = aws_cloudwatch_log_destination(:multi_region_logs, {
      #     name: "multi-region-aggregation-destination",
      #     role_arn: cross_region_role.arn,
      #     target_arn: "arn:aws:kinesis:us-east-1:123456789012:stream/central-logs"
      #   })
      def aws_cloudwatch_log_destination(name, attributes = {})
        # Validate attributes using dry-struct
        destination_attrs = Types::Types::CloudWatchLogDestinationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudwatch_logs_destination, name) do
          name destination_attrs.name
          role_arn destination_attrs.role_arn
          target_arn destination_attrs.target_arn
          
          # Apply tags if present
          if destination_attrs.tags.any?
            tags do
              destination_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudwatch_logs_destination',
          name: name,
          resource_attributes: destination_attrs.to_h,
          outputs: {
            arn: "${aws_cloudwatch_logs_destination.#{name}.arn}",
            name: "${aws_cloudwatch_logs_destination.#{name}.name}",
            role_arn: "${aws_cloudwatch_logs_destination.#{name}.role_arn}",
            target_arn: "${aws_cloudwatch_logs_destination.#{name}.target_arn}"
          },
          computed_properties: {
            cross_account_capable: destination_attrs.cross_account_capable?,
            target_service: destination_attrs.target_service,
            region: destination_attrs.region,
            account_id: destination_attrs.account_id
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)