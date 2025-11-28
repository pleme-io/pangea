# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_load_balancer_target/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudLoadBalancerTarget
      # Add Target to Load Balancer
      def hcloud_load_balancer_target(name, attributes = {})
        lbt_attrs = Hetzner::Types::LoadBalancerTargetAttributes.new(attributes)

        resource(:hcloud_load_balancer_target, name) do
          load_balancer_id lbt_attrs.load_balancer_id
          type lbt_attrs.type
          server_id lbt_attrs.server_id if lbt_attrs.server_id
          label_selector lbt_attrs.label_selector if lbt_attrs.label_selector
          ip lbt_attrs.ip if lbt_attrs.ip
          use_private_ip lbt_attrs.use_private_ip
        end

        ResourceReference.new(
          type: 'hcloud_load_balancer_target',
          name: name,
          resource_attributes: lbt_attrs.to_h,
          outputs: {
            id: "${hcloud_load_balancer_target.#{name}.id}",
            load_balancer_id: "${hcloud_load_balancer_target.#{name}.load_balancer_id}",
            type: "${hcloud_load_balancer_target.#{name}.type}",
            server_id: "${hcloud_load_balancer_target.#{name}.server_id}"
          }
        )
      end
    end

    module Hetzner
      include HcloudLoadBalancerTarget
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
