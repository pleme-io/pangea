# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_tunnel_cloudflared/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustTunnelCloudflared
    def cloudflare_zero_trust_tunnel_cloudflared(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustTunnelCloudflaredAttributes.new(attributes)
      resource(:cloudflare_zero_trust_tunnel_cloudflared, name) do
        account_id attrs.account_id
        name attrs.name
        secret attrs.secret
        config_src attrs.config_src if attrs.config_src
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_tunnel_cloudflared',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: {
          id: "${cloudflare_zero_trust_tunnel_cloudflared.#{name}.id}",
          cname: "${cloudflare_zero_trust_tunnel_cloudflared.#{name}.cname}",
          tunnel_token: "${cloudflare_zero_trust_tunnel_cloudflared.#{name}.tunnel_token}"
        }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustTunnelCloudflared
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
