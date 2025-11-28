# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_cloudforce_one_request_priority/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareCloudforceOneRequestPriority
    def cloudflare_cloudforce_one_request_priority(name, attributes = {})
      attrs = Cloudflare::Types::CloudforceOneRequestPriorityAttributes.new(attributes)
      resource(:cloudflare_cloudforce_one_request_priority, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_cloudforce_one_request_priority',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_cloudforce_one_request_priority.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareCloudforceOneRequestPriority
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
