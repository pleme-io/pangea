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
require 'pangea/resources/aws_config_delivery_channel/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Config Delivery Channel with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Delivery Channel attributes
      # @option attributes [String] :name The name of the delivery channel
      # @option attributes [String] :s3_bucket_name The name of the S3 bucket to deliver configuration snapshots
      # @option attributes [String] :s3_key_prefix The prefix for the S3 bucket
      # @option attributes [String] :s3_kms_key_arn The ARN of the KMS key used to encrypt the S3 bucket
      # @option attributes [String] :sns_topic_arn The ARN of the SNS topic for notifications
      # @option attributes [Hash] :snapshot_delivery_properties Configuration for snapshot delivery
      # @option attributes [Hash] :tags A map of tags to assign to the resource
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Basic delivery channel
      #   delivery_channel = aws_config_delivery_channel(:main_channel, {
      #     name: "main-config-channel",
      #     s3_bucket_name: config_bucket.bucket,
      #     tags: {
      #       Environment: "production",
      #       Purpose: "compliance"
      #     }
      #   })
      #
      # @example Delivery channel with encryption and notifications
      #   delivery_channel = aws_config_delivery_channel(:secure_channel, {
      #     name: "secure-config-channel",
      #     s3_bucket_name: config_bucket.bucket,
      #     s3_key_prefix: "config/",
      #     s3_kms_key_arn: kms_key.arn,
      #     sns_topic_arn: notification_topic.arn,
      #     tags: {
      #       Environment: "production",
      #       Security: "encrypted",
      #       Notifications: "enabled"
      #     }
      #   })
      #
      # @example Delivery channel with custom snapshot frequency
      #   delivery_channel = aws_config_delivery_channel(:frequent_channel, {
      #     name: "frequent-snapshot-channel",
      #     s3_bucket_name: config_bucket.bucket,
      #     s3_key_prefix: "frequent-snapshots/",
      #     snapshot_delivery_properties: {
      #       delivery_frequency: "Three_Hours"
      #     },
      #     tags: {
      #       Environment: "production",
      #       Frequency: "high",
      #       Purpose: "real-time-compliance"
      #     }
      #   })
      def aws_config_delivery_channel(name, attributes = {})
        # Validate attributes using dry-struct
        channel_attrs = Types::Types::ConfigDeliveryChannelAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_config_delivery_channel, name) do
          name channel_attrs.name
          s3_bucket_name channel_attrs.s3_bucket_name
          
          # Optional S3 configuration
          s3_key_prefix channel_attrs.s3_key_prefix if channel_attrs.has_s3_key_prefix?
          s3_kms_key_arn channel_attrs.s3_kms_key_arn if channel_attrs.has_encryption?
          
          # Optional SNS notifications
          sns_topic_arn channel_attrs.sns_topic_arn if channel_attrs.has_sns_notifications?
          
          # Snapshot delivery properties
          if channel_attrs.has_snapshot_delivery_properties?
            snapshot_delivery_properties do
              if channel_attrs.snapshot_delivery_properties[:delivery_frequency]
                delivery_frequency channel_attrs.snapshot_delivery_properties[:delivery_frequency]
              end
            end
          end
          
          # Apply tags if present
          if channel_attrs.tags.any?
            tags do
              channel_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_config_delivery_channel',
          name: name,
          resource_attributes: channel_attrs.to_h,
          outputs: {
            id: "${aws_config_delivery_channel.#{name}.id}",
            name: "${aws_config_delivery_channel.#{name}.name}",
            s3_bucket_name: "${aws_config_delivery_channel.#{name}.s3_bucket_name}",
            s3_key_prefix: "${aws_config_delivery_channel.#{name}.s3_key_prefix}",
            s3_kms_key_arn: "${aws_config_delivery_channel.#{name}.s3_kms_key_arn}",
            sns_topic_arn: "${aws_config_delivery_channel.#{name}.sns_topic_arn}",
            snapshot_delivery_properties: "${aws_config_delivery_channel.#{name}.snapshot_delivery_properties}",
            tags_all: "${aws_config_delivery_channel.#{name}.tags_all}"
          },
          computed_properties: {
            has_s3_key_prefix: channel_attrs.has_s3_key_prefix?,
            has_encryption: channel_attrs.has_encryption?,
            has_sns_notifications: channel_attrs.has_sns_notifications?,
            has_snapshot_delivery_properties: channel_attrs.has_snapshot_delivery_properties?,
            delivery_frequency: channel_attrs.delivery_frequency,
            estimated_monthly_cost_usd: channel_attrs.estimated_monthly_cost_usd
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)