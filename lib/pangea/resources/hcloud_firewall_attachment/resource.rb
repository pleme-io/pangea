# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_firewall_attachment/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudFirewallAttachment
      # Attach Firewall to Servers
      def hcloud_firewall_attachment(name, attributes = {})
        fa_attrs = Hetzner::Types::FirewallAttachmentAttributes.new(attributes)

        resource(:hcloud_firewall_attachment, name) do
          firewall_id fa_attrs.firewall_id
          server_ids fa_attrs.server_ids if fa_attrs.server_ids.any?
        end

        ResourceReference.new(
          type: 'hcloud_firewall_attachment',
          name: name,
          resource_attributes: fa_attrs.to_h,
          outputs: {
            id: "${hcloud_firewall_attachment.#{name}.id}",
            firewall_id: "${hcloud_firewall_attachment.#{name}.firewall_id}",
            server_ids: "${hcloud_firewall_attachment.#{name}.server_ids}"
          }
        )
      end
    end

    module Hetzner
      include HcloudFirewallAttachment
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
