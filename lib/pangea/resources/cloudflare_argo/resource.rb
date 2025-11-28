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
require 'pangea/resources/cloudflare_argo/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Argo resource module that self-registers
    module CloudflareArgo
      # Configure Cloudflare Argo features for a zone
      #
      # Enables Argo Smart Routing (optimized traffic routing) and
      # Argo Tiered Caching (improved cache efficiency).
      #
      # NOTE: tiered_caching is deprecated. Use cloudflare_tiered_cache resource instead.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Argo configuration attributes
      # @option attributes [String] :zone_id Zone ID (required)
      # @option attributes [String] :smart_routing Enable Smart Routing ("on" or "off")
      # @option attributes [String] :tiered_caching Enable Tiered Caching ("on" or "off", deprecated)
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Enable Smart Routing only
      #   cloudflare_argo(:smart_routing, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     smart_routing: "on"
      #   })
      #
      # @example Enable both features
      #   cloudflare_argo(:argo_all, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     smart_routing: "on",
      #     tiered_caching: "on"
      #   })
      #
      # @example Disable all Argo features
      #   cloudflare_argo(:argo_disabled, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     smart_routing: "off",
      #     tiered_caching: "off"
      #   })
      def cloudflare_argo(name, attributes = {})
        # Validate attributes using dry-struct
        argo_attrs = Cloudflare::Types::ArgoAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_argo, name) do
          zone_id argo_attrs.zone_id
          smart_routing argo_attrs.smart_routing if argo_attrs.smart_routing
          tiered_caching argo_attrs.tiered_caching if argo_attrs.tiered_caching
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_argo',
          name: name,
          resource_attributes: argo_attrs.to_h,
          outputs: {
            id: "${cloudflare_argo.#{name}.id}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareArgo
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
