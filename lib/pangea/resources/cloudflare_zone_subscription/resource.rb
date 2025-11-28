# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zone_subscription/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZoneSubscription
    def cloudflare_zone_subscription(name, attributes = {})
      attrs = Cloudflare::Types::ZoneSubscriptionAttributes.new(attributes)
      resource(:cloudflare_zone_subscription, name) do
        zone_id attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_zone_subscription',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zone_subscription.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZoneSubscription
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
