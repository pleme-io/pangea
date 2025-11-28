# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_notification_policy/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareNotificationPolicy
    def cloudflare_notification_policy(name, attributes = {})
      attrs = Cloudflare::Types::NotificationPolicyAttributes.new(attributes)
      resource(:cloudflare_notification_policy, name) do
        account_id attrs.account_id
        name attrs.name
        alert_type attrs.alert_type
        enabled attrs.enabled
        description attrs.description if attrs.description
        email_integration attrs.email_integration if attrs.email_integration
        webhooks_integration attrs.webhooks_integration if attrs.webhooks_integration
        pagerduty_integration attrs.pagerduty_integration if attrs.pagerduty_integration
        filters attrs.filters if attrs.filters
      end
      ResourceReference.new(
        type: 'cloudflare_notification_policy',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_notification_policy.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareNotificationPolicy
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
