# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_floating_ip/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudFloatingIp
      # Create a Hetzner Cloud Floating IP
      def hcloud_floating_ip(name, attributes = {})
        fip_attrs = Hetzner::Types::FloatingIpAttributes.new(attributes)

        resource(:hcloud_floating_ip, name) do
          type fip_attrs.type
          home_location fip_attrs.home_location if fip_attrs.home_location
          server_id fip_attrs.server_id if fip_attrs.server_id
          description fip_attrs.description if fip_attrs.description
          name fip_attrs.name if fip_attrs.name

          if fip_attrs.labels.any?
            labels do
              fip_attrs.labels.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

        ResourceReference.new(
          type: 'hcloud_floating_ip',
          name: name,
          resource_attributes: fip_attrs.to_h,
          outputs: {
            id: "${hcloud_floating_ip.#{name}.id}",
            ip_address: "${hcloud_floating_ip.#{name}.ip_address}",
            name: "${hcloud_floating_ip.#{name}.name}",
            home_location: "${hcloud_floating_ip.#{name}.home_location}"
          }
        )
      end
    end

    module Hetzner
      include HcloudFloatingIp
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
