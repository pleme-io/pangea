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

require_relative 'encoder_settings/audio_descriptions'
require_relative 'encoder_settings/output_groups'
require_relative 'encoder_settings/video_descriptions'

module Pangea
  module Resources
    module AWS
      module MediaLiveChannel
        class DSLBuilder
          # Encoder settings DSL building for MediaLive Channel
          module EncoderSettings
            include AudioDescriptions
            include OutputGroups
            include VideoDescriptions

            def build_encoder_settings(ctx)
              build_audio_descriptions(ctx, attrs.encoder_settings[:audio_descriptions])
              build_output_groups(ctx, attrs.encoder_settings[:output_groups])
              build_timecode_config(ctx, attrs.encoder_settings[:timecode_config])
              build_video_descriptions(ctx, attrs.encoder_settings[:video_descriptions])
            end

            private

            def build_timecode_config(ctx, config)
              ctx.timecode_config do
                source config[:source]
                sync_threshold config[:sync_threshold] if config[:sync_threshold]
              end
            end
          end
        end
      end
    end
  end
end
