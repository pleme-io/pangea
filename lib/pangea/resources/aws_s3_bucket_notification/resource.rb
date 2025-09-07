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
require 'pangea/resources/aws_s3_bucket_notification/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS S3 Bucket Notification Configuration with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] S3 bucket notification attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_s3_bucket_notification(name, attributes = {})
        # Validate attributes using dry-struct
        notification_attrs = Types::S3BucketNotificationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_s3_bucket_notification, name) do
          # Set the bucket
          bucket notification_attrs.bucket
          
          # Configure EventBridge notifications
          if notification_attrs.eventbridge
            eventbridge true
          end
          
          # Configure CloudWatch/SNS topic notifications
          notification_attrs.cloudwatch_configuration.each_with_index do |config, index|
            cloudwatch_configuration do
              id config[:id] || "cloudwatch-config-#{index}"
              topic_arn config[:topic_arn]
              events config[:events]
              
              if config[:filter_prefix] || config[:filter_suffix]
                filter do
                  prefix config[:filter_prefix] if config[:filter_prefix]
                  suffix config[:filter_suffix] if config[:filter_suffix]
                end
              end
            end
          end
          
          # Configure Lambda function notifications
          notification_attrs.lambda_function.each_with_index do |config, index|
            lambda_function do
              id config[:id] || "lambda-config-#{index}"
              lambda_function_arn config[:lambda_function_arn]
              events config[:events]
              
              if config[:filter_prefix] || config[:filter_suffix]
                filter do
                  prefix config[:filter_prefix] if config[:filter_prefix]
                  suffix config[:filter_suffix] if config[:filter_suffix]
                end
              end
            end
          end
          
          # Configure SQS queue notifications
          notification_attrs.queue.each_with_index do |config, index|
            queue do
              id config[:id] || "queue-config-#{index}"
              queue_arn config[:queue_arn]
              events config[:events]
              
              if config[:filter_prefix] || config[:filter_suffix]
                filter do
                  prefix config[:filter_prefix] if config[:filter_prefix]
                  suffix config[:filter_suffix] if config[:filter_suffix]
                end
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_s3_bucket_notification',
          name: name,
          resource_attributes: notification_attrs.to_h,
          outputs: {
            id: "${aws_s3_bucket_notification.#{name}.id}",
            bucket: "${aws_s3_bucket_notification.#{name}.bucket}"
          },
          computed: {
            total_notification_destinations: notification_attrs.total_notification_destinations,
            has_lambda_notifications: notification_attrs.has_lambda_notifications?,
            has_sqs_notifications: notification_attrs.has_sqs_notifications?,
            has_sns_notifications: notification_attrs.has_sns_notifications?,
            has_eventbridge_enabled: notification_attrs.has_eventbridge_enabled?,
            all_configured_events: notification_attrs.all_configured_events,
            uses_wildcard_events: notification_attrs.uses_wildcard_events?,
            monitors_object_creation: notification_attrs.monitors_object_creation?,
            monitors_object_removal: notification_attrs.monitors_object_removal?,
            monitors_object_restore: notification_attrs.monitors_object_restore?,
            monitors_replication: notification_attrs.monitors_replication?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)