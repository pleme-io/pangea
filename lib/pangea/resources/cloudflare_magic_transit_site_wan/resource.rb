# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_magic_transit_site_wan/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareMagicTransitSiteWan
    def cloudflare_magic_transit_site_wan(name, attributes = {})
      attrs = Cloudflare::Types::MagicTransitSiteWanAttributes.new(attributes)
      resource(:cloudflare_magic_transit_site_wan, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_magic_transit_site_wan',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_magic_transit_site_wan.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareMagicTransitSiteWan
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
