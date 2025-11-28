# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_placement_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudPlacementGroup
      # Create Placement Group
      def hcloud_placement_group(name, attributes = {})
        pg_attrs = Hetzner::Types::PlacementGroupAttributes.new(attributes)

        resource(:hcloud_placement_group, name) do
          name pg_attrs.name
          type pg_attrs.type

          if pg_attrs.labels.any?
            labels do
              pg_attrs.labels.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

        ResourceReference.new(
          type: 'hcloud_placement_group',
          name: name,
          resource_attributes: pg_attrs.to_h,
          outputs: {
            id: "${hcloud_placement_group.#{name}.id}",
            name: "${hcloud_placement_group.#{name}.name}",
            type: "${hcloud_placement_group.#{name}.type}"
          }
        )
      end
    end

    module Hetzner
      include HcloudPlacementGroup
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
