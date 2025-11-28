# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_stream_watermark/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareStreamWatermark
    def cloudflare_stream_watermark(name, attributes = {})
      attrs = Cloudflare::Types::StreamWatermarkAttributes.new(attributes)
      resource(:cloudflare_stream_watermark, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_stream_watermark',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_stream_watermark.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareStreamWatermark
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
