# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_dns_zone_transfers_tsig/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareDnsZoneTransfersTsig
    def cloudflare_dns_zone_transfers_tsig(name, attributes = {})
      attrs = Cloudflare::Types::DnsZoneTransfersTsigAttributes.new(attributes)
      resource(:cloudflare_dns_zone_transfers_tsig, name) do
        zone_id attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_dns_zone_transfers_tsig',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_dns_zone_transfers_tsig.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareDnsZoneTransfersTsig
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
