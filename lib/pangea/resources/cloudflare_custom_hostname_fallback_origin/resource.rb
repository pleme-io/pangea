# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_custom_hostname_fallback_origin/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareCustomHostnameFallbackOrigin
    def cloudflare_custom_hostname_fallback_origin(name, attributes = {})
      attrs = Cloudflare::Types::CustomHostnameFallbackOriginAttributes.new(attributes)
      resource(:cloudflare_custom_hostname_fallback_origin, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_custom_hostname_fallback_origin',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_custom_hostname_fallback_origin.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareCustomHostnameFallbackOrigin
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
