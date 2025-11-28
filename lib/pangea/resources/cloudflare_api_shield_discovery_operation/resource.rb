# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_api_shield_discovery_operation/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareApiShieldDiscoveryOperation
    def cloudflare_api_shield_discovery_operation(name, attributes = {})
      attrs = Cloudflare::Types::ApiShieldDiscoveryOperationAttributes.new(attributes)
      resource(:cloudflare_api_shield_discovery_operation, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_api_shield_discovery_operation',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_api_shield_discovery_operation.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareApiShieldDiscoveryOperation
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
