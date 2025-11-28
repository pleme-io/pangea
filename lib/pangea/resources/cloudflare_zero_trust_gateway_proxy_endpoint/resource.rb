# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_gateway_proxy_endpoint/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustGatewayProxyEndpoint
    def cloudflare_zero_trust_gateway_proxy_endpoint(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustGatewayProxyEndpointAttributes.new(attributes)
      resource(:cloudflare_zero_trust_gateway_proxy_endpoint, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_gateway_proxy_endpoint',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_gateway_proxy_endpoint.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustGatewayProxyEndpoint
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
