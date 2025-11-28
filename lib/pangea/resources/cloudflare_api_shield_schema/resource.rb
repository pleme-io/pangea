# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_api_shield_schema/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareApiShieldSchema
    def cloudflare_api_shield_schema(name, attributes = {})
      attrs = Cloudflare::Types::ApiShieldSchemaAttributes.new(attributes)
      resource(:cloudflare_api_shield_schema, name) do
        zone_id attrs.zone_id
        name attrs.name
        source attrs.source
        kind attrs.kind if attrs.kind
        validation_enabled attrs.validation_enabled if !attrs.validation_enabled.nil?
      end
      ResourceReference.new(
        type: 'cloudflare_api_shield_schema',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_api_shield_schema.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareApiShieldSchema
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
