# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_gateway_certificate/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustGatewayCertificate
    def cloudflare_zero_trust_gateway_certificate(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustGatewayCertificateAttributes.new(attributes)
      resource(:cloudflare_zero_trust_gateway_certificate, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_gateway_certificate',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_gateway_certificate.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustGatewayCertificate
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
