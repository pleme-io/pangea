# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_email_routing_address/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareEmailRoutingAddress
    def cloudflare_email_routing_address(name, attributes = {})
      attrs = Cloudflare::Types::EmailRoutingAddressAttributes.new(attributes)
      resource(:cloudflare_email_routing_address, name) do
        zone_id attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_email_routing_address',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_email_routing_address.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareEmailRoutingAddress
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
