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
require 'pangea/resources/aws_cloudwatch_log_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudWatch Log Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudWatch Log Group attributes
      # @option attributes [String] :name The name of the log group
      # @option attributes [Integer] :retention_in_days How long to keep log events in the log group
      # @option attributes [String] :kms_key_id The ARN of the KMS key to use for encryption
      # @option attributes [String] :log_group_class The log class of the log group
      # @option attributes [Boolean] :skip_destroy Set to true if you do not wish the log group to be deleted at destroy time
      # @option attributes [Hash] :tags A map of tags to assign to the resource
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Basic log group
      #   log_group = aws_cloudwatch_log_group(:app_logs, {
      #     name: "/aws/lambda/my-function",
      #     retention_in_days: 14,
      #     tags: {
      #       Environment: "production",
      #       Application: "web-app"
      #     }
      #   })
      #
      # @example Encrypted log group with Infrequent Access class
      #   log_group = aws_cloudwatch_log_group(:audit_logs, {
      #     name: "/audit/application-logs",
      #     retention_in_days: 365,
      #     kms_key_id: kms_key.arn,
      #     log_group_class: "INFREQUENT_ACCESS",
      #     tags: {
      #       Environment: "production",
      #       Type: "audit",
      #       Compliance: "required"
      #     }
      #   })
      #
      # @example Application log group with custom retention
      #   log_group = aws_cloudwatch_log_group(:api_logs, {
      #     name: "/application/api/access",
      #     retention_in_days: 30,
      #     tags: {
      #       Service: "api",
      #       LogType: "access"
      #     }
      #   })
      def aws_cloudwatch_log_group(name, attributes = {})
        # Validate attributes using dry-struct
        log_group_attrs = AWS::Types::Types::CloudWatchLogGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudwatch_log_group, name) do
          name log_group_attrs.name
          retention_in_days log_group_attrs.retention_in_days if log_group_attrs.retention_in_days
          kms_key_id log_group_attrs.kms_key_id if log_group_attrs.kms_key_id
          log_group_class log_group_attrs.log_group_class if log_group_attrs.log_group_class
          skip_destroy log_group_attrs.skip_destroy
          
          # Apply tags if present
          if log_group_attrs.tags.any?
            tags do
              log_group_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_cloudwatch_log_group',
          name: name,
          resource_attributes: log_group_attrs.to_h,
          outputs: {
            id: "${aws_cloudwatch_log_group.#{name}.id}",
            arn: "${aws_cloudwatch_log_group.#{name}.arn}",
            name: "${aws_cloudwatch_log_group.#{name}.name}",
            retention_in_days: "${aws_cloudwatch_log_group.#{name}.retention_in_days}",
            kms_key_id: "${aws_cloudwatch_log_group.#{name}.kms_key_id}",
            log_group_class: "${aws_cloudwatch_log_group.#{name}.log_group_class}",
            tags_all: "${aws_cloudwatch_log_group.#{name}.tags_all}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:has_retention?) { log_group_attrs.has_retention? }
        ref.define_singleton_method(:has_encryption?) { log_group_attrs.has_encryption? }
        ref.define_singleton_method(:is_infrequent_access?) { log_group_attrs.is_infrequent_access? }
        ref.define_singleton_method(:estimated_monthly_cost_usd) { log_group_attrs.estimated_monthly_cost_usd }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)