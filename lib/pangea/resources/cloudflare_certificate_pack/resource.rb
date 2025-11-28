# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_certificate_pack/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareCertificatePack
    def cloudflare_certificate_pack(name, attributes = {})
      attrs = Cloudflare::Types::CertificatePackAttributes.new(attributes)
      resource(:cloudflare_certificate_pack, name) do
        zone_id attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_certificate_pack',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_certificate_pack.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareCertificatePack
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
