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
require 'pangea/resources/aws_sns_topic/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS SNS Topic with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] SNS topic attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_sns_topic(name, attributes = {})
        # Validate attributes using dry-struct
        topic_attrs = AWS::Types::Types::SNSTopicAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_sns_topic, name) do
          # Set topic name if provided
          name topic_attrs.name if topic_attrs.name
          
          # Set display name if provided
          display_name topic_attrs.display_name if topic_attrs.display_name
          
          # Set FIFO topic configuration
          fifo_topic topic_attrs.fifo_topic
          if topic_attrs.fifo_topic
            content_based_deduplication topic_attrs.content_based_deduplication
          end
          
          # Set KMS encryption if provided
          kms_master_key_id topic_attrs.kms_master_key_id if topic_attrs.kms_master_key_id
          
          # Set delivery policy if provided
          delivery_policy topic_attrs.delivery_policy if topic_attrs.delivery_policy
          
          # Set topic policy if provided
          policy topic_attrs.policy if topic_attrs.policy
          
          # Set message data protection policy if provided
          message_data_protection_policy topic_attrs.message_data_protection_policy if topic_attrs.message_data_protection_policy
          
          # Set tracing configuration if provided
          tracing_config topic_attrs.tracing_config if topic_attrs.tracing_config
          
          # Set application feedback attributes
          application_success_feedback_role_arn topic_attrs.application_success_feedback_role_arn if topic_attrs.application_success_feedback_role_arn
          application_success_feedback_sample_rate topic_attrs.application_success_feedback_sample_rate if topic_attrs.application_success_feedback_sample_rate
          application_failure_feedback_role_arn topic_attrs.application_failure_feedback_role_arn if topic_attrs.application_failure_feedback_role_arn
          
          # Set HTTP feedback attributes
          http_success_feedback_role_arn topic_attrs.http_success_feedback_role_arn if topic_attrs.http_success_feedback_role_arn
          http_success_feedback_sample_rate topic_attrs.http_success_feedback_sample_rate if topic_attrs.http_success_feedback_sample_rate
          http_failure_feedback_role_arn topic_attrs.http_failure_feedback_role_arn if topic_attrs.http_failure_feedback_role_arn
          
          # Set Lambda feedback attributes
          lambda_success_feedback_role_arn topic_attrs.lambda_success_feedback_role_arn if topic_attrs.lambda_success_feedback_role_arn
          lambda_success_feedback_sample_rate topic_attrs.lambda_success_feedback_sample_rate if topic_attrs.lambda_success_feedback_sample_rate
          lambda_failure_feedback_role_arn topic_attrs.lambda_failure_feedback_role_arn if topic_attrs.lambda_failure_feedback_role_arn
          
          # Set SQS feedback attributes
          sqs_success_feedback_role_arn topic_attrs.sqs_success_feedback_role_arn if topic_attrs.sqs_success_feedback_role_arn
          sqs_success_feedback_sample_rate topic_attrs.sqs_success_feedback_sample_rate if topic_attrs.sqs_success_feedback_sample_rate
          sqs_failure_feedback_role_arn topic_attrs.sqs_failure_feedback_role_arn if topic_attrs.sqs_failure_feedback_role_arn
          
          # Set Firehose feedback attributes
          firehose_success_feedback_role_arn topic_attrs.firehose_success_feedback_role_arn if topic_attrs.firehose_success_feedback_role_arn
          firehose_success_feedback_sample_rate topic_attrs.firehose_success_feedback_sample_rate if topic_attrs.firehose_success_feedback_sample_rate
          firehose_failure_feedback_role_arn topic_attrs.firehose_failure_feedback_role_arn if topic_attrs.firehose_failure_feedback_role_arn
          
          # Apply tags
          if topic_attrs.tags.any?
            tags topic_attrs.tags
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_sns_topic',
          name: name,
          resource_attributes: topic_attrs.to_h,
          outputs: {
            id: "${aws_sns_topic.#{name}.id}",
            arn: "${aws_sns_topic.#{name}.arn}",
            name: "${aws_sns_topic.#{name}.name}",
            owner: "${aws_sns_topic.#{name}.owner}",
            beginning_archive_time: "${aws_sns_topic.#{name}.beginning_archive_time}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:topic_type) { topic_attrs.topic_type }
        ref.define_singleton_method(:is_fifo?) { topic_attrs.is_fifo? }
        ref.define_singleton_method(:is_encrypted?) { topic_attrs.is_encrypted? }
        ref.define_singleton_method(:has_delivery_policy?) { topic_attrs.has_delivery_policy? }
        ref.define_singleton_method(:has_access_policy?) { topic_attrs.has_access_policy? }
        ref.define_singleton_method(:has_data_protection?) { topic_attrs.has_data_protection? }
        ref.define_singleton_method(:has_feedback_enabled?) { topic_attrs.has_feedback_enabled? }
        ref.define_singleton_method(:feedback_protocols) { topic_attrs.feedback_protocols }
        ref.define_singleton_method(:tracing_enabled?) { topic_attrs.tracing_enabled? }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)