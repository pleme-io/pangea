# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_logpull_retention/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareLogpullRetention
    def cloudflare_logpull_retention(name, attributes = {})
      attrs = Cloudflare::Types::LogpullRetentionAttributes.new(attributes)
      resource(:cloudflare_logpull_retention, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_logpull_retention',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_logpull_retention.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareLogpullRetention
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
