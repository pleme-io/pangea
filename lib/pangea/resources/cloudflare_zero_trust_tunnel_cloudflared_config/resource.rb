# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_tunnel_cloudflared_config/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustTunnelCloudflaredConfig
    def cloudflare_zero_trust_tunnel_cloudflared_config(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustTunnelCloudflaredConfigAttributes.new(attributes)
      resource(:cloudflare_zero_trust_tunnel_cloudflared_config, name) do
        account_id attrs.account_id
        tunnel_id attrs.tunnel_id
        config attrs.config
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_tunnel_cloudflared_config',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_tunnel_cloudflared_config.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustTunnelCloudflaredConfig
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
