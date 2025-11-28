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
require 'pangea/resources/cloudflare_waiting_room/types'

module Pangea
  module Resources
    module Cloudflare
      module Types
        # Type-safe attributes for Cloudflare Waiting Room Event
        #
        # Events temporarily change waiting room behavior during specified time periods.
        # Only one event can be active at a time (events cannot overlap).
        #
        # Available only for Waiting Room Advanced subscription.
        #
        # @example Flash sale event
        #   WaitingRoomEventAttributes.new(
        #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        #     waiting_room_id: "699d98642c564d2e855e9661899b7252",
        #     name: "flash_sale_event",
        #     event_start_time: "2025-11-15T12:00:00Z",
        #     event_end_time: "2025-11-15T14:00:00Z",
        #     new_users_per_minute: 1000
        #   )
        class WaitingRoomEventAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute zone_id
          #   @return [String] The zone ID
          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId

          # @!attribute waiting_room_id
          #   @return [String] The waiting room ID
          attribute :waiting_room_id, Dry::Types['strict.string'].constrained(
            format: /\A[a-f0-9]{32}\z/
          )

          # @!attribute name
          #   @return [String] Event identifier
          attribute :name, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute event_start_time
          #   @return [String] ISO 8601 timestamp for event start
          attribute :event_start_time, Dry::Types['strict.string'].constrained(
            format: /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/
          )

          # @!attribute event_end_time
          #   @return [String] ISO 8601 timestamp for event end
          attribute :event_end_time, Dry::Types['strict.string'].constrained(
            format: /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/
          )

          # @!attribute description
          #   @return [String, nil] Event description
          attribute :description, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute prequeue_start_time
          #   @return [String, nil] ISO 8601 timestamp when prequeue begins
          attribute :prequeue_start_time, Dry::Types['strict.string']
            .constrained(format: /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/)
            .optional
            .default(nil)

          # @!attribute new_users_per_minute
          #   @return [Integer, nil] Override rate limit for event
          attribute :new_users_per_minute, Dry::Types['coercible.integer']
            .constrained(gteq: 200, lteq: 60_000)
            .optional
            .default(nil)

          # @!attribute total_active_users
          #   @return [Integer, nil] Override max concurrent users for event
          attribute :total_active_users, Dry::Types['coercible.integer']
            .constrained(gteq: 200, lteq: 1_000_000)
            .optional
            .default(nil)

          # @!attribute queueing_method
          #   @return [String, nil] Override queueing method for event
          attribute :queueing_method, CloudflareWaitingRoomQueueingMethod.optional.default(nil)

          # @!attribute session_duration
          #   @return [Integer, nil] Override session duration in minutes
          attribute :session_duration, Dry::Types['coercible.integer']
            .constrained(gteq: 1, lteq: 43_200)
            .optional
            .default(nil)

          # @!attribute disable_session_renewal
          #   @return [Boolean, nil] Override session renewal setting
          attribute :disable_session_renewal, ::Pangea::Resources::Types::Bool.optional.default(nil)

          # @!attribute shuffle_at_event_start
          #   @return [Boolean, nil] Shuffle prequeued users at event start
          attribute :shuffle_at_event_start, ::Pangea::Resources::Types::Bool.optional.default(nil)

          # @!attribute suspended
          #   @return [Boolean, nil] Suspend the event
          attribute :suspended, ::Pangea::Resources::Types::Bool.optional.default(nil)

          # @!attribute custom_page_html
          #   @return [String, nil] Custom HTML for event waiting page
          attribute :custom_page_html, Dry::Types['strict.string'].optional.default(nil)

          # Validate event times
          def self.new(attributes)
            attrs = attributes.transform_keys(&:to_sym)
            super(attrs).tap do |instance|
              # Ensure event_end_time is after event_start_time
              if instance.event_end_time <= instance.event_start_time
                raise Dry::Struct::Error, "event_end_time must be after event_start_time"
              end

              # Ensure prequeue_start_time is before event_start_time if specified
              if instance.prequeue_start_time && instance.prequeue_start_time >= instance.event_start_time
                raise Dry::Struct::Error, "prequeue_start_time must be before event_start_time"
              end
            end
          end

          # Check if event has prequeue
          # @return [Boolean] true if prequeue is configured
          def has_prequeue?
            !prequeue_start_time.nil?
          end

          # Check if event shuffles prequeue
          # @return [Boolean] true if shuffle enabled
          def shuffles_prequeue?
            shuffle_at_event_start == true
          end
        end
      end
    end
  end
end
