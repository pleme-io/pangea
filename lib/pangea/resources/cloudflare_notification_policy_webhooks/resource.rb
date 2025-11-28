# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_notification_policy_webhooks/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareNotificationPolicyWebhooks
    def cloudflare_notification_policy_webhooks(name, attributes = {})
      attrs = Cloudflare::Types::NotificationPolicyWebhooksAttributes.new(attributes)
      resource(:cloudflare_notification_policy_webhooks, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_notification_policy_webhooks',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_notification_policy_webhooks.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareNotificationPolicyWebhooks
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
