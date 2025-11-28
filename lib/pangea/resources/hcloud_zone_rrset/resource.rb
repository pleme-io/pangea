# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_zone_rrset/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudZoneRrset
      # Create a DNS record set in a Hetzner DNS zone
      def hcloud_zone_rrset(name, attributes = {})
        rrset_attrs = Hetzner::Types::ZoneRrsetAttributes.new(attributes)

        resource(:hcloud_zone_rrset, name) do
          zone_id rrset_attrs.zone_id
          name rrset_attrs.name
          type rrset_attrs.type
          values rrset_attrs.values
          ttl rrset_attrs.ttl if rrset_attrs.ttl
        end

        ResourceReference.new(
          type: 'hcloud_zone_rrset',
          name: name,
          resource_attributes: rrset_attrs.to_h,
          outputs: {
            id: "${hcloud_zone_rrset.#{name}.id}",
            zone_id: "${hcloud_zone_rrset.#{name}.zone_id}",
            name: "${hcloud_zone_rrset.#{name}.name}",
            type: "${hcloud_zone_rrset.#{name}.type}"
          }
        )
      end
    end

    module Hetzner
      include HcloudZoneRrset
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
