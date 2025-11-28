# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_stream_caption_language/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareStreamCaptionLanguage
    def cloudflare_stream_caption_language(name, attributes = {})
      attrs = Cloudflare::Types::StreamCaptionLanguageAttributes.new(attributes)
      resource(:cloudflare_stream_caption_language, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_stream_caption_language',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_stream_caption_language.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareStreamCaptionLanguage
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
