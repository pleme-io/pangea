# frozen_string_literal: true

require_relative 'kinesisvideo/stream'
require_relative 'kinesisvideo/signaling_channel'

module Pangea
  module Resources
    module AWS
      # AWS Kinesis Video Streams service module
      # Provides type-safe resource functions for video streaming infrastructure
      module KinesisVideo
        # Creates a Kinesis video stream for video ingestion and storage
        #
        # @param name [Symbol] Unique name for the video stream resource
        # @param attributes [Hash] Configuration attributes for the video stream
        # @return [KinesisVideo::Stream::StreamReference] Reference to the created video stream
        def aws_kinesisvideo_stream(name, attributes = {})
          resource = KinesisVideo::Stream.new(
            name: name,
            synthesizer: synthesizer,
            attributes: KinesisVideo::Stream::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a Kinesis video signaling channel for WebRTC communication
        #
        # @param name [Symbol] Unique name for the signaling channel resource
        # @param attributes [Hash] Configuration attributes for the signaling channel
        # @return [KinesisVideo::SignalingChannel::SignalingChannelReference] Reference to the created signaling channel
        def aws_kinesisvideo_signaling_channel(name, attributes = {})
          resource = KinesisVideo::SignalingChannel.new(
            name: name,
            synthesizer: synthesizer,
            attributes: KinesisVideo::SignalingChannel::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end
      end
    end
  end
end