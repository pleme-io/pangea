# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_load_balancer_network/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudLoadBalancerNetwork
      # Attach Load Balancer to Network
      def hcloud_load_balancer_network(name, attributes = {})
        lbn_attrs = Hetzner::Types::LoadBalancerNetworkAttributes.new(attributes)

        resource(:hcloud_load_balancer_network, name) do
          load_balancer_id lbn_attrs.load_balancer_id
          network_id lbn_attrs.network_id
          ip lbn_attrs.ip if lbn_attrs.ip
          enable_public_interface lbn_attrs.enable_public_interface
        end

        ResourceReference.new(
          type: 'hcloud_load_balancer_network',
          name: name,
          resource_attributes: lbn_attrs.to_h,
          outputs: {
            id: "${hcloud_load_balancer_network.#{name}.id}",
            load_balancer_id: "${hcloud_load_balancer_network.#{name}.load_balancer_id}",
            network_id: "${hcloud_load_balancer_network.#{name}.network_id}",
            ip: "${hcloud_load_balancer_network.#{name}.ip}"
          }
        )
      end
    end

    module Hetzner
      include HcloudLoadBalancerNetwork
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
