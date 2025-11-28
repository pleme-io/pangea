# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_zone/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudZone
      # Create a DNS zone in Hetzner DNS
      def hcloud_zone(name, attributes = {})
        zone_attrs = Hetzner::Types::ZoneAttributes.new(attributes)

        resource(:hcloud_zone, name) do
          name zone_attrs.name
          ttl zone_attrs.ttl
        end

        ResourceReference.new(
          type: 'hcloud_zone',
          name: name,
          resource_attributes: zone_attrs.to_h,
          outputs: {
            id: "${hcloud_zone.#{name}.id}",
            name: "${hcloud_zone.#{name}.name}",
            ttl: "${hcloud_zone.#{name}.ttl}"
          }
        )
      end
    end

    module Hetzner
      include HcloudZone
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
