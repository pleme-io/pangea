# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_access_short_lived_certificate/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustAccessShortLivedCertificate
    def cloudflare_zero_trust_access_short_lived_certificate(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustAccessShortLivedCertificateAttributes.new(attributes)
      resource(:cloudflare_zero_trust_access_short_lived_certificate, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_access_short_lived_certificate',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_access_short_lived_certificate.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustAccessShortLivedCertificate
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
