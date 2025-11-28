# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_api_shield_operation/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareApiShieldOperation
    def cloudflare_api_shield_operation(name, attributes = {})
      attrs = Cloudflare::Types::ApiShieldOperationAttributes.new(attributes)
      resource(:cloudflare_api_shield_operation, name) do
        zone_id attrs.zone_id
        method attrs.method
        host attrs.host
        endpoint attrs.endpoint
      end
      ResourceReference.new(
        type: 'cloudflare_api_shield_operation',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_api_shield_operation.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareApiShieldOperation
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
