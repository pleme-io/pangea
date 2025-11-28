# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_dns_zone_transfers_outgoing/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareDnsZoneTransfersOutgoing
    def cloudflare_dns_zone_transfers_outgoing(name, attributes = {})
      attrs = Cloudflare::Types::DnsZoneTransfersOutgoingAttributes.new(attributes)
      resource(:cloudflare_dns_zone_transfers_outgoing, name) do
        zone_id attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_dns_zone_transfers_outgoing',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_dns_zone_transfers_outgoing.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareDnsZoneTransfersOutgoing
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
