# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zone_cache_variants/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZoneCacheVariants
    def cloudflare_zone_cache_variants(name, attributes = {})
      attrs = Cloudflare::Types::ZoneCacheVariantsAttributes.new(attributes)
      resource(:cloudflare_zone_cache_variants, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zone_cache_variants',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zone_cache_variants.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZoneCacheVariants
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
