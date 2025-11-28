# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_dns_location/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustDnsLocation
    def cloudflare_zero_trust_dns_location(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustDnsLocationAttributes.new(attributes)
      resource(:cloudflare_zero_trust_dns_location, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_dns_location',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_dns_location.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustDnsLocation
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
