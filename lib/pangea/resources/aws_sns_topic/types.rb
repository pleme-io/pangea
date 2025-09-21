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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS SNS Topic resources
        class SNSTopicAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Topic name (optional - AWS will generate if not provided)
        attribute :name, Pangea::Resources::Types::String.optional

        # Display name for the topic
        attribute :display_name, Pangea::Resources::Types::String.optional

        # KMS encryption key
        attribute :kms_master_key_id, Pangea::Resources::Types::String.optional

        # FIFO topic (requires .fifo suffix in name)
        attribute :fifo_topic, Pangea::Resources::Types::Bool.default(false)

        # Content-based deduplication for FIFO topics
        attribute :content_based_deduplication, Pangea::Resources::Types::Bool.default(false)

        # Delivery policy (JSON string)
        attribute :delivery_policy, Pangea::Resources::Types::String.optional

        # SNS topic policy (JSON string)
        attribute :policy, Pangea::Resources::Types::String.optional

        # Message delivery status attributes
        attribute :application_success_feedback_role_arn, Pangea::Resources::Types::String.optional.default(nil)
        attribute :application_success_feedback_sample_rate, Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 100).optional.default(nil)
        attribute :application_failure_feedback_role_arn, Pangea::Resources::Types::String.optional.default(nil)

        attribute :http_success_feedback_role_arn, Pangea::Resources::Types::String.optional.default(nil)
        attribute :http_success_feedback_sample_rate, Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 100).optional.default(nil)
        attribute :http_failure_feedback_role_arn, Pangea::Resources::Types::String.optional.default(nil)

        attribute :lambda_success_feedback_role_arn, Pangea::Resources::Types::String.optional.default(nil)
        attribute :lambda_success_feedback_sample_rate, Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 100).optional.default(nil)
        attribute :lambda_failure_feedback_role_arn, Pangea::Resources::Types::String.optional.default(nil)

        attribute :sqs_success_feedback_role_arn, Pangea::Resources::Types::String.optional.default(nil)
        attribute :sqs_success_feedback_sample_rate, Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 100).optional.default(nil)
        attribute :sqs_failure_feedback_role_arn, Pangea::Resources::Types::String.optional.default(nil)

        attribute :firehose_success_feedback_role_arn, Pangea::Resources::Types::String.optional.default(nil)
        attribute :firehose_success_feedback_sample_rate, Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 100).optional.default(nil)
        attribute :firehose_failure_feedback_role_arn, Pangea::Resources::Types::String.optional.default(nil)

        # Message data protection policy (JSON string)
        attribute :message_data_protection_policy, Pangea::Resources::Types::String.optional

        # Tracing configuration
        attribute :tracing_config, Pangea::Resources::Types::String.constrained(included_in: ['Active', 'PassThrough']).optional

        # Tags
        attribute :tags, Pangea::Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate FIFO topic naming convention
          if attrs.fifo_topic && attrs.name && !attrs.name.end_with?('.fifo')
            raise Dry::Struct::Error, "FIFO topic names must end with '.fifo' suffix"
          end

          # Validate non-FIFO topic naming convention
          if !attrs.fifo_topic && attrs.name && attrs.name.end_with?('.fifo')
            raise Dry::Struct::Error, "Standard topic names cannot end with '.fifo' suffix"
          end

          # Validate FIFO-only attributes
          if !attrs.fifo_topic && attrs.content_based_deduplication
            raise Dry::Struct::Error, "content_based_deduplication is only valid for FIFO topics"
          end

          # Validate delivery policy is valid JSON if provided
          if attrs.delivery_policy
            begin
              JSON.parse(attrs.delivery_policy)
            rescue JSON::ParserError => e
              raise Dry::Struct::Error, "delivery_policy must be valid JSON: #{e.message}"
            end
          end

          # Validate policy is valid JSON if provided
          if attrs.policy
            begin
              JSON.parse(attrs.policy)
            rescue JSON::ParserError => e
              raise Dry::Struct::Error, "policy must be valid JSON: #{e.message}"
            end
          end

          # Validate message data protection policy is valid JSON if provided
          if attrs.message_data_protection_policy
            begin
              JSON.parse(attrs.message_data_protection_policy)
            rescue JSON::ParserError => e
              raise Dry::Struct::Error, "message_data_protection_policy must be valid JSON: #{e.message}"
            end
          end

          # Validate feedback sample rates are provided with role ARNs
          %w[application http lambda sqs firehose].each do |protocol|
            sample_rate_attr = "#{protocol}_success_feedback_sample_rate"
            role_arn_attr = "#{protocol}_success_feedback_role_arn"
            
            if attrs.send(sample_rate_attr) && !attrs.send(role_arn_attr)
              raise Dry::Struct::Error, "#{sample_rate_attr} requires #{role_arn_attr} to be set"
            end
          end

          attrs
        end

        # Helper methods
        def is_fifo?
          fifo_topic
        end

        def is_encrypted?
          kms_master_key_id.present?
        end

        def has_delivery_policy?
          delivery_policy.present?
        end

        def has_access_policy?
          policy.present?
        end

        def has_data_protection?
          message_data_protection_policy.present?
        end

        def has_feedback_enabled?
          application_success_feedback_role_arn.present? ||
          application_failure_feedback_role_arn.present? ||
          http_success_feedback_role_arn.present? ||
          http_failure_feedback_role_arn.present? ||
          lambda_success_feedback_role_arn.present? ||
          lambda_failure_feedback_role_arn.present? ||
          sqs_success_feedback_role_arn.present? ||
          sqs_failure_feedback_role_arn.present? ||
          firehose_success_feedback_role_arn.present? ||
          firehose_failure_feedback_role_arn.present?
        end

        def feedback_protocols
          protocols = []
          protocols << 'application' if application_success_feedback_role_arn || application_failure_feedback_role_arn
          protocols << 'http' if http_success_feedback_role_arn || http_failure_feedback_role_arn
          protocols << 'lambda' if lambda_success_feedback_role_arn || lambda_failure_feedback_role_arn
          protocols << 'sqs' if sqs_success_feedback_role_arn || sqs_failure_feedback_role_arn
          protocols << 'firehose' if firehose_success_feedback_role_arn || firehose_failure_feedback_role_arn
          protocols
        end

        def topic_type
          fifo_topic ? 'FIFO' : 'Standard'
        end

        def tracing_enabled?
          tracing_config == 'Active'
        end
      end
    end
  end
end
end