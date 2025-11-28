# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_stream_download/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareStreamDownload
    def cloudflare_stream_download(name, attributes = {})
      attrs = Cloudflare::Types::StreamDownloadAttributes.new(attributes)
      resource(:cloudflare_stream_download, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_stream_download',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_stream_download.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareStreamDownload
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
