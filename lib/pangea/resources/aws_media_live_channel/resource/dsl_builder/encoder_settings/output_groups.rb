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
          # Output groups DSL building for MediaLive Channel
          module OutputGroups
            HLS_ATTRS = %i[
              ad_markers base_url_content base_url_manifest client_cache codec_specification
              constant_iv directory_structure discontinuity_tags encryption_type
              hls_id3_segment_tagging i_frame_only_playlists incomplete_segment_behavior
              index_n_segments input_loss_action iv_in_manifest iv_source keep_segments
              manifest_compression manifest_duration_format min_segment_length mode
              output_selection program_date_time program_date_time_period redundant_manifest
              segment_length segmentation_mode segments_per_subdirectory stream_inf_resolution
              timed_metadata_id3_frame timed_metadata_id3_period timestamp_delta_milliseconds
              ts_file_mode
            ].freeze

            RTMP_GROUP_ATTRS = %i[
              ad_markers authentication_scheme cache_full_behavior cache_length
              caption_data input_loss_action restart_delay
            ].freeze

            M3U8_ATTRS = %i[
              audio_frames_per_pes audio_pids nielsen_id3_behavior pat_interval
              pcr_control pcr_period pmt_interval program_num scte35_behavior
              timed_metadata_behavior transport_stream_id video_pid
            ].freeze

            private

            def build_output_groups(ctx, output_groups_config)
              output_groups_config.each do |output_group|
                ctx.output_groups do
                  name output_group[:name] if output_group[:name]
                  build_output_group_settings(self, output_group[:output_group_settings])
                  build_outputs(self, output_group[:outputs])
                end
              end
            end

            def build_output_group_settings(ctx, settings)
              ctx.output_group_settings do
                build_archive_group_settings(self, settings[:archive_group_settings]) if settings[:archive_group_settings]
                build_hls_group_settings(self, settings[:hls_group_settings]) if settings[:hls_group_settings]
                build_media_package_group_settings(self, settings[:media_package_group_settings]) if settings[:media_package_group_settings]
                build_rtmp_group_settings(self, settings[:rtmp_group_settings]) if settings[:rtmp_group_settings]
                build_udp_group_settings(self, settings[:udp_group_settings]) if settings[:udp_group_settings]
              end
            end

            def build_archive_group_settings(ctx, archive)
              ctx.archive_group_settings do
                destination { destination_ref_id archive[:destination][:destination_ref_id] }
                rollover_interval archive[:rollover_interval] if archive[:rollover_interval]
              end
            end

            def build_hls_group_settings(ctx, hls)
              ctx.hls_group_settings do
                destination { destination_ref_id hls[:destination][:destination_ref_id] }
                HLS_ATTRS.each { |attr| public_send(attr, hls[attr]) if hls[attr] }
              end
            end

            def build_media_package_group_settings(ctx, mp)
              ctx.media_package_group_settings do
                destination { destination_ref_id mp[:destination][:destination_ref_id] }
              end
            end

            def build_rtmp_group_settings(ctx, rtmp)
              ctx.rtmp_group_settings do
                RTMP_GROUP_ATTRS.each { |attr| public_send(attr, rtmp[attr]) if rtmp[attr] }
              end
            end

            def build_udp_group_settings(ctx, udp)
              ctx.udp_group_settings do
                input_loss_action udp[:input_loss_action] if udp[:input_loss_action]
                timed_metadata_id3_frame udp[:timed_metadata_id3_frame] if udp[:timed_metadata_id3_frame]
                timed_metadata_id3_period udp[:timed_metadata_id3_period] if udp[:timed_metadata_id3_period]
              end
            end

            def build_outputs(ctx, outputs_config)
              outputs_config.each do |output_config|
                ctx.outputs do
                  audio_description_names output_config[:audio_description_names] if output_config[:audio_description_names]
                  caption_description_names output_config[:caption_description_names] if output_config[:caption_description_names]
                  output_name output_config[:output_name] if output_config[:output_name]
                  video_description_name output_config[:video_description_name] if output_config[:video_description_name]
                  build_output_settings(self, output_config[:output_settings])
                end
              end
            end

            def build_output_settings(ctx, settings)
              ctx.output_settings do
                build_hls_output_settings(self, settings[:hls_output_settings]) if settings[:hls_output_settings]
                build_rtmp_output_settings(self, settings[:rtmp_output_settings]) if settings[:rtmp_output_settings]
              end
            end

            def build_hls_output_settings(ctx, hls)
              ctx.hls_output_settings do
                h265_packaging_type hls[:h265_packaging_type] if hls[:h265_packaging_type]
                name_modifier hls[:name_modifier] if hls[:name_modifier]
                segment_modifier hls[:segment_modifier] if hls[:segment_modifier]
                build_hls_settings(self, hls[:hls_settings]) if hls[:hls_settings]
              end
            end

            def build_hls_settings(ctx, hls_settings)
              ctx.hls_settings do
                build_standard_hls_settings(self, hls_settings[:standard_hls_settings]) if hls_settings[:standard_hls_settings]
              end
            end

            def build_standard_hls_settings(ctx, standard)
              ctx.standard_hls_settings do
                audio_rendition_sets standard[:audio_rendition_sets] if standard[:audio_rendition_sets]
                build_m3u8_settings(self, standard[:m3u8_settings]) if standard[:m3u8_settings]
              end
            end

            def build_m3u8_settings(ctx, m3u8)
              ctx.m3u8_settings do
                M3U8_ATTRS.each { |attr| public_send(attr, m3u8[attr]) if m3u8[attr] }
              end
            end

            def build_rtmp_output_settings(ctx, rtmp)
              ctx.rtmp_output_settings do
                certificate_mode rtmp[:certificate_mode] if rtmp[:certificate_mode]
                connection_retry_interval rtmp[:connection_retry_interval] if rtmp[:connection_retry_interval]
                num_retries rtmp[:num_retries] if rtmp[:num_retries]
                destination { destination_ref_id rtmp[:destination][:destination_ref_id] }
              end
            end
          end
        end
      end
    end
  end
end
