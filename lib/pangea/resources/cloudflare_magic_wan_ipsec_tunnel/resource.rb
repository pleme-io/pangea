# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_magic_wan_ipsec_tunnel/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareMagicWanIpsecTunnel
    def cloudflare_magic_wan_ipsec_tunnel(name, attributes = {})
      attrs = Cloudflare::Types::MagicWanIpsecTunnelAttributes.new(attributes)
      resource(:cloudflare_magic_wan_ipsec_tunnel, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_magic_wan_ipsec_tunnel',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_magic_wan_ipsec_tunnel.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareMagicWanIpsecTunnel
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
