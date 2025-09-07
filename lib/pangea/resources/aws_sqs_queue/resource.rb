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
require 'pangea/resources/aws_sqs_queue/types'
require 'pangea/resource_registry'
require 'json'

module Pangea
  module Resources
    module AWS
      # Create an AWS SQS Queue with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] SQS queue attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_sqs_queue(name, attributes = {})
        # Validate attributes using dry-struct
        queue_attrs = AWS::Types::Types::SQSQueueAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_sqs_queue, name) do
          # Set queue name
          name queue_attrs.name
          
          # Set queue type
          fifo_queue queue_attrs.fifo_queue
          
          # FIFO-specific settings
          if queue_attrs.fifo_queue
            content_based_deduplication queue_attrs.content_based_deduplication
            deduplication_scope queue_attrs.deduplication_scope
            fifo_throughput_limit queue_attrs.fifo_throughput_limit
          end
          
          # Queue configuration
          visibility_timeout_seconds queue_attrs.visibility_timeout_seconds
          message_retention_seconds queue_attrs.message_retention_seconds
          max_message_size queue_attrs.max_message_size
          delay_seconds queue_attrs.delay_seconds
          receive_wait_time_seconds queue_attrs.receive_wait_time_seconds
          
          # Dead letter queue configuration
          if queue_attrs.redrive_policy && queue_attrs.redrive_policy[:deadLetterTargetArn]
            redrive_policy JSON.generate(queue_attrs.redrive_policy)
          end
          
          # Redrive allow policy (for DLQ source queues)
          if queue_attrs.redrive_allow_policy && queue_attrs.redrive_allow_policy.any?
            redrive_allow_policy JSON.generate(queue_attrs.redrive_allow_policy)
          end
          
          # Encryption configuration
          if queue_attrs.kms_master_key_id
            kms_master_key_id queue_attrs.kms_master_key_id
            kms_data_key_reuse_period_seconds queue_attrs.kms_data_key_reuse_period_seconds
          elsif queue_attrs.sqs_managed_sse_enabled
            sqs_managed_sse_enabled queue_attrs.sqs_managed_sse_enabled
          end
          
          # Apply queue policy if provided
          policy queue_attrs.policy if queue_attrs.policy
          
          # Apply tags
          if queue_attrs.tags.any?
            tags queue_attrs.tags
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_sqs_queue',
          name: name,
          resource_attributes: queue_attrs.to_h,
          outputs: {
            id: "${aws_sqs_queue.#{name}.id}",
            arn: "${aws_sqs_queue.#{name}.arn}",
            url: "${aws_sqs_queue.#{name}.url}",
            name: "${aws_sqs_queue.#{name}.name}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:queue_type) { queue_attrs.queue_type }
        ref.define_singleton_method(:is_fifo?) { queue_attrs.is_fifo? }
        ref.define_singleton_method(:is_encrypted?) { queue_attrs.is_encrypted? }
        ref.define_singleton_method(:encryption_type) { queue_attrs.encryption_type }
        ref.define_singleton_method(:has_dlq?) { queue_attrs.has_dlq? }
        ref.define_singleton_method(:long_polling_enabled?) { queue_attrs.long_polling_enabled? }
        ref.define_singleton_method(:is_delay_queue?) { queue_attrs.is_delay_queue? }
        ref.define_singleton_method(:allows_all_sources?) { queue_attrs.allows_all_sources? }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)