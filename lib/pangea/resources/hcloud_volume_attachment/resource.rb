# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_volume_attachment/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudVolumeAttachment
      # Attach a Volume to a Server
      def hcloud_volume_attachment(name, attributes = {})
        va_attrs = Hetzner::Types::VolumeAttachmentAttributes.new(attributes)

        resource(:hcloud_volume_attachment, name) do
          volume_id va_attrs.volume_id
          server_id va_attrs.server_id
          automount va_attrs.automount
        end

        ResourceReference.new(
          type: 'hcloud_volume_attachment',
          name: name,
          resource_attributes: va_attrs.to_h,
          outputs: {
            id: "${hcloud_volume_attachment.#{name}.id}",
            volume_id: "${hcloud_volume_attachment.#{name}.volume_id}",
            server_id: "${hcloud_volume_attachment.#{name}.server_id}"
          }
        )
      end
    end

    module Hetzner
      include HcloudVolumeAttachment
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
