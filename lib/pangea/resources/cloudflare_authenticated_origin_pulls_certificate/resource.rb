# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_authenticated_origin_pulls_certificate/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareAuthenticatedOriginPullsCertificate
    def cloudflare_authenticated_origin_pulls_certificate(name, attributes = {})
      attrs = Cloudflare::Types::AuthenticatedOriginPullsCertificateAttributes.new(attributes)
      resource(:cloudflare_authenticated_origin_pulls_certificate, name) do
        zone_id attrs.zone_id
        certificate attrs.certificate
        private_key attrs.private_key
        type attrs.type if attrs.type
      end
      ResourceReference.new(
        type: 'cloudflare_authenticated_origin_pulls_certificate',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: {
          id: "${cloudflare_authenticated_origin_pulls_certificate.#{name}.id}",
          status: "${cloudflare_authenticated_origin_pulls_certificate.#{name}.status}",
          expires_on: "${cloudflare_authenticated_origin_pulls_certificate.#{name}.expires_on}"
        }
      )
    end
  end
  module Cloudflare
    include CloudflareAuthenticatedOriginPullsCertificate
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
