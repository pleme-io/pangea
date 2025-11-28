# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_primary_ip/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudPrimaryIp
      # Create Primary IP
      def hcloud_primary_ip(name, attributes = {})
        pip_attrs = Hetzner::Types::PrimaryIpAttributes.new(attributes)

        resource(:hcloud_primary_ip, name) do
          name pip_attrs.name
          type pip_attrs.type
          assignee_type pip_attrs.assignee_type
          assignee_id pip_attrs.assignee_id if pip_attrs.assignee_id
          datacenter pip_attrs.datacenter if pip_attrs.datacenter
          auto_delete pip_attrs.auto_delete

          if pip_attrs.labels.any?
            labels do
              pip_attrs.labels.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

        ResourceReference.new(
          type: 'hcloud_primary_ip',
          name: name,
          resource_attributes: pip_attrs.to_h,
          outputs: {
            id: "${hcloud_primary_ip.#{name}.id}",
            ip_address: "${hcloud_primary_ip.#{name}.ip_address}",
            name: "${hcloud_primary_ip.#{name}.name}"
          }
        )
      end
    end

    module Hetzner
      include HcloudPrimaryIp
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
