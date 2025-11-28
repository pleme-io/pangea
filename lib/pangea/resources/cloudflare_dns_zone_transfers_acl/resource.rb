# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_dns_zone_transfers_acl/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareDnsZoneTransfersAcl
    def cloudflare_dns_zone_transfers_acl(name, attributes = {})
      attrs = Cloudflare::Types::DnsZoneTransfersAclAttributes.new(attributes)
      resource(:cloudflare_dns_zone_transfers_acl, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_dns_zone_transfers_acl',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_dns_zone_transfers_acl.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareDnsZoneTransfersAcl
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
