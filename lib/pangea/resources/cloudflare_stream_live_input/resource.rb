# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_stream_live_input/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareStreamLiveInput
    def cloudflare_stream_live_input(name, attributes = {})
      attrs = Cloudflare::Types::StreamLiveInputAttributes.new(attributes)
      resource(:cloudflare_stream_live_input, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_stream_live_input',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_stream_live_input.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareStreamLiveInput
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
