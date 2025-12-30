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
      module MediaLiveChannel
        class DSLBuilder
          # Video descriptions DSL building for MediaLive Channel
          module VideoDescriptions
            H264_ATTRS = %i[
              adaptive_quantization afd_signaling bitrate buf_fill_pct buf_size
              color_metadata entropy_encoding fixed_afd flicker_aq force_field_pictures
              framerate_control framerate_denominator framerate_numerator gop_b_reference
              gop_closed_cadence gop_num_b_frames gop_size gop_size_units level
              look_ahead_rate_control max_bitrate min_i_interval num_ref_frames par_control
              par_denominator par_numerator profile quality_level qvbr_quality_level
              rate_control_mode scan_type scene_change_detect slices softness spatial_aq
              subgop_length syntax temporal_aq timecode_insertion
            ].freeze

            H265_ATTRS = %i[
              adaptive_quantization afd_signaling alternative_transfer_function bitrate
              buf_size color_metadata fixed_afd flicker_aq framerate_control
              framerate_denominator framerate_numerator gop_closed_cadence gop_size
              gop_size_units level look_ahead_rate_control max_bitrate min_i_interval
              par_control par_denominator par_numerator profile qvbr_quality_level
              rate_control_mode scan_type scene_change_detect slices tier timecode_insertion
            ].freeze

            private

            def build_video_descriptions(ctx, video_descs)
              return unless video_descs

              video_descs.each do |video_desc|
                ctx.video_descriptions do
                  height video_desc[:height] if video_desc[:height]
                  name video_desc[:name]
                  respond_to_afd video_desc[:respond_to_afd] if video_desc[:respond_to_afd]
                  scaling_behavior video_desc[:scaling_behavior] if video_desc[:scaling_behavior]
                  sharpness video_desc[:sharpness] if video_desc[:sharpness]
                  width video_desc[:width] if video_desc[:width]

                  build_video_codec_settings(self, video_desc[:codec_settings]) if video_desc[:codec_settings]
                end
              end
            end

            def build_video_codec_settings(ctx, codec_settings)
              ctx.codec_settings do
                build_h264_settings(self, codec_settings[:h264_settings]) if codec_settings[:h264_settings]
                build_h265_settings(self, codec_settings[:h265_settings]) if codec_settings[:h265_settings]
              end
            end

            def build_h264_settings(ctx, h264)
              ctx.h264_settings do
                H264_ATTRS.each { |attr| public_send(attr, h264[attr]) if h264[attr] }
              end
            end

            def build_h265_settings(ctx, h265)
              ctx.h265_settings do
                H265_ATTRS.each { |attr| public_send(attr, h265[attr]) if h265[attr] }
              end
            end
          end
        end
      end
    end
  end
end
