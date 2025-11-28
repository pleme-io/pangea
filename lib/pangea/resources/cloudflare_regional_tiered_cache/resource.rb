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
require 'pangea/resources/cloudflare_regional_tiered_cache/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Regional Tiered Cache resource module that self-registers
    module CloudflareRegionalTieredCache
      # Configure Regional Tiered Cache for a zone
      #
      # Regional Tiered Cache instructs Cloudflare to check a regional hub
      # data center before checking origin, reducing latency and improving
      # cache hit ratios in smart and custom tiered cache topologies.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Regional tiered cache configuration attributes
      # @option attributes [String] :zone_id Zone ID (required)
      # @option attributes [String] :value Enable or disable ("on" or "off", required)
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Enable Regional Tiered Cache
      #   cloudflare_regional_tiered_cache(:regional_cache, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     value: "on"
      #   })
      #
      # @example Disable Regional Tiered Cache
      #   cloudflare_regional_tiered_cache(:regional_cache_off, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     value: "off"
      #   })
      def cloudflare_regional_tiered_cache(name, attributes = {})
        # Validate attributes using dry-struct
        cache_attrs = Cloudflare::Types::RegionalTieredCacheAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_regional_tiered_cache, name) do
          zone_id cache_attrs.zone_id
          value cache_attrs.value
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_regional_tiered_cache',
          name: name,
          resource_attributes: cache_attrs.to_h,
          outputs: {
            id: "${cloudflare_regional_tiered_cache.#{name}.id}",
            editable: "${cloudflare_regional_tiered_cache.#{name}.editable}",
            modified_on: "${cloudflare_regional_tiered_cache.#{name}.modified_on}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareRegionalTieredCache
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
