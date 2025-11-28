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
        # Tiered cache toggle enum
        CloudflareTieredCacheValue = Dry::Types['strict.string'].enum(
          'on',
          'off'
        )

        # Type-safe attributes for Cloudflare Tiered Cache
        #
        # Smart Tiered Cache topology configuration for improved cache hit ratios.
        # Uses Cloudflare's network topology to serve cached content from optimal locations.
        #
        # Replaces deprecated tiered_caching attribute in cloudflare_argo resource.
        #
        # @example Enable Smart Tiered Cache
        #   TieredCacheAttributes.new(
        #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        #     value: "on"
        #   )
        #
        # @example Disable Smart Tiered Cache
        #   TieredCacheAttributes.new(
        #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        #     value: "off"
        #   )
        class TieredCacheAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute zone_id
          #   @return [String] The zone ID
          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId

          # @!attribute value
          #   @return [String] Enable or disable Smart Tiered Cache ("on" or "off")
          attribute :value, CloudflareTieredCacheValue

          # Check if Tiered Cache is enabled
          # @return [Boolean] true if enabled
          def enabled?
            value == 'on'
          end

          # Check if Tiered Cache is disabled
          # @return [Boolean] true if disabled
          def disabled?
            value == 'off'
          end
        end
      end
    end
  end
end
