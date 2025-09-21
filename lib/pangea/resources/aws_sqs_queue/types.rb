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
        # Type-safe attributes for AWS SQS Queue resources
        class SQSQueueAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Queue name (required - must end with .fifo for FIFO queues)
        attribute :name, Pangea::Resources::Types::String

        # Queue type (Standard or FIFO)
        attribute :fifo_queue, Pangea::Resources::Types::Bool.default(false)

        # Content-based deduplication (FIFO queues only)
        attribute :content_based_deduplication, Pangea::Resources::Types::Bool.default(false)

        # Visibility timeout in seconds (0-43200, 12 hours max)
        attribute :visibility_timeout_seconds, Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 43200).default(30)

        # Message retention period in seconds (60s-1209600s / 14 days)
        attribute :message_retention_seconds, Pangea::Resources::Types::Integer.constrained(gteq: 60, lteq: 1209600).default(345600) # 4 days

        # Maximum message size in bytes (1024-262144 / 256KB)
        attribute :max_message_size, Pangea::Resources::Types::Integer.constrained(gteq: 1024, lteq: 262144).default(262144)

        # Delay queue - message delivery delay in seconds (0-900)
        attribute :delay_seconds, Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 900).default(0)

        # Receive message wait time in seconds (0-20) for long polling
        attribute :receive_wait_time_seconds, Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 20).default(0)

        # Dead letter queue configuration
        attribute :redrive_policy, Pangea::Resources::Types::Hash.schema(
          deadLetterTargetArn: Pangea::Resources::Types::String,
          maxReceiveCount: Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 1000).default(3)
        ).optional.default(nil)

        # Allow messages from source queues (for dead letter queue)
        attribute :redrive_allow_policy, Pangea::Resources::Types::Hash.schema(
          redrivePermission: Pangea::Resources::Types::String.default('allowAll').constrained(included_in: ['allowAll', 'denyAll', 'byQueue']),
          sourceQueueArns?: Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional
        ).optional.default(nil)

        # KMS encryption configuration
        attribute :kms_master_key_id, Pangea::Resources::Types::String.optional.default(nil)

        # KMS data key reuse period in seconds (60-86400)
        attribute :kms_data_key_reuse_period_seconds, Pangea::Resources::Types::Integer.constrained(gteq: 60, lteq: 86400).default(300)

        # Server-side encryption using SQS service key
        attribute :sqs_managed_sse_enabled, Pangea::Resources::Types::Bool.default(false)

        # Deduplication scope (FIFO only) - messageGroup or queue
        attribute :deduplication_scope, Pangea::Resources::Types::String.default('queue').constrained(included_in: ['messageGroup', 'queue'])

        # FIFO throughput limit (FIFO only) - perMessageGroupId or perQueue
        attribute :fifo_throughput_limit, Pangea::Resources::Types::String.default('perQueue').constrained(included_in: ['perMessageGroupId', 'perQueue'])

        # Queue policy (as JSON string)
        attribute? :policy, Pangea::Resources::Types::String.optional

        # Tags
        attribute :tags, Pangea::Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate FIFO queue naming convention
          if attrs.fifo_queue && !attrs.name.end_with?('.fifo')
            raise Dry::Struct::Error, "FIFO queue names must end with '.fifo' suffix"
          end

          # Validate non-FIFO queue naming convention
          if !attrs.fifo_queue && attrs.name.end_with?('.fifo')
            raise Dry::Struct::Error, "Standard queue names cannot end with '.fifo' suffix"
          end

          # Validate FIFO-only attributes
          if !attrs.fifo_queue
            if attrs.content_based_deduplication
              raise Dry::Struct::Error, "content_based_deduplication is only valid for FIFO queues"
            end
            if attrs.deduplication_scope != 'queue'
              raise Dry::Struct::Error, "deduplication_scope is only valid for FIFO queues"
            end
            if attrs.fifo_throughput_limit != 'perQueue'
              raise Dry::Struct::Error, "fifo_throughput_limit is only valid for FIFO queues"
            end
          end

          # Validate redrive allow policy
          if attrs.redrive_allow_policy && 
             attrs.redrive_allow_policy[:redrivePermission] == 'byQueue' && 
             (attrs.redrive_allow_policy[:sourceQueueArns].nil? || attrs.redrive_allow_policy[:sourceQueueArns].empty?)
            raise Dry::Struct::Error, "sourceQueueArns must be specified when redrivePermission is 'byQueue'"
          end

          # Validate encryption settings (can't have both KMS and SQS managed)
          if attrs.kms_master_key_id && attrs.sqs_managed_sse_enabled
            raise Dry::Struct::Error, "Cannot enable both KMS encryption and SQS managed server-side encryption"
          end

          attrs
        end

        # Helper methods
        def is_fifo?
          fifo_queue
        end

        def is_encrypted?
          kms_master_key_id.present? || sqs_managed_sse_enabled
        end

        def has_dlq?
          redrive_policy && redrive_policy[:deadLetterTargetArn].present?
        end

        def long_polling_enabled?
          receive_wait_time_seconds > 0
        end

        def is_delay_queue?
          delay_seconds > 0
        end

        def allows_all_sources?
          redrive_allow_policy.nil? || redrive_allow_policy[:redrivePermission] == 'allowAll'
        end

        def queue_type
          fifo_queue ? 'FIFO' : 'Standard'
        end

        def encryption_type
          if kms_master_key_id
            'KMS'
          elsif sqs_managed_sse_enabled
            'SQS-SSE'
          else
            'None'
          end
        end
        end
      end
    end
  end
end