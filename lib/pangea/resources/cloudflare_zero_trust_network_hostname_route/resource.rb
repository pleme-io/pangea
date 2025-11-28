# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_network_hostname_route/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustNetworkHostnameRoute
    def cloudflare_zero_trust_network_hostname_route(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustNetworkHostnameRouteAttributes.new(attributes)
      resource(:cloudflare_zero_trust_network_hostname_route, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_network_hostname_route',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_network_hostname_route.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustNetworkHostnameRoute
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
