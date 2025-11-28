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
require 'pangea/resources/cloudflare_waiting_room_event/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Waiting Room Event resource module that self-registers
    module CloudflareWaitingRoomEvent
      # Create a Cloudflare Waiting Room Event
      #
      # Events temporarily change waiting room behavior during specified time periods.
      # Only one event can be active at a time (events cannot overlap).
      #
      # Available only for Waiting Room Advanced subscription.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Event attributes
      # @option attributes [String] :zone_id Zone ID (required)
      # @option attributes [String] :waiting_room_id Waiting room ID (required)
      # @option attributes [String] :name Event identifier (required)
      # @option attributes [String] :event_start_time ISO 8601 start time (required)
      # @option attributes [String] :event_end_time ISO 8601 end time (required)
      # @option attributes [String] :description Event description
      # @option attributes [String] :prequeue_start_time ISO 8601 prequeue start
      # @option attributes [Integer] :new_users_per_minute Override rate limit
      # @option attributes [Integer] :total_active_users Override max users
      # @option attributes [String] :queueing_method Override queue method
      # @option attributes [Integer] :session_duration Override session minutes
      # @option attributes [Boolean] :disable_session_renewal Override renewal
      # @option attributes [Boolean] :shuffle_at_event_start Shuffle prequeue
      # @option attributes [Boolean] :suspended Suspend event
      # @option attributes [String] :custom_page_html Custom HTML
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Flash sale event
      #   cloudflare_waiting_room_event(:flash_sale, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     waiting_room_id: "699d98642c564d2e855e9661899b7252",
      #     name: "flash_sale_event",
      #     event_start_time: "2025-11-15T12:00:00Z",
      #     event_end_time: "2025-11-15T14:00:00Z",
      #     new_users_per_minute: 1000,
      #     total_active_users: 5000
      #   })
      #
      # @example Event with prequeue
      #   cloudflare_waiting_room_event(:webinar, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     waiting_room_id: "699d98642c564d2e855e9661899b7252",
      #     name: "webinar_event",
      #     event_start_time: "2025-11-20T14:00:00Z",
      #     event_end_time: "2025-11-20T16:00:00Z",
      #     prequeue_start_time: "2025-11-20T13:30:00Z",
      #     shuffle_at_event_start: true
      #   })
      def cloudflare_waiting_room_event(name, attributes = {})
        # Validate attributes using dry-struct
        event_attrs = Cloudflare::Types::WaitingRoomEventAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_waiting_room_event, name) do
          zone_id event_attrs.zone_id
          waiting_room_id event_attrs.waiting_room_id
          name event_attrs.name
          event_start_time event_attrs.event_start_time
          event_end_time event_attrs.event_end_time

          description event_attrs.description if event_attrs.description
          prequeue_start_time event_attrs.prequeue_start_time if event_attrs.prequeue_start_time
          new_users_per_minute event_attrs.new_users_per_minute if event_attrs.new_users_per_minute
          total_active_users event_attrs.total_active_users if event_attrs.total_active_users
          queueing_method event_attrs.queueing_method if event_attrs.queueing_method
          session_duration event_attrs.session_duration if event_attrs.session_duration
          disable_session_renewal event_attrs.disable_session_renewal if event_attrs.disable_session_renewal
          shuffle_at_event_start event_attrs.shuffle_at_event_start if event_attrs.shuffle_at_event_start
          suspended event_attrs.suspended if event_attrs.suspended
          custom_page_html event_attrs.custom_page_html if event_attrs.custom_page_html
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_waiting_room_event',
          name: name,
          resource_attributes: event_attrs.to_h,
          outputs: {
            id: "${cloudflare_waiting_room_event.#{name}.id}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareWaitingRoomEvent
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
