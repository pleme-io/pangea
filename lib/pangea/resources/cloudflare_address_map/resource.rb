# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_address_map/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareAddressMap
    def cloudflare_address_map(name, attributes = {})
      attrs = Cloudflare::Types::AddressMapAttributes.new(attributes)
      resource(:cloudflare_address_map, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_address_map',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_address_map.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareAddressMap
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
