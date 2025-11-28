# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_email_routing_catch_all/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareEmailRoutingCatchAll
    def cloudflare_email_routing_catch_all(name, attributes = {})
      attrs = Cloudflare::Types::EmailRoutingCatchAllAttributes.new(attributes)
      resource(:cloudflare_email_routing_catch_all, name) do
        zone_id attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_email_routing_catch_all',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_email_routing_catch_all.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareEmailRoutingCatchAll
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
