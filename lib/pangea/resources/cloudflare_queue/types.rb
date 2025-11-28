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
    module Cloudflare
      module Types
        # Type-safe attributes for Cloudflare Queue
        #
        # Queues provide message queuing for asynchronous processing.
        # Messages are delivered to Workers with configurable retry and
        # concurrency settings.
        #
        # @example Create a task queue
        #   QueueAttributes.new(
        #     account_id: "a" * 32,
        #     queue_name: "email-tasks",
        #     max_concurrency: 10,
        #     max_retries: 3
        #   )
        class QueueAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute account_id
          #   @return [String] The Cloudflare account ID
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId

          # @!attribute queue_name
          #   @return [String] Queue name (unique identifier)
          attribute :queue_name, Dry::Types['strict.string'].constrained(
            min_size: 1,
            max_size: 256
          )

          # @!attribute max_concurrency
          #   @return [Integer, nil] Maximum concurrent consumers (1-100)
          attribute :max_concurrency, Dry::Types['coercible.integer']
            .constrained(gteq: 1, lteq: 100)
            .optional
            .default(nil)

          # @!attribute max_retries
          #   @return [Integer, nil] Maximum retry attempts (0-100)
          attribute :max_retries, Dry::Types['coercible.integer']
            .constrained(gteq: 0, lteq: 100)
            .optional
            .default(nil)

          # @!attribute max_wait_time_ms
          #   @return [Integer, nil] Maximum wait time before retry in milliseconds
          attribute :max_wait_time_ms, Dry::Types['coercible.integer']
            .constrained(gteq: 0)
            .optional
            .default(nil)

          # @!attribute retry_delay
          #   @return [Integer, nil] Delay between retries in seconds
          attribute :retry_delay, Dry::Types['coercible.integer']
            .constrained(gteq: 0)
            .optional
            .default(nil)

          # @!attribute visibility_timeout_ms
          #   @return [Integer, nil] Message visibility timeout in milliseconds
          attribute :visibility_timeout_ms, Dry::Types['coercible.integer']
            .constrained(gteq: 0)
            .optional
            .default(nil)

          # @!attribute message_retention_period
          #   @return [Integer, nil] Message retention period in seconds (60-1209600)
          attribute :message_retention_period, Dry::Types['coercible.integer']
            .constrained(gteq: 60, lteq: 1209600)  # 1 min to 14 days
            .optional
            .default(nil)

          # Check if queue has high concurrency configured
          # @return [Boolean] true if max_concurrency >= 10
          def high_concurrency?
            max_concurrency && max_concurrency >= 10
          end

          # Check if queue has retry configured
          # @return [Boolean] true if max_retries > 0
          def retries_enabled?
            max_retries && max_retries > 0
          end

          # Get retention period in days
          # @return [Float, nil] Retention period in days
          def retention_days
            return nil unless message_retention_period
            message_retention_period / 86400.0
          end

          # Extract environment from queue name if present
          # @return [String, nil] Environment name if detected
          def environment
            case queue_name.downcase
            when /production|prod/
              'production'
            when /staging|stage/
              'staging'
            when /development|dev/
              'development'
            when /test/
              'test'
            else
              nil
            end
          end
        end
      end
    end
  end
end
