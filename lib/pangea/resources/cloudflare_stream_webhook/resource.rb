# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_stream_webhook/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareStreamWebhook
    def cloudflare_stream_webhook(name, attributes = {})
      attrs = Cloudflare::Types::StreamWebhookAttributes.new(attributes)
      resource(:cloudflare_stream_webhook, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_stream_webhook',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_stream_webhook.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareStreamWebhook
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
