# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_dns_zone_transfers_incoming/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareDnsZoneTransfersIncoming
    def cloudflare_dns_zone_transfers_incoming(name, attributes = {})
      attrs = Cloudflare::Types::DnsZoneTransfersIncomingAttributes.new(attributes)
      resource(:cloudflare_dns_zone_transfers_incoming, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_dns_zone_transfers_incoming',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_dns_zone_transfers_incoming.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareDnsZoneTransfersIncoming
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
