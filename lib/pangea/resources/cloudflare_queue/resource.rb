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
require 'pangea/resources/cloudflare_queue/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Queue resource module that self-registers
    module CloudflareQueue
      # Create a Cloudflare Queue
      #
      # Queues provide message queuing for asynchronous task processing.
      # Messages are delivered to Workers with configurable retry and
      # concurrency settings.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Queue attributes
      # @option attributes [String] :account_id Cloudflare account ID (required)
      # @option attributes [String] :queue_name Queue name (required)
      # @option attributes [Integer] :max_concurrency Maximum concurrent consumers (1-100)
      # @option attributes [Integer] :max_retries Maximum retry attempts (0-100)
      # @option attributes [Integer] :max_wait_time_ms Maximum wait time before retry in ms
      # @option attributes [Integer] :retry_delay Delay between retries in seconds
      # @option attributes [Integer] :visibility_timeout_ms Message visibility timeout in ms
      # @option attributes [Integer] :message_retention_period Retention period in seconds (60-1209600)
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Create a basic task queue
      #   cloudflare_queue(:tasks, {
      #     account_id: "a" * 32,
      #     queue_name: "background-tasks"
      #   })
      #
      # @example Create queue with concurrency and retry settings
      #   cloudflare_queue(:email_queue, {
      #     account_id: "a" * 32,
      #     queue_name: "email-delivery",
      #     max_concurrency: 20,
      #     max_retries: 5,
      #     retry_delay: 60,
      #     message_retention_period: 86400  # 1 day
      #   })
      #
      # @example Create high-throughput queue
      #   cloudflare_queue(:analytics, {
      #     account_id: "a" * 32,
      #     queue_name: "analytics-events",
      #     max_concurrency: 100,
      #     max_retries: 3,
      #     visibility_timeout_ms: 30000,
      #     message_retention_period: 604800  # 7 days
      #   })
      def cloudflare_queue(name, attributes = {})
        # Validate attributes using dry-struct
        queue_attrs = Cloudflare::Types::QueueAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_queue, name) do
          account_id queue_attrs.account_id
          name queue_attrs.queue_name
          max_concurrency queue_attrs.max_concurrency if queue_attrs.max_concurrency
          max_retries queue_attrs.max_retries if queue_attrs.max_retries
          max_wait_time_ms queue_attrs.max_wait_time_ms if queue_attrs.max_wait_time_ms
          retry_delay queue_attrs.retry_delay if queue_attrs.retry_delay
          visibility_timeout_ms queue_attrs.visibility_timeout_ms if queue_attrs.visibility_timeout_ms
          message_retention_period queue_attrs.message_retention_period if queue_attrs.message_retention_period
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_queue',
          name: name,
          resource_attributes: queue_attrs.to_h,
          outputs: {
            id: "${cloudflare_queue.#{name}.id}",
            queue_id: "${cloudflare_queue.#{name}.id}",
            queue_name: "${cloudflare_queue.#{name}.name}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareQueue
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
