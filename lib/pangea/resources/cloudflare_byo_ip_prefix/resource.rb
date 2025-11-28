# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_byo_ip_prefix/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareByoIpPrefix
    def cloudflare_byo_ip_prefix(name, attributes = {})
      attrs = Cloudflare::Types::ByoIpPrefixAttributes.new(attributes)
      resource(:cloudflare_byo_ip_prefix, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_byo_ip_prefix',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_byo_ip_prefix.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareByoIpPrefix
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
