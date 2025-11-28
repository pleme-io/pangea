# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_tunnel_cloudflared_virtual_network/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustTunnelCloudflaredVirtualNetwork
    def cloudflare_zero_trust_tunnel_cloudflared_virtual_network(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustTunnelCloudflaredVirtualNetworkAttributes.new(attributes)
      resource(:cloudflare_zero_trust_tunnel_cloudflared_virtual_network, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_tunnel_cloudflared_virtual_network',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_tunnel_cloudflared_virtual_network.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustTunnelCloudflaredVirtualNetwork
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
