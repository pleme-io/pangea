# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_load_balancer/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudLoadBalancer
      # Create a Hetzner Cloud Load Balancer
      def hcloud_load_balancer(name, attributes = {})
        lb_attrs = Hetzner::Types::LoadBalancerAttributes.new(attributes)

        resource(:hcloud_load_balancer, name) do
          name lb_attrs.name
          load_balancer_type lb_attrs.load_balancer_type
          location lb_attrs.location if lb_attrs.location
          network_zone lb_attrs.network_zone if lb_attrs.network_zone

          if lb_attrs.algorithm
            algorithm do
              type lb_attrs.algorithm[:type] if lb_attrs.algorithm[:type]
            end
          end

          if lb_attrs.labels.any?
            labels do
              lb_attrs.labels.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

        ResourceReference.new(
          type: 'hcloud_load_balancer',
          name: name,
          resource_attributes: lb_attrs.to_h,
          outputs: {
            id: "${hcloud_load_balancer.#{name}.id}",
            name: "${hcloud_load_balancer.#{name}.name}",
            ipv4: "${hcloud_load_balancer.#{name}.ipv4}",
            ipv6: "${hcloud_load_balancer.#{name}.ipv6}"
          }
        )
      end
    end

    module Hetzner
      include HcloudLoadBalancer
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
