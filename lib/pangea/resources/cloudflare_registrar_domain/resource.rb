# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_registrar_domain/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareRegistrarDomain
    def cloudflare_registrar_domain(name, attributes = {})
      attrs = Cloudflare::Types::RegistrarDomainAttributes.new(attributes)
      resource(:cloudflare_registrar_domain, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_registrar_domain',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_registrar_domain.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareRegistrarDomain
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
