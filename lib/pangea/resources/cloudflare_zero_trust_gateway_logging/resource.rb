# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_gateway_logging/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustGatewayLogging
    def cloudflare_zero_trust_gateway_logging(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustGatewayLoggingAttributes.new(attributes)
      resource(:cloudflare_zero_trust_gateway_logging, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_gateway_logging',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_gateway_logging.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustGatewayLogging
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
