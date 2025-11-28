# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_tunnel_cloudflared_route/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustTunnelCloudflaredRoute
    def cloudflare_zero_trust_tunnel_cloudflared_route(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustTunnelCloudflaredRouteAttributes.new(attributes)
      resource(:cloudflare_zero_trust_tunnel_cloudflared_route, name) do
        account_id attrs.account_id
        tunnel_id attrs.tunnel_id
        network attrs.network
        comment attrs.comment if attrs.comment
        virtual_network_id attrs.virtual_network_id if attrs.virtual_network_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_tunnel_cloudflared_route',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_tunnel_cloudflared_route.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustTunnelCloudflaredRoute
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
