# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_access_custom_page/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustAccessCustomPage
    def cloudflare_zero_trust_access_custom_page(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustAccessCustomPageAttributes.new(attributes)
      resource(:cloudflare_zero_trust_access_custom_page, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_access_custom_page',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_access_custom_page.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustAccessCustomPage
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
