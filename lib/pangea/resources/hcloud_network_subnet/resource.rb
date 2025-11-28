# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_network_subnet/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudNetworkSubnet
      # Create a Hetzner Cloud Network Subnet with type-safe attributes
      def hcloud_network_subnet(name, attributes = {})
        subnet_attrs = Hetzner::Types::NetworkSubnetAttributes.new(attributes)

        resource(:hcloud_network_subnet, name) do
          network_id subnet_attrs.network_id
          type subnet_attrs.type
          network_zone subnet_attrs.network_zone
          ip_range subnet_attrs.ip_range
          vswitch_id subnet_attrs.vswitch_id if subnet_attrs.vswitch_id
        end

        ResourceReference.new(
          type: 'hcloud_network_subnet',
          name: name,
          resource_attributes: subnet_attrs.to_h,
          outputs: {
            id: "${hcloud_network_subnet.#{name}.id}",
            network_id: "${hcloud_network_subnet.#{name}.network_id}",
            ip_range: "${hcloud_network_subnet.#{name}.ip_range}",
            gateway: "${hcloud_network_subnet.#{name}.gateway}"
          }
        )
      end
    end

    module Hetzner
      include HcloudNetworkSubnet
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
