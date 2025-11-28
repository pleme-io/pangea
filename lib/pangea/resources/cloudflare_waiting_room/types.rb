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
        # Queueing method enum for waiting rooms
        CloudflareWaitingRoomQueueingMethod = Dry::Types['strict.string'].enum(
          'fifo',        # First-in-first-out
          'random',      # Random selection
          'passthrough', # Let all through
          'reject'       # Reject all
        )

        # Cookie SameSite attribute enum
        CloudflareCookieSameSite = Dry::Types['strict.string'].enum(
          'auto',
          'lax',
          'none',
          'strict'
        )

        # Cookie Secure attribute enum
        CloudflareCookieSecure = Dry::Types['strict.string'].enum(
          'auto',
          'always',
          'never'
        )

        # Cookie attributes configuration
        class WaitingRoomCookieAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute samesite
          #   @return [String, nil] Cookie SameSite attribute
          attribute :samesite, CloudflareCookieSameSite.optional.default(nil)

          # @!attribute secure
          #   @return [String, nil] Cookie Secure attribute
          attribute :secure, CloudflareCookieSecure.optional.default(nil)
        end

        # Type-safe attributes for Cloudflare Waiting Room
        #
        # Manage traffic surges by queueing excess visitors in a
        # customizable waiting room before allowing them to proceed.
        #
        # @example Basic waiting room
        #   WaitingRoomAttributes.new(
        #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        #     host: "shop.example.com",
        #     name: "shop_queue",
        #     new_users_per_minute: 200,
        #     total_active_users: 300
        #   )
        class WaitingRoomAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute zone_id
          #   @return [String] The zone ID
          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId

          # @!attribute host
          #   @return [String] The domain for the waiting room
          attribute :host, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute name
          #   @return [String] Unique waiting room name
          attribute :name, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute new_users_per_minute
          #   @return [Integer] Rate limit for new users entering from queue
          attribute :new_users_per_minute, Dry::Types['coercible.integer'].constrained(gteq: 200, lteq: 60_000)

          # @!attribute total_active_users
          #   @return [Integer] Maximum concurrent active users
          attribute :total_active_users, Dry::Types['coercible.integer'].constrained(gteq: 200, lteq: 1_000_000)

          # @!attribute path
          #   @return [String, nil] Path to enable waiting room on
          attribute :path, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute queue_all
          #   @return [Boolean, nil] Queue all traffic
          attribute :queue_all, ::Pangea::Resources::Types::Bool.optional.default(nil)

          # @!attribute queueing_method
          #   @return [String, nil] Queueing method
          attribute :queueing_method, CloudflareWaitingRoomQueueingMethod.optional.default(nil)

          # @!attribute description
          #   @return [String, nil] Description
          attribute :description, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute session_duration
          #   @return [Integer, nil] Session duration in minutes
          attribute :session_duration, Dry::Types['coercible.integer']
            .constrained(gteq: 1, lteq: 43_200)
            .optional
            .default(nil)

          # @!attribute disable_session_renewal
          #   @return [Boolean, nil] Disable session renewal
          attribute :disable_session_renewal, ::Pangea::Resources::Types::Bool.optional.default(nil)

          # @!attribute suspended
          #   @return [Boolean, nil] Suspend waiting room
          attribute :suspended, ::Pangea::Resources::Types::Bool.optional.default(nil)

          # @!attribute custom_page_html
          #   @return [String, nil] Custom HTML for waiting page
          attribute :custom_page_html, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute default_template_language
          #   @return [String, nil] Default language for template
          attribute :default_template_language, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute cookie_attributes
          #   @return [WaitingRoomCookieAttributes, nil] Cookie configuration
          attribute :cookie_attributes, WaitingRoomCookieAttributes.optional.default(nil)

          # @!attribute json_response_enabled
          #   @return [Boolean, nil] Enable JSON responses
          attribute :json_response_enabled, ::Pangea::Resources::Types::Bool.optional.default(nil)

          # @!attribute queueing_status_code
          #   @return [Integer, nil] HTTP status code for queueing
          attribute :queueing_status_code, Dry::Types['coercible.integer']
            .constrained(included_in: [200, 202, 429])
            .optional
            .default(nil)

          # Check if waiting room queues all traffic
          # @return [Boolean] true if queuing all
          def queues_all?
            queue_all == true
          end

          # Check if FIFO queueing
          # @return [Boolean] true if FIFO
          def fifo_queueing?
            queueing_method == 'fifo'
          end

          # Check if random queueing
          # @return [Boolean] true if random
          def random_queueing?
            queueing_method == 'random'
          end
        end
      end
    end
  end
end
