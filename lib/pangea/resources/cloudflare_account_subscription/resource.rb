# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_account_subscription/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareAccountSubscription
    def cloudflare_account_subscription(name, attributes = {})
      attrs = Cloudflare::Types::AccountSubscriptionAttributes.new(attributes)
      resource(:cloudflare_account_subscription, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_account_subscription',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_account_subscription.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareAccountSubscription
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
