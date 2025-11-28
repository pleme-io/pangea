# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_list/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustList
    def cloudflare_zero_trust_list(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustListAttributes.new(attributes)
      resource(:cloudflare_zero_trust_list, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_list',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_list.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustList
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
