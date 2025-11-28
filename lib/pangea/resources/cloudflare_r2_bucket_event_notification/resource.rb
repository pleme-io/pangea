# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_r2_bucket_event_notification/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareR2BucketEventNotification
    def cloudflare_r2_bucket_event_notification(name, attributes = {})
      attrs = Cloudflare::Types::R2BucketEventNotificationAttributes.new(attributes)
      resource(:cloudflare_r2_bucket_event_notification, name) do
        account_id attrs.account_id
        bucket attrs.bucket
        queue attrs.queue
        event_types attrs.event_types if attrs.event_types
        prefix attrs.prefix if attrs.prefix
        suffix attrs.suffix if attrs.suffix
      end
      ResourceReference.new(
        type: 'cloudflare_r2_bucket_event_notification',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_r2_bucket_event_notification.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareR2BucketEventNotification
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
