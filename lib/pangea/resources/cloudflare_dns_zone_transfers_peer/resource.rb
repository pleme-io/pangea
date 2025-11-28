# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_dns_zone_transfers_peer/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareDnsZoneTransfersPeer
    def cloudflare_dns_zone_transfers_peer(name, attributes = {})
      attrs = Cloudflare::Types::DnsZoneTransfersPeerAttributes.new(attributes)
      resource(:cloudflare_dns_zone_transfers_peer, name) do
        zone_id attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_dns_zone_transfers_peer',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_dns_zone_transfers_peer.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareDnsZoneTransfersPeer
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
