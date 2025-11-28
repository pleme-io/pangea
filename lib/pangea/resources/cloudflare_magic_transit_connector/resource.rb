# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_magic_transit_connector/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareMagicTransitConnector
    def cloudflare_magic_transit_connector(name, attributes = {})
      attrs = Cloudflare::Types::MagicTransitConnectorAttributes.new(attributes)
      resource(:cloudflare_magic_transit_connector, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_magic_transit_connector',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_magic_transit_connector.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareMagicTransitConnector
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
