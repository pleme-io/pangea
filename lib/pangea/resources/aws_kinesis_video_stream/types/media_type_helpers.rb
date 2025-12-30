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

module Pangea
  module Resources
    module AWS
      module Types
        # Media type helpers for Kinesis Video Stream
        module MediaTypeHelpers
          # Common media type constants
          MEDIA_TYPES = {
            h264: "video/h264",
            h265: "video/h265",
            hevc: "video/hevc",
            vp8: "video/vp8",
            vp9: "video/vp9",
            aac: "audio/aac",
            opus: "audio/opus",
            pcm: "audio/pcm",
            mp3: "audio/mpeg"
          }.freeze

          def self.media_types
            MEDIA_TYPES
          end

          def is_h264_video?
            media_type.include?('h264')
          end

          def is_h265_video?
            media_type.include?('h265') || media_type.include?('hevc')
          end

          def is_audio_stream?
            media_type.start_with?('audio/')
          end

          def is_video_stream?
            media_type.start_with?('video/')
          end
        end
      end
    end
  end
end
