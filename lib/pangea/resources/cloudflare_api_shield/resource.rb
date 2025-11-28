# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_api_shield/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareApiShield
    def cloudflare_api_shield(name, attributes = {})
      attrs = Cloudflare::Types::ApiShieldAttributes.new(attributes)
      resource(:cloudflare_api_shield, name) do
        zone_id attrs.zone_id
        auth_id_characteristics attrs.auth_id_characteristics if attrs.auth_id_characteristics
      end
      ResourceReference.new(
        type: 'cloudflare_api_shield',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_api_shield.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareApiShield
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
