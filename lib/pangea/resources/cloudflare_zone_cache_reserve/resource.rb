# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zone_cache_reserve/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZoneCacheReserve
    def cloudflare_zone_cache_reserve(name, attributes = {})
      attrs = Cloudflare::Types::ZoneCacheReserveAttributes.new(attributes)
      resource(:cloudflare_zone_cache_reserve, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zone_cache_reserve',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zone_cache_reserve.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZoneCacheReserve
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
