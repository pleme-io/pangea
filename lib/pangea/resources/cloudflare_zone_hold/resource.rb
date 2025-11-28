# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zone_hold/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZoneHold
    def cloudflare_zone_hold(name, attributes = {})
      attrs = Cloudflare::Types::ZoneHoldAttributes.new(attributes)
      resource(:cloudflare_zone_hold, name) do
        zone_id attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_zone_hold',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zone_hold.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZoneHold
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
