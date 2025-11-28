# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_access_mtls_certificate/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustAccessMtlsCertificate
    def cloudflare_zero_trust_access_mtls_certificate(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustAccessMtlsCertificateAttributes.new(attributes)
      resource(:cloudflare_zero_trust_access_mtls_certificate, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_access_mtls_certificate',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_access_mtls_certificate.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustAccessMtlsCertificate
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
