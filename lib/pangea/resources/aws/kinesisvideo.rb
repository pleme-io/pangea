# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


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