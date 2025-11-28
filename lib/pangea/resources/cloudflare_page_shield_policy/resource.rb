# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_page_shield_policy/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflarePageShieldPolicy
    def cloudflare_page_shield_policy(name, attributes = {})
      attrs = Cloudflare::Types::PageShieldPolicyAttributes.new(attributes)
      resource(:cloudflare_page_shield_policy, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_page_shield_policy',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_page_shield_policy.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflarePageShieldPolicy
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
