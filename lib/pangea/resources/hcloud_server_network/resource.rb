# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_server_network/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudServerNetwork
      # Attach a Hetzner Cloud Server to a Network
      def hcloud_server_network(name, attributes = {})
        sn_attrs = Hetzner::Types::ServerNetworkAttributes.new(attributes)

        resource(:hcloud_server_network, name) do
          server_id sn_attrs.server_id
          network_id sn_attrs.network_id
          ip sn_attrs.ip if sn_attrs.ip
          alias_ips sn_attrs.alias_ips if sn_attrs.alias_ips.any?
        end

        ResourceReference.new(
          type: 'hcloud_server_network',
          name: name,
          resource_attributes: sn_attrs.to_h,
          outputs: {
            id: "${hcloud_server_network.#{name}.id}",
            server_id: "${hcloud_server_network.#{name}.server_id}",
            network_id: "${hcloud_server_network.#{name}.network_id}",
            ip: "${hcloud_server_network.#{name}.ip}"
          }
        )
      end
    end

    module Hetzner
      include HcloudServerNetwork
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
