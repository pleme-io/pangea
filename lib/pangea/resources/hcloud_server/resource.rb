# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_server/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudServer
      # Create a Hetzner Cloud Server with type-safe attributes
      def hcloud_server(name, attributes = {})
        server_attrs = Hetzner::Types::ServerAttributes.new(attributes)

        resource(:hcloud_server, name) do
          name server_attrs.name
          server_type server_attrs.server_type
          image server_attrs.image

          # Optional attributes
          location server_attrs.location if server_attrs.location
          datacenter server_attrs.datacenter if server_attrs.datacenter

          # Arrays
          ssh_keys server_attrs.ssh_keys if server_attrs.ssh_keys.any?
          firewall_ids server_attrs.firewall_ids if server_attrs.firewall_ids.any?

          # Boolean/text attributes
          backups server_attrs.backups
          user_data server_attrs.user_data if server_attrs.user_data
          iso server_attrs.iso if server_attrs.iso
          send(:rescue, server_attrs.rescue) if server_attrs.rescue

          # Nested block for public network configuration
          if server_attrs.public_net
            public_net do
              ipv4_enabled server_attrs.public_net[:ipv4_enabled] if server_attrs.public_net.key?(:ipv4_enabled)
              ipv6_enabled server_attrs.public_net[:ipv6_enabled] if server_attrs.public_net.key?(:ipv6_enabled)
              ipv4 server_attrs.public_net[:ipv4] if server_attrs.public_net[:ipv4]
              ipv6 server_attrs.public_net[:ipv6] if server_attrs.public_net[:ipv6]
            end
          end

          # Nested block for private network configuration
          if server_attrs.network
            network do
              network_id server_attrs.network[:network_id] if server_attrs.network[:network_id]
              ip server_attrs.network[:ip] if server_attrs.network[:ip]
              alias_ips server_attrs.network[:alias_ips] if server_attrs.network[:alias_ips]
            end
          end

          # Placement group
          placement_group_id server_attrs.placement_group_id if server_attrs.placement_group_id

          # Labels
          if server_attrs.labels.any?
            labels do
              server_attrs.labels.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

        ResourceReference.new(
          type: 'hcloud_server',
          name: name,
          resource_attributes: server_attrs.to_h,
          outputs: {
            id: "${hcloud_server.#{name}.id}",
            name: "${hcloud_server.#{name}.name}",
            ipv4_address: "${hcloud_server.#{name}.ipv4_address}",
            ipv6_address: "${hcloud_server.#{name}.ipv6_address}",
            ipv6_network: "${hcloud_server.#{name}.ipv6_network}",
            status: "${hcloud_server.#{name}.status}",
            backup_window: "${hcloud_server.#{name}.backup_window}",
            datacenter: "${hcloud_server.#{name}.datacenter}"
          }
        )
      end
    end

    module Hetzner
      include HcloudServer
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
