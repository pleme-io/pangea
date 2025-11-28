# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_snapshot/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudSnapshot
      # Create a snapshot from a Hetzner Cloud server
      def hcloud_snapshot(name, attributes = {})
        snapshot_attrs = Hetzner::Types::SnapshotAttributes.new(attributes)

        resource(:hcloud_snapshot, name) do
          server_id snapshot_attrs.server_id
          description snapshot_attrs.description if snapshot_attrs.description
          labels snapshot_attrs.labels
        end

        ResourceReference.new(
          type: 'hcloud_snapshot',
          name: name,
          resource_attributes: snapshot_attrs.to_h,
          outputs: {
            id: "${hcloud_snapshot.#{name}.id}",
            image_id: "${hcloud_snapshot.#{name}.id}",
            description: "${hcloud_snapshot.#{name}.description}"
          }
        )
      end
    end

    module Hetzner
      include HcloudSnapshot
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
