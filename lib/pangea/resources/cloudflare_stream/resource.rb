# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_stream/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareStream
    def cloudflare_stream(name, attributes = {})
      attrs = Cloudflare::Types::StreamAttributes.new(attributes)
      resource(:cloudflare_stream, name) do
        account_id attrs.account_id
        name attrs.name if attrs.name
        meta attrs.meta if attrs.meta
        require_signed_urls attrs.require_signed_urls if !attrs.require_signed_urls.nil?
        allowed_origins attrs.allowed_origins if attrs.allowed_origins
        thumbnail_timestamp_pct attrs.thumbnail_timestamp_pct if attrs.thumbnail_timestamp_pct
      end
      ResourceReference.new(
        type: 'cloudflare_stream',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: {
          id: "${cloudflare_stream.#{name}.id}",
          preview: "${cloudflare_stream.#{name}.preview}",
          playback_url: "${cloudflare_stream.#{name}.playback_url}"
        }
      )
    end
  end
  module Cloudflare
    include CloudflareStream
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
