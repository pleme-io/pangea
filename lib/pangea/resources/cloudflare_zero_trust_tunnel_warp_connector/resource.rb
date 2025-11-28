# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_tunnel_warp_connector/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustTunnelWarpConnector
    def cloudflare_zero_trust_tunnel_warp_connector(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustTunnelWarpConnectorAttributes.new(attributes)
      resource(:cloudflare_zero_trust_tunnel_warp_connector, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_tunnel_warp_connector',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_tunnel_warp_connector.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustTunnelWarpConnector
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
