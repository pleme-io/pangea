# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_network/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudNetwork
      # Create a Hetzner Cloud Network with type-safe attributes
      def hcloud_network(name, attributes = {})
        network_attrs = Hetzner::Types::NetworkAttributes.new(attributes)

        resource(:hcloud_network, name) do
          name network_attrs.name
          ip_range network_attrs.ip_range

          if network_attrs.labels.any?
            labels do
              network_attrs.labels.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

        ResourceReference.new(
          type: 'hcloud_network',
          name: name,
          resource_attributes: network_attrs.to_h,
          outputs: {
            id: "${hcloud_network.#{name}.id}",
            name: "${hcloud_network.#{name}.name}",
            ip_range: "${hcloud_network.#{name}.ip_range}"
          }
        )
      end
    end

    module Hetzner
      include HcloudNetwork
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
