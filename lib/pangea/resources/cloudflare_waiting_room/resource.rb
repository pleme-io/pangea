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
require 'pangea/resources/cloudflare_waiting_room/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Waiting Room resource module that self-registers
    module CloudflareWaitingRoom
      # Create a Cloudflare Waiting Room
      #
      # Manage traffic surges by queueing excess visitors in a customizable
      # waiting room before allowing them to proceed to your application.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Waiting room attributes
      # @option attributes [String] :zone_id Zone ID (required)
      # @option attributes [String] :host Domain for waiting room (required)
      # @option attributes [String] :name Waiting room identifier (required)
      # @option attributes [Integer] :new_users_per_minute Rate limit (200-60,000, required)
      # @option attributes [Integer] :total_active_users Max concurrent users (200-1,000,000, required)
      # @option attributes [String] :path URL path to protect
      # @option attributes [Boolean] :queue_all Queue all traffic
      # @option attributes [String] :queueing_method Queue type (fifo/random/passthrough/reject)
      # @option attributes [String] :description Description
      # @option attributes [Integer] :session_duration Session duration in minutes
      # @option attributes [Boolean] :disable_session_renewal Disable session renewal
      # @option attributes [Boolean] :suspended Suspend waiting room
      # @option attributes [String] :custom_page_html Custom HTML
      # @option attributes [Hash] :cookie_attributes Cookie configuration
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Basic waiting room
      #   cloudflare_waiting_room(:shop, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     host: "shop.example.com",
      #     name: "shop_queue",
      #     new_users_per_minute: 200,
      #     total_active_users: 300
      #   })
      #
      # @example Advanced waiting room with path
      #   cloudflare_waiting_room(:checkout, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     host: "shop.example.com",
      #     path: "/checkout",
      #     name: "checkout_queue",
      #     new_users_per_minute: 500,
      #     total_active_users: 1000,
      #     queueing_method: "fifo",
      #     session_duration: 10
      #   })
      def cloudflare_waiting_room(name, attributes = {})
        # Validate attributes using dry-struct
        wr_attrs = Cloudflare::Types::WaitingRoomAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_waiting_room, name) do
          zone_id wr_attrs.zone_id
          host wr_attrs.host
          name wr_attrs.name
          new_users_per_minute wr_attrs.new_users_per_minute
          total_active_users wr_attrs.total_active_users

          path wr_attrs.path if wr_attrs.path
          queue_all wr_attrs.queue_all if wr_attrs.queue_all
          queueing_method wr_attrs.queueing_method if wr_attrs.queueing_method
          description wr_attrs.description if wr_attrs.description
          session_duration wr_attrs.session_duration if wr_attrs.session_duration
          disable_session_renewal wr_attrs.disable_session_renewal if wr_attrs.disable_session_renewal
          suspended wr_attrs.suspended if wr_attrs.suspended
          custom_page_html wr_attrs.custom_page_html if wr_attrs.custom_page_html
          default_template_language wr_attrs.default_template_language if wr_attrs.default_template_language
          json_response_enabled wr_attrs.json_response_enabled if wr_attrs.json_response_enabled
          queueing_status_code wr_attrs.queueing_status_code if wr_attrs.queueing_status_code

          if wr_attrs.cookie_attributes
            cookie_attributes do
              samesite wr_attrs.cookie_attributes.samesite if wr_attrs.cookie_attributes.samesite
              secure wr_attrs.cookie_attributes.secure if wr_attrs.cookie_attributes.secure
            end
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_waiting_room',
          name: name,
          resource_attributes: wr_attrs.to_h,
          outputs: {
            id: "${cloudflare_waiting_room.#{name}.id}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareWaitingRoom
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
