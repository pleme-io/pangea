# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/hcloud_rdns/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module HcloudRdns
      # Create Reverse DNS entry
      def hcloud_rdns(name, attributes = {})
        rdns_attrs = Hetzner::Types::RdnsAttributes.new(attributes)

        resource(:hcloud_rdns, name) do
          server_id rdns_attrs.server_id
          ip_address rdns_attrs.ip_address
          dns_ptr rdns_attrs.dns_ptr
        end

        ResourceReference.new(
          type: 'hcloud_rdns',
          name: name,
          resource_attributes: rdns_attrs.to_h,
          outputs: {
            id: "${hcloud_rdns.#{name}.id}",
            server_id: "${hcloud_rdns.#{name}.server_id}",
            ip_address: "${hcloud_rdns.#{name}.ip_address}",
            dns_ptr: "${hcloud_rdns.#{name}.dns_ptr}"
          }
        )
      end
    end

    module Hetzner
      include HcloudRdns
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Hetzner)
