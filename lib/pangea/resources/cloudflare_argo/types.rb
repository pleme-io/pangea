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
        # Argo feature toggle enum
        CloudflareArgoToggle = Dry::Types['strict.string'].enum(
          'on',
          'off'
        )

        # Type-safe attributes for Cloudflare Argo
        #
        # Enables Argo Smart Routing and Tiered Caching for a zone.
        # Smart Routing optimizes traffic routing, Tiered Caching improves cache efficiency.
        #
        # NOTE: tiered_caching is deprecated in favor of cloudflare_tiered_cache resource.
        #
        # @example Enable Smart Routing
        #   ArgoAttributes.new(
        #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        #     smart_routing: "on"
        #   )
        #
        # @example Enable both features
        #   ArgoAttributes.new(
        #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        #     smart_routing: "on",
        #     tiered_caching: "on"
        #   )
        class ArgoAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute zone_id
          #   @return [String] The zone ID
          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId

          # @!attribute smart_routing
          #   @return [String, nil] Enable Argo Smart Routing ("on" or "off")
          attribute :smart_routing, CloudflareArgoToggle.optional.default(nil)

          # @!attribute tiered_caching
          #   @return [String, nil] Enable Argo Tiered Caching ("on" or "off")
          #   @deprecated Use cloudflare_tiered_cache resource instead
          attribute :tiered_caching, CloudflareArgoToggle.optional.default(nil)

          # Check if Smart Routing is enabled
          # @return [Boolean] true if enabled
          def smart_routing_enabled?
            smart_routing == 'on'
          end

          # Check if Tiered Caching is enabled
          # @return [Boolean] true if enabled
          def tiered_caching_enabled?
            tiered_caching == 'on'
          end

          # Check if any Argo feature is enabled
          # @return [Boolean] true if any feature enabled
          def any_enabled?
            smart_routing_enabled? || tiered_caching_enabled?
          end

          # Check if all Argo features are enabled
          # @return [Boolean] true if all features enabled
          def all_enabled?
            smart_routing_enabled? && tiered_caching_enabled?
          end
        end
      end
    end
  end
end
