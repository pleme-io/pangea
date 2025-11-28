# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_cloudforce_one_request/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareCloudforceOneRequest
    def cloudflare_cloudforce_one_request(name, attributes = {})
      attrs = Cloudflare::Types::CloudforceOneRequestAttributes.new(attributes)
      resource(:cloudflare_cloudforce_one_request, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_cloudforce_one_request',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_cloudforce_one_request.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareCloudforceOneRequest
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
