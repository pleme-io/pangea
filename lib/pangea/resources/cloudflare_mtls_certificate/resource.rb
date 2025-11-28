# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_mtls_certificate/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareMtlsCertificate
    def cloudflare_mtls_certificate(name, attributes = {})
      attrs = Cloudflare::Types::MtlsCertificateAttributes.new(attributes)
      resource(:cloudflare_mtls_certificate, name) do
        account_id attrs.account_id
        ca attrs.ca
        certificates attrs.certificates
        name attrs.name if attrs.name
        private_key attrs.private_key if attrs.private_key
      end
      ResourceReference.new(
        type: 'cloudflare_mtls_certificate',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: {
          id: "${cloudflare_mtls_certificate.#{name}.id}",
          expires_on: "${cloudflare_mtls_certificate.#{name}.expires_on}",
          issuer: "${cloudflare_mtls_certificate.#{name}.issuer}"
        }
      )
    end
  end
  module Cloudflare
    include CloudflareMtlsCertificate
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
