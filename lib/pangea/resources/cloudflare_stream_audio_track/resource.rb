# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_stream_audio_track/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareStreamAudioTrack
    def cloudflare_stream_audio_track(name, attributes = {})
      attrs = Cloudflare::Types::StreamAudioTrackAttributes.new(attributes)
      resource(:cloudflare_stream_audio_track, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_stream_audio_track',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_stream_audio_track.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareStreamAudioTrack
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
