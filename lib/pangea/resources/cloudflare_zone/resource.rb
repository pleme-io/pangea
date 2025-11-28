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
require 'pangea/resources/cloudflare_zone/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Zone resource module that self-registers
    module CloudflareZone
      # Create a Cloudflare Zone with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Zone attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def cloudflare_zone(name, attributes = {})
        # Validate attributes using dry-struct
        zone_attrs = Cloudflare::Types::ZoneAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_zone, name) do
          zone zone_attrs.zone
          account_id zone_attrs.account_id if zone_attrs.account_id
          jump_start zone_attrs.jump_start
          paused zone_attrs.paused
          plan zone_attrs.plan
          type zone_attrs.type
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_zone',
          name: name,
          resource_attributes: zone_attrs.to_h,
          outputs: {
            id: "${cloudflare_zone.#{name}.id}",
            zone_id: "${cloudflare_zone.#{name}.id}",
            status: "${cloudflare_zone.#{name}.status}",
            name_servers: "${cloudflare_zone.#{name}.name_servers}",
            vanity_name_servers: "${cloudflare_zone.#{name}.vanity_name_servers}",
            verification_key: "${cloudflare_zone.#{name}.verification_key}",
            meta: "${cloudflare_zone.#{name}.meta}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareZone
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
