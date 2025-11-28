# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_keyless_certificate/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareKeylessCertificate
    def cloudflare_keyless_certificate(name, attributes = {})
      attrs = Cloudflare::Types::KeylessCertificateAttributes.new(attributes)
      resource(:cloudflare_keyless_certificate, name) do
        zone_id attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_keyless_certificate',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_keyless_certificate.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareKeylessCertificate
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
