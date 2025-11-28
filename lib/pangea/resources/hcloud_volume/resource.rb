# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_volume/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudVolume
      # Create a Hetzner Cloud Volume
      def hcloud_volume(name, attributes = {})
        volume_attrs = Hetzner::Types::VolumeAttributes.new(attributes)

        resource(:hcloud_volume, name) do
          name volume_attrs.name
          size volume_attrs.size
          location volume_attrs.location if volume_attrs.location
          server_id volume_attrs.server_id if volume_attrs.server_id
          format volume_attrs.format if volume_attrs.format

          if volume_attrs.labels.any?
            labels do
              volume_attrs.labels.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

        ResourceReference.new(
          type: 'hcloud_volume',
          name: name,
          resource_attributes: volume_attrs.to_h,
          outputs: {
            id: "${hcloud_volume.#{name}.id}",
            name: "${hcloud_volume.#{name}.name}",
            size: "${hcloud_volume.#{name}.size}",
            linux_device: "${hcloud_volume.#{name}.linux_device}",
            location: "${hcloud_volume.#{name}.location}"
          }
        )
      end
    end

    module Hetzner
      include HcloudVolume
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
