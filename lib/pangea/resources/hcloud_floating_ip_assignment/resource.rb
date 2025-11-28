# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_floating_ip_assignment/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudFloatingIpAssignment
      # Assign a Floating IP to a Server
      def hcloud_floating_ip_assignment(name, attributes = {})
        fia_attrs = Hetzner::Types::FloatingIpAssignmentAttributes.new(attributes)

        resource(:hcloud_floating_ip_assignment, name) do
          floating_ip_id fia_attrs.floating_ip_id
          server_id fia_attrs.server_id
        end

        ResourceReference.new(
          type: 'hcloud_floating_ip_assignment',
          name: name,
          resource_attributes: fia_attrs.to_h,
          outputs: {
            id: "${hcloud_floating_ip_assignment.#{name}.id}",
            floating_ip_id: "${hcloud_floating_ip_assignment.#{name}.floating_ip_id}",
            server_id: "${hcloud_floating_ip_assignment.#{name}.server_id}"
          }
        )
      end
    end

    module Hetzner
      include HcloudFloatingIpAssignment
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
