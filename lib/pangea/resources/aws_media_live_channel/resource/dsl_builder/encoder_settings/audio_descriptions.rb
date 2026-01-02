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
          # Audio descriptions DSL building for MediaLive Channel
          module AudioDescriptions
            AAC_ATTRS = %i[bitrate coding_mode input_type profile rate_control_mode raw_format sample_rate spec vbr_quality].freeze
            AC3_ATTRS = %i[bitrate bitstream_mode coding_mode dialnorm drc_profile lfe_filter metadata_control].freeze
            EAC3_ATTRS = %i[
              attenuation_control bitrate bitstream_mode coding_mode dc_filter dialnorm
              drc_line drc_rf lfe_control lfe_filter metadata_control passthrough_control
              phase_control stereo_downmix surround_ex_mode surround_mode
            ].freeze

            private

            def build_audio_descriptions(ctx, audio_descs)
              audio_descs.each do |audio_desc|
                ctx.audio_descriptions do
                  audio_selector_name audio_desc[:audio_selector_name]
                  audio_type audio_desc[:audio_type] if audio_desc[:audio_type]
                  audio_type_control audio_desc[:audio_type_control] if audio_desc[:audio_type_control]
                  language_code audio_desc[:language_code] if audio_desc[:language_code]
                  language_code_control audio_desc[:language_code_control] if audio_desc[:language_code_control]
                  name audio_desc[:name]
                  stream_name audio_desc[:stream_name] if audio_desc[:stream_name]

                  build_audio_codec_settings(self, audio_desc[:codec_settings]) if audio_desc[:codec_settings]
                  build_remix_settings(self, audio_desc[:remix_settings]) if audio_desc[:remix_settings]
                end
              end
            end

            def build_audio_codec_settings(ctx, codec_settings)
              ctx.codec_settings do
                build_aac_settings(self, codec_settings[:aac_settings]) if codec_settings[:aac_settings]
                build_ac3_settings(self, codec_settings[:ac3_settings]) if codec_settings[:ac3_settings]
                build_eac3_settings(self, codec_settings[:eac3_settings]) if codec_settings[:eac3_settings]
              end
            end

            def build_aac_settings(ctx, aac)
              ctx.aac_settings do
                AAC_ATTRS.each { |attr| public_send(attr, aac[attr]) if aac[attr] }
              end
            end

            def build_ac3_settings(ctx, ac3)
              ctx.ac3_settings do
                AC3_ATTRS.each { |attr| public_send(attr, ac3[attr]) if ac3[attr] }
              end
            end

            def build_eac3_settings(ctx, eac3)
              ctx.eac3_settings do
                EAC3_ATTRS.each { |attr| public_send(attr, eac3[attr]) if eac3[attr] }
              end
            end

            def build_remix_settings(ctx, remix)
              ctx.remix_settings do
                channels_in remix[:channels_in] if remix[:channels_in]
                channels_out remix[:channels_out] if remix[:channels_out]

                remix[:channel_mappings].each do |channel_mapping|
                  channel_mappings do
                    output_channel channel_mapping[:output_channel]

                    channel_mapping[:input_channel_levels].each do |input_level|
                      input_channel_levels do
                        gain input_level[:gain]
                        input_channel input_level[:input_channel]
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
