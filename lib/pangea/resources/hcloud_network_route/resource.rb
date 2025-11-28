# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_network_route/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudNetworkRoute
      # Create a custom network route
      def hcloud_network_route(name, attributes = {})
        route_attrs = Hetzner::Types::NetworkRouteAttributes.new(attributes)

        resource(:hcloud_network_route, name) do
          network_id route_attrs.network_id
          destination route_attrs.destination
          gateway route_attrs.gateway
        end

        ResourceReference.new(
          type: 'hcloud_network_route',
          name: name,
          resource_attributes: route_attrs.to_h,
          outputs: {
            id: "${hcloud_network_route.#{name}.id}",
            network_id: "${hcloud_network_route.#{name}.network_id}",
            destination: "${hcloud_network_route.#{name}.destination}",
            gateway: "${hcloud_network_route.#{name}.gateway}"
          }
        )
      end
    end

    module Hetzner
      include HcloudNetworkRoute
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
