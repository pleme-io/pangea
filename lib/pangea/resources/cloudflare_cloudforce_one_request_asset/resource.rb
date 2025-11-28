# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_cloudforce_one_request_asset/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareCloudforceOneRequestAsset
    def cloudflare_cloudforce_one_request_asset(name, attributes = {})
      attrs = Cloudflare::Types::CloudforceOneRequestAssetAttributes.new(attributes)
      resource(:cloudflare_cloudforce_one_request_asset, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_cloudforce_one_request_asset',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_cloudforce_one_request_asset.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareCloudforceOneRequestAsset
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
