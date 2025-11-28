# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_access_group/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustAccessGroup
    def cloudflare_zero_trust_access_group(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustAccessGroupAttributes.new(attributes)
      resource(:cloudflare_zero_trust_access_group, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
        name attrs.name
        include attrs.include
        exclude attrs.exclude if attrs.exclude
        require attrs.require if attrs.require
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_access_group',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_access_group.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustAccessGroup
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
