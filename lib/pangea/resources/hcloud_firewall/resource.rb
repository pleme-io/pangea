# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_firewall/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudFirewall
      # Create a Hetzner Cloud Firewall with type-safe attributes
      def hcloud_firewall(name, attributes = {})
        firewall_attrs = Hetzner::Types::FirewallAttributes.new(attributes)

        resource(:hcloud_firewall, name) do
          name firewall_attrs.name

          # Add firewall rules
          firewall_attrs.rules.each do |rule|
            rule do
              direction rule[:direction]
              protocol rule[:protocol]
              port rule[:port] if rule[:port]
              source_ips rule[:source_ips] if rule[:source_ips]
              destination_ips rule[:destination_ips] if rule[:destination_ips]
            end
          end

          if firewall_attrs.labels.any?
            labels do
              firewall_attrs.labels.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

        ResourceReference.new(
          type: 'hcloud_firewall',
          name: name,
          resource_attributes: firewall_attrs.to_h,
          outputs: {
            id: "${hcloud_firewall.#{name}.id}",
            name: "${hcloud_firewall.#{name}.name}"
          }
        )
      end
    end

    module Hetzner
      include HcloudFirewall
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
