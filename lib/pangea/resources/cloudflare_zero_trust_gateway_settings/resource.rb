# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_gateway_settings/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustGatewaySettings
    def cloudflare_zero_trust_gateway_settings(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustGatewaySettingsAttributes.new(attributes)
      resource(:cloudflare_zero_trust_gateway_settings, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_gateway_settings',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_gateway_settings.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustGatewaySettings
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
