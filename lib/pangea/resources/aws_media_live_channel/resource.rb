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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_media_live_channel/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS MediaLive Channel with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] MediaLive channel attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_media_live_channel(name, attributes = {})
        # Validate attributes using dry-struct
        channel_attrs = Types::MediaLiveChannelAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_medialive_channel, name) do
          # Basic configuration
          name channel_attrs.name
          channel_class channel_attrs.channel_class
          
          # Input attachments
          channel_attrs.input_attachments.each do |input_attachment|
            input_attachments do
              input_attachment_name input_attachment[:input_attachment_name]
              input_id input_attachment[:input_id]
              
              # Input settings
              if input_attachment[:input_settings]
                input_settings do
                  # Audio selectors
                  if input_attachment[:input_settings][:audio_selectors]
                    input_attachment[:input_settings][:audio_selectors].each do |audio_selector|
                      audio_selectors do
                        name audio_selector[:name]
                        
                        if audio_selector[:selector_settings]
                          selector_settings do
                            if audio_selector[:selector_settings][:audio_language_selection]
                              audio_language_selection do
                                language_code audio_selector[:selector_settings][:audio_language_selection][:language_code]
                                language_selection_policy audio_selector[:selector_settings][:audio_language_selection][:language_selection_policy] if audio_selector[:selector_settings][:audio_language_selection][:language_selection_policy]
                              end
                            end
                            
                            if audio_selector[:selector_settings][:audio_pid_selection]
                              audio_pid_selection do
                                pid audio_selector[:selector_settings][:audio_pid_selection][:pid]
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                  
                  # Caption selectors
                  if input_attachment[:input_settings][:caption_selectors]
                    input_attachment[:input_settings][:caption_selectors].each do |caption_selector|
                      caption_selectors do
                        name caption_selector[:name]
                        language_code caption_selector[:language_code] if caption_selector[:language_code]
                        
                        if caption_selector[:selector_settings]
                          selector_settings do
                            # Various caption source settings would go here
                          end
                        end
                      end
                    end
                  end
                  
                  # Other input settings
                  deblock_filter input_attachment[:input_settings][:deblock_filter] if input_attachment[:input_settings][:deblock_filter]
                  denoise_filter input_attachment[:input_settings][:denoise_filter] if input_attachment[:input_settings][:denoise_filter]
                  filter_strength input_attachment[:input_settings][:filter_strength] if input_attachment[:input_settings][:filter_strength]
                  input_filter input_attachment[:input_settings][:input_filter] if input_attachment[:input_settings][:input_filter]
                  
                  # Network input settings
                  if input_attachment[:input_settings][:network_input_settings]
                    network_input_settings do
                      if input_attachment[:input_settings][:network_input_settings][:hls_input_settings]
                        hls_input_settings do
                          bandwidth input_attachment[:input_settings][:network_input_settings][:hls_input_settings][:bandwidth] if input_attachment[:input_settings][:network_input_settings][:hls_input_settings][:bandwidth]
                          buffer_segments input_attachment[:input_settings][:network_input_settings][:hls_input_settings][:buffer_segments] if input_attachment[:input_settings][:network_input_settings][:hls_input_settings][:buffer_segments]
                          retries input_attachment[:input_settings][:network_input_settings][:hls_input_settings][:retries] if input_attachment[:input_settings][:network_input_settings][:hls_input_settings][:retries]
                          retry_interval input_attachment[:input_settings][:network_input_settings][:hls_input_settings][:retry_interval] if input_attachment[:input_settings][:network_input_settings][:hls_input_settings][:retry_interval]
                        end
                      end
                      
                      server_validation input_attachment[:input_settings][:network_input_settings][:server_validation] if input_attachment[:input_settings][:network_input_settings][:server_validation]
                    end
                  end
                  
                  smpte2038_data_preference input_attachment[:input_settings][:smpte2038_data_preference] if input_attachment[:input_settings][:smpte2038_data_preference]
                  source_end_behavior input_attachment[:input_settings][:source_end_behavior] if input_attachment[:input_settings][:source_end_behavior]
                  
                  # Video selector
                  if input_attachment[:input_settings][:video_selector]
                    video_selector do
                      color_space input_attachment[:input_settings][:video_selector][:color_space] if input_attachment[:input_settings][:video_selector][:color_space]
                      color_space_usage input_attachment[:input_settings][:video_selector][:color_space_usage] if input_attachment[:input_settings][:video_selector][:color_space_usage]
                      
                      if input_attachment[:input_settings][:video_selector][:selector_settings]
                        selector_settings do
                          if input_attachment[:input_settings][:video_selector][:selector_settings][:video_selector_pid]
                            video_selector_pid do
                              pid input_attachment[:input_settings][:video_selector][:selector_settings][:video_selector_pid][:pid]
                            end
                          end
                          
                          if input_attachment[:input_settings][:video_selector][:selector_settings][:video_selector_program_id]
                            video_selector_program_id do
                              program_id input_attachment[:input_settings][:video_selector][:selector_settings][:video_selector_program_id][:program_id]
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
          
          # Encoder settings
          encoder_settings do
            # Audio descriptions
            channel_attrs.encoder_settings[:audio_descriptions].each do |audio_desc|
              audio_descriptions do
                audio_selector_name audio_desc[:audio_selector_name]
                audio_type audio_desc[:audio_type] if audio_desc[:audio_type]
                audio_type_control audio_desc[:audio_type_control] if audio_desc[:audio_type_control]
                language_code audio_desc[:language_code] if audio_desc[:language_code]
                language_code_control audio_desc[:language_code_control] if audio_desc[:language_code_control]
                name audio_desc[:name]
                stream_name audio_desc[:stream_name] if audio_desc[:stream_name]
                
                # Codec settings
                if audio_desc[:codec_settings]
                  codec_settings do
                    if audio_desc[:codec_settings][:aac_settings]
                      aac_settings do
                        bitrate audio_desc[:codec_settings][:aac_settings][:bitrate] if audio_desc[:codec_settings][:aac_settings][:bitrate]
                        coding_mode audio_desc[:codec_settings][:aac_settings][:coding_mode] if audio_desc[:codec_settings][:aac_settings][:coding_mode]
                        input_type audio_desc[:codec_settings][:aac_settings][:input_type] if audio_desc[:codec_settings][:aac_settings][:input_type]
                        profile audio_desc[:codec_settings][:aac_settings][:profile] if audio_desc[:codec_settings][:aac_settings][:profile]
                        rate_control_mode audio_desc[:codec_settings][:aac_settings][:rate_control_mode] if audio_desc[:codec_settings][:aac_settings][:rate_control_mode]
                        raw_format audio_desc[:codec_settings][:aac_settings][:raw_format] if audio_desc[:codec_settings][:aac_settings][:raw_format]
                        sample_rate audio_desc[:codec_settings][:aac_settings][:sample_rate] if audio_desc[:codec_settings][:aac_settings][:sample_rate]
                        spec audio_desc[:codec_settings][:aac_settings][:spec] if audio_desc[:codec_settings][:aac_settings][:spec]
                        vbr_quality audio_desc[:codec_settings][:aac_settings][:vbr_quality] if audio_desc[:codec_settings][:aac_settings][:vbr_quality]
                      end
                    end
                    
                    if audio_desc[:codec_settings][:ac3_settings]
                      ac3_settings do
                        bitrate audio_desc[:codec_settings][:ac3_settings][:bitrate] if audio_desc[:codec_settings][:ac3_settings][:bitrate]
                        bitstream_mode audio_desc[:codec_settings][:ac3_settings][:bitstream_mode] if audio_desc[:codec_settings][:ac3_settings][:bitstream_mode]
                        coding_mode audio_desc[:codec_settings][:ac3_settings][:coding_mode] if audio_desc[:codec_settings][:ac3_settings][:coding_mode]
                        dialnorm audio_desc[:codec_settings][:ac3_settings][:dialnorm] if audio_desc[:codec_settings][:ac3_settings][:dialnorm]
                        drc_profile audio_desc[:codec_settings][:ac3_settings][:drc_profile] if audio_desc[:codec_settings][:ac3_settings][:drc_profile]
                        lfe_filter audio_desc[:codec_settings][:ac3_settings][:lfe_filter] if audio_desc[:codec_settings][:ac3_settings][:lfe_filter]
                        metadata_control audio_desc[:codec_settings][:ac3_settings][:metadata_control] if audio_desc[:codec_settings][:ac3_settings][:metadata_control]
                      end
                    end
                    
                    if audio_desc[:codec_settings][:eac3_settings]
                      eac3_settings do
                        attenuation_control audio_desc[:codec_settings][:eac3_settings][:attenuation_control] if audio_desc[:codec_settings][:eac3_settings][:attenuation_control]
                        bitrate audio_desc[:codec_settings][:eac3_settings][:bitrate] if audio_desc[:codec_settings][:eac3_settings][:bitrate]
                        bitstream_mode audio_desc[:codec_settings][:eac3_settings][:bitstream_mode] if audio_desc[:codec_settings][:eac3_settings][:bitstream_mode]
                        coding_mode audio_desc[:codec_settings][:eac3_settings][:coding_mode] if audio_desc[:codec_settings][:eac3_settings][:coding_mode]
                        dc_filter audio_desc[:codec_settings][:eac3_settings][:dc_filter] if audio_desc[:codec_settings][:eac3_settings][:dc_filter]
                        dialnorm audio_desc[:codec_settings][:eac3_settings][:dialnorm] if audio_desc[:codec_settings][:eac3_settings][:dialnorm]
                        drc_line audio_desc[:codec_settings][:eac3_settings][:drc_line] if audio_desc[:codec_settings][:eac3_settings][:drc_line]
                        drc_rf audio_desc[:codec_settings][:eac3_settings][:drc_rf] if audio_desc[:codec_settings][:eac3_settings][:drc_rf]
                        lfe_control audio_desc[:codec_settings][:eac3_settings][:lfe_control] if audio_desc[:codec_settings][:eac3_settings][:lfe_control]
                        lfe_filter audio_desc[:codec_settings][:eac3_settings][:lfe_filter] if audio_desc[:codec_settings][:eac3_settings][:lfe_filter]
                        metadata_control audio_desc[:codec_settings][:eac3_settings][:metadata_control] if audio_desc[:codec_settings][:eac3_settings][:metadata_control]
                        passthrough_control audio_desc[:codec_settings][:eac3_settings][:passthrough_control] if audio_desc[:codec_settings][:eac3_settings][:passthrough_control]
                        phase_control audio_desc[:codec_settings][:eac3_settings][:phase_control] if audio_desc[:codec_settings][:eac3_settings][:phase_control]
                        stereo_downmix audio_desc[:codec_settings][:eac3_settings][:stereo_downmix] if audio_desc[:codec_settings][:eac3_settings][:stereo_downmix]
                        surround_ex_mode audio_desc[:codec_settings][:eac3_settings][:surround_ex_mode] if audio_desc[:codec_settings][:eac3_settings][:surround_ex_mode]
                        surround_mode audio_desc[:codec_settings][:eac3_settings][:surround_mode] if audio_desc[:codec_settings][:eac3_settings][:surround_mode]
                      end
                    end
                  end
                end
                
                # Remix settings
                if audio_desc[:remix_settings]
                  remix_settings do
                    channels_in audio_desc[:remix_settings][:channels_in] if audio_desc[:remix_settings][:channels_in]
                    channels_out audio_desc[:remix_settings][:channels_out] if audio_desc[:remix_settings][:channels_out]
                    
                    audio_desc[:remix_settings][:channel_mappings].each do |channel_mapping|
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
            
            # Output groups
            channel_attrs.encoder_settings[:output_groups].each do |output_group|
              output_groups do
                name output_group[:name] if output_group[:name]
                
                # Output group settings
                output_group_settings do
                  if output_group[:output_group_settings][:archive_group_settings]
                    archive_group_settings do
                      destination do
                        destination_ref_id output_group[:output_group_settings][:archive_group_settings][:destination][:destination_ref_id]
                      end
                      rollover_interval output_group[:output_group_settings][:archive_group_settings][:rollover_interval] if output_group[:output_group_settings][:archive_group_settings][:rollover_interval]
                    end
                  end
                  
                  if output_group[:output_group_settings][:hls_group_settings]
                    hls_group_settings do
                      destination do
                        destination_ref_id output_group[:output_group_settings][:hls_group_settings][:destination][:destination_ref_id]
                      end
                      
                      # HLS-specific settings
                      ad_markers output_group[:output_group_settings][:hls_group_settings][:ad_markers] if output_group[:output_group_settings][:hls_group_settings][:ad_markers]
                      base_url_content output_group[:output_group_settings][:hls_group_settings][:base_url_content] if output_group[:output_group_settings][:hls_group_settings][:base_url_content]
                      base_url_manifest output_group[:output_group_settings][:hls_group_settings][:base_url_manifest] if output_group[:output_group_settings][:hls_group_settings][:base_url_manifest]
                      client_cache output_group[:output_group_settings][:hls_group_settings][:client_cache] if output_group[:output_group_settings][:hls_group_settings][:client_cache]
                      codec_specification output_group[:output_group_settings][:hls_group_settings][:codec_specification] if output_group[:output_group_settings][:hls_group_settings][:codec_specification]
                      constant_iv output_group[:output_group_settings][:hls_group_settings][:constant_iv] if output_group[:output_group_settings][:hls_group_settings][:constant_iv]
                      directory_structure output_group[:output_group_settings][:hls_group_settings][:directory_structure] if output_group[:output_group_settings][:hls_group_settings][:directory_structure]
                      discontinuity_tags output_group[:output_group_settings][:hls_group_settings][:discontinuity_tags] if output_group[:output_group_settings][:hls_group_settings][:discontinuity_tags]
                      encryption_type output_group[:output_group_settings][:hls_group_settings][:encryption_type] if output_group[:output_group_settings][:hls_group_settings][:encryption_type]
                      hls_id3_segment_tagging output_group[:output_group_settings][:hls_group_settings][:hls_id3_segment_tagging] if output_group[:output_group_settings][:hls_group_settings][:hls_id3_segment_tagging]
                      i_frame_only_playlists output_group[:output_group_settings][:hls_group_settings][:i_frame_only_playlists] if output_group[:output_group_settings][:hls_group_settings][:i_frame_only_playlists]
                      incomplete_segment_behavior output_group[:output_group_settings][:hls_group_settings][:incomplete_segment_behavior] if output_group[:output_group_settings][:hls_group_settings][:incomplete_segment_behavior]
                      index_n_segments output_group[:output_group_settings][:hls_group_settings][:index_n_segments] if output_group[:output_group_settings][:hls_group_settings][:index_n_segments]
                      input_loss_action output_group[:output_group_settings][:hls_group_settings][:input_loss_action] if output_group[:output_group_settings][:hls_group_settings][:input_loss_action]
                      iv_in_manifest output_group[:output_group_settings][:hls_group_settings][:iv_in_manifest] if output_group[:output_group_settings][:hls_group_settings][:iv_in_manifest]
                      iv_source output_group[:output_group_settings][:hls_group_settings][:iv_source] if output_group[:output_group_settings][:hls_group_settings][:iv_source]
                      keep_segments output_group[:output_group_settings][:hls_group_settings][:keep_segments] if output_group[:output_group_settings][:hls_group_settings][:keep_segments]
                      manifest_compression output_group[:output_group_settings][:hls_group_settings][:manifest_compression] if output_group[:output_group_settings][:hls_group_settings][:manifest_compression]
                      manifest_duration_format output_group[:output_group_settings][:hls_group_settings][:manifest_duration_format] if output_group[:output_group_settings][:hls_group_settings][:manifest_duration_format]
                      min_segment_length output_group[:output_group_settings][:hls_group_settings][:min_segment_length] if output_group[:output_group_settings][:hls_group_settings][:min_segment_length]
                      mode output_group[:output_group_settings][:hls_group_settings][:mode] if output_group[:output_group_settings][:hls_group_settings][:mode]
                      output_selection output_group[:output_group_settings][:hls_group_settings][:output_selection] if output_group[:output_group_settings][:hls_group_settings][:output_selection]
                      program_date_time output_group[:output_group_settings][:hls_group_settings][:program_date_time] if output_group[:output_group_settings][:hls_group_settings][:program_date_time]
                      program_date_time_period output_group[:output_group_settings][:hls_group_settings][:program_date_time_period] if output_group[:output_group_settings][:hls_group_settings][:program_date_time_period]
                      redundant_manifest output_group[:output_group_settings][:hls_group_settings][:redundant_manifest] if output_group[:output_group_settings][:hls_group_settings][:redundant_manifest]
                      segment_length output_group[:output_group_settings][:hls_group_settings][:segment_length] if output_group[:output_group_settings][:hls_group_settings][:segment_length]
                      segmentation_mode output_group[:output_group_settings][:hls_group_settings][:segmentation_mode] if output_group[:output_group_settings][:hls_group_settings][:segmentation_mode]
                      segments_per_subdirectory output_group[:output_group_settings][:hls_group_settings][:segments_per_subdirectory] if output_group[:output_group_settings][:hls_group_settings][:segments_per_subdirectory]
                      stream_inf_resolution output_group[:output_group_settings][:hls_group_settings][:stream_inf_resolution] if output_group[:output_group_settings][:hls_group_settings][:stream_inf_resolution]
                      timed_metadata_id3_frame output_group[:output_group_settings][:hls_group_settings][:timed_metadata_id3_frame] if output_group[:output_group_settings][:hls_group_settings][:timed_metadata_id3_frame]
                      timed_metadata_id3_period output_group[:output_group_settings][:hls_group_settings][:timed_metadata_id3_period] if output_group[:output_group_settings][:hls_group_settings][:timed_metadata_id3_period]
                      timestamp_delta_milliseconds output_group[:output_group_settings][:hls_group_settings][:timestamp_delta_milliseconds] if output_group[:output_group_settings][:hls_group_settings][:timestamp_delta_milliseconds]
                      ts_file_mode output_group[:output_group_settings][:hls_group_settings][:ts_file_mode] if output_group[:output_group_settings][:hls_group_settings][:ts_file_mode]
                    end
                  end
                  
                  if output_group[:output_group_settings][:media_package_group_settings]
                    media_package_group_settings do
                      destination do
                        destination_ref_id output_group[:output_group_settings][:media_package_group_settings][:destination][:destination_ref_id]
                      end
                    end
                  end
                  
                  if output_group[:output_group_settings][:rtmp_group_settings]
                    rtmp_group_settings do
                      ad_markers output_group[:output_group_settings][:rtmp_group_settings][:ad_markers] if output_group[:output_group_settings][:rtmp_group_settings][:ad_markers]
                      authentication_scheme output_group[:output_group_settings][:rtmp_group_settings][:authentication_scheme] if output_group[:output_group_settings][:rtmp_group_settings][:authentication_scheme]
                      cache_full_behavior output_group[:output_group_settings][:rtmp_group_settings][:cache_full_behavior] if output_group[:output_group_settings][:rtmp_group_settings][:cache_full_behavior]
                      cache_length output_group[:output_group_settings][:rtmp_group_settings][:cache_length] if output_group[:output_group_settings][:rtmp_group_settings][:cache_length]
                      caption_data output_group[:output_group_settings][:rtmp_group_settings][:caption_data] if output_group[:output_group_settings][:rtmp_group_settings][:caption_data]
                      input_loss_action output_group[:output_group_settings][:rtmp_group_settings][:input_loss_action] if output_group[:output_group_settings][:rtmp_group_settings][:input_loss_action]
                      restart_delay output_group[:output_group_settings][:rtmp_group_settings][:restart_delay] if output_group[:output_group_settings][:rtmp_group_settings][:restart_delay]
                    end
                  end
                  
                  if output_group[:output_group_settings][:udp_group_settings]
                    udp_group_settings do
                      input_loss_action output_group[:output_group_settings][:udp_group_settings][:input_loss_action] if output_group[:output_group_settings][:udp_group_settings][:input_loss_action]
                      timed_metadata_id3_frame output_group[:output_group_settings][:udp_group_settings][:timed_metadata_id3_frame] if output_group[:output_group_settings][:udp_group_settings][:timed_metadata_id3_frame]
                      timed_metadata_id3_period output_group[:output_group_settings][:udp_group_settings][:timed_metadata_id3_period] if output_group[:output_group_settings][:udp_group_settings][:timed_metadata_id3_period]
                    end
                  end
                end
                
                # Outputs
                output_group[:outputs].each do |output_config|
                  outputs do
                    audio_description_names output_config[:audio_description_names] if output_config[:audio_description_names]
                    caption_description_names output_config[:caption_description_names] if output_config[:caption_description_names]
                    output_name output_config[:output_name] if output_config[:output_name]
                    video_description_name output_config[:video_description_name] if output_config[:video_description_name]
                    
                    # Output settings
                    output_settings do
                      if output_config[:output_settings][:hls_output_settings]
                        hls_output_settings do
                          h265_packaging_type output_config[:output_settings][:hls_output_settings][:h265_packaging_type] if output_config[:output_settings][:hls_output_settings][:h265_packaging_type]
                          name_modifier output_config[:output_settings][:hls_output_settings][:name_modifier] if output_config[:output_settings][:hls_output_settings][:name_modifier]
                          segment_modifier output_config[:output_settings][:hls_output_settings][:segment_modifier] if output_config[:output_settings][:hls_output_settings][:segment_modifier]
                          
                          # HLS settings
                          hls_settings do
                            if output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings]
                              standard_hls_settings do
                                audio_rendition_sets output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:audio_rendition_sets] if output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:audio_rendition_sets]
                                
                                m3u8_settings do
                                  audio_frames_per_pes output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:audio_frames_per_pes] if output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:audio_frames_per_pes]
                                  audio_pids output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:audio_pids] if output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:audio_pids]
                                  nielsen_id3_behavior output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:nielsen_id3_behavior] if output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:nielsen_id3_behavior]
                                  pat_interval output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:pat_interval] if output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:pat_interval]
                                  pcr_control output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:pcr_control] if output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:pcr_control]
                                  pcr_period output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:pcr_period] if output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:pcr_period]
                                  pmt_interval output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:pmt_interval] if output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:pmt_interval]
                                  program_num output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:program_num] if output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:program_num]
                                  scte35_behavior output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:scte35_behavior] if output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:scte35_behavior]
                                  timed_metadata_behavior output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:timed_metadata_behavior] if output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:timed_metadata_behavior]
                                  transport_stream_id output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:transport_stream_id] if output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:transport_stream_id]
                                  video_pid output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:video_pid] if output_config[:output_settings][:hls_output_settings][:hls_settings][:standard_hls_settings][:m3u8_settings][:video_pid]
                                end
                              end
                            end
                          end
                        end
                      end
                      
                      if output_config[:output_settings][:rtmp_output_settings]
                        rtmp_output_settings do
                          certificate_mode output_config[:output_settings][:rtmp_output_settings][:certificate_mode] if output_config[:output_settings][:rtmp_output_settings][:certificate_mode]
                          connection_retry_interval output_config[:output_settings][:rtmp_output_settings][:connection_retry_interval] if output_config[:output_settings][:rtmp_output_settings][:connection_retry_interval]
                          num_retries output_config[:output_settings][:rtmp_output_settings][:num_retries] if output_config[:output_settings][:rtmp_output_settings][:num_retries]
                          
                          destination do
                            destination_ref_id output_config[:output_settings][:rtmp_output_settings][:destination][:destination_ref_id]
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
            
            # Timecode configuration
            timecode_config do
              source channel_attrs.encoder_settings[:timecode_config][:source]
              sync_threshold channel_attrs.encoder_settings[:timecode_config][:sync_threshold] if channel_attrs.encoder_settings[:timecode_config][:sync_threshold]
            end
            
            # Video descriptions
            if channel_attrs.encoder_settings[:video_descriptions]
              channel_attrs.encoder_settings[:video_descriptions].each do |video_desc|
                video_descriptions do
                  height video_desc[:height] if video_desc[:height]
                  name video_desc[:name]
                  respond_to_afd video_desc[:respond_to_afd] if video_desc[:respond_to_afd]
                  scaling_behavior video_desc[:scaling_behavior] if video_desc[:scaling_behavior]
                  sharpness video_desc[:sharpness] if video_desc[:sharpness]
                  width video_desc[:width] if video_desc[:width]
                  
                  # Codec settings
                  if video_desc[:codec_settings]
                    codec_settings do
                      if video_desc[:codec_settings][:h264_settings]
                        h264_settings do
                          adaptive_quantization video_desc[:codec_settings][:h264_settings][:adaptive_quantization] if video_desc[:codec_settings][:h264_settings][:adaptive_quantization]
                          afd_signaling video_desc[:codec_settings][:h264_settings][:afd_signaling] if video_desc[:codec_settings][:h264_settings][:afd_signaling]
                          bitrate video_desc[:codec_settings][:h264_settings][:bitrate] if video_desc[:codec_settings][:h264_settings][:bitrate]
                          buf_fill_pct video_desc[:codec_settings][:h264_settings][:buf_fill_pct] if video_desc[:codec_settings][:h264_settings][:buf_fill_pct]
                          buf_size video_desc[:codec_settings][:h264_settings][:buf_size] if video_desc[:codec_settings][:h264_settings][:buf_size]
                          color_metadata video_desc[:codec_settings][:h264_settings][:color_metadata] if video_desc[:codec_settings][:h264_settings][:color_metadata]
                          entropy_encoding video_desc[:codec_settings][:h264_settings][:entropy_encoding] if video_desc[:codec_settings][:h264_settings][:entropy_encoding]
                          fixed_afd video_desc[:codec_settings][:h264_settings][:fixed_afd] if video_desc[:codec_settings][:h264_settings][:fixed_afd]
                          flicker_aq video_desc[:codec_settings][:h264_settings][:flicker_aq] if video_desc[:codec_settings][:h264_settings][:flicker_aq]
                          force_field_pictures video_desc[:codec_settings][:h264_settings][:force_field_pictures] if video_desc[:codec_settings][:h264_settings][:force_field_pictures]
                          framerate_control video_desc[:codec_settings][:h264_settings][:framerate_control] if video_desc[:codec_settings][:h264_settings][:framerate_control]
                          framerate_denominator video_desc[:codec_settings][:h264_settings][:framerate_denominator] if video_desc[:codec_settings][:h264_settings][:framerate_denominator]
                          framerate_numerator video_desc[:codec_settings][:h264_settings][:framerate_numerator] if video_desc[:codec_settings][:h264_settings][:framerate_numerator]
                          gop_b_reference video_desc[:codec_settings][:h264_settings][:gop_b_reference] if video_desc[:codec_settings][:h264_settings][:gop_b_reference]
                          gop_closed_cadence video_desc[:codec_settings][:h264_settings][:gop_closed_cadence] if video_desc[:codec_settings][:h264_settings][:gop_closed_cadence]
                          gop_num_b_frames video_desc[:codec_settings][:h264_settings][:gop_num_b_frames] if video_desc[:codec_settings][:h264_settings][:gop_num_b_frames]
                          gop_size video_desc[:codec_settings][:h264_settings][:gop_size] if video_desc[:codec_settings][:h264_settings][:gop_size]
                          gop_size_units video_desc[:codec_settings][:h264_settings][:gop_size_units] if video_desc[:codec_settings][:h264_settings][:gop_size_units]
                          level video_desc[:codec_settings][:h264_settings][:level] if video_desc[:codec_settings][:h264_settings][:level]
                          look_ahead_rate_control video_desc[:codec_settings][:h264_settings][:look_ahead_rate_control] if video_desc[:codec_settings][:h264_settings][:look_ahead_rate_control]
                          max_bitrate video_desc[:codec_settings][:h264_settings][:max_bitrate] if video_desc[:codec_settings][:h264_settings][:max_bitrate]
                          min_i_interval video_desc[:codec_settings][:h264_settings][:min_i_interval] if video_desc[:codec_settings][:h264_settings][:min_i_interval]
                          num_ref_frames video_desc[:codec_settings][:h264_settings][:num_ref_frames] if video_desc[:codec_settings][:h264_settings][:num_ref_frames]
                          par_control video_desc[:codec_settings][:h264_settings][:par_control] if video_desc[:codec_settings][:h264_settings][:par_control]
                          par_denominator video_desc[:codec_settings][:h264_settings][:par_denominator] if video_desc[:codec_settings][:h264_settings][:par_denominator]
                          par_numerator video_desc[:codec_settings][:h264_settings][:par_numerator] if video_desc[:codec_settings][:h264_settings][:par_numerator]
                          profile video_desc[:codec_settings][:h264_settings][:profile] if video_desc[:codec_settings][:h264_settings][:profile]
                          quality_level video_desc[:codec_settings][:h264_settings][:quality_level] if video_desc[:codec_settings][:h264_settings][:quality_level]
                          qvbr_quality_level video_desc[:codec_settings][:h264_settings][:qvbr_quality_level] if video_desc[:codec_settings][:h264_settings][:qvbr_quality_level]
                          rate_control_mode video_desc[:codec_settings][:h264_settings][:rate_control_mode] if video_desc[:codec_settings][:h264_settings][:rate_control_mode]
                          scan_type video_desc[:codec_settings][:h264_settings][:scan_type] if video_desc[:codec_settings][:h264_settings][:scan_type]
                          scene_change_detect video_desc[:codec_settings][:h264_settings][:scene_change_detect] if video_desc[:codec_settings][:h264_settings][:scene_change_detect]
                          slices video_desc[:codec_settings][:h264_settings][:slices] if video_desc[:codec_settings][:h264_settings][:slices]
                          softness video_desc[:codec_settings][:h264_settings][:softness] if video_desc[:codec_settings][:h264_settings][:softness]
                          spatial_aq video_desc[:codec_settings][:h264_settings][:spatial_aq] if video_desc[:codec_settings][:h264_settings][:spatial_aq]
                          subgop_length video_desc[:codec_settings][:h264_settings][:subgop_length] if video_desc[:codec_settings][:h264_settings][:subgop_length]
                          syntax video_desc[:codec_settings][:h264_settings][:syntax] if video_desc[:codec_settings][:h264_settings][:syntax]
                          temporal_aq video_desc[:codec_settings][:h264_settings][:temporal_aq] if video_desc[:codec_settings][:h264_settings][:temporal_aq]
                          timecode_insertion video_desc[:codec_settings][:h264_settings][:timecode_insertion] if video_desc[:codec_settings][:h264_settings][:timecode_insertion]
                        end
                      end
                      
                      if video_desc[:codec_settings][:h265_settings]
                        h265_settings do
                          adaptive_quantization video_desc[:codec_settings][:h265_settings][:adaptive_quantization] if video_desc[:codec_settings][:h265_settings][:adaptive_quantization]
                          afd_signaling video_desc[:codec_settings][:h265_settings][:afd_signaling] if video_desc[:codec_settings][:h265_settings][:afd_signaling]
                          alternative_transfer_function video_desc[:codec_settings][:h265_settings][:alternative_transfer_function] if video_desc[:codec_settings][:h265_settings][:alternative_transfer_function]
                          bitrate video_desc[:codec_settings][:h265_settings][:bitrate] if video_desc[:codec_settings][:h265_settings][:bitrate]
                          buf_size video_desc[:codec_settings][:h265_settings][:buf_size] if video_desc[:codec_settings][:h265_settings][:buf_size]
                          color_metadata video_desc[:codec_settings][:h265_settings][:color_metadata] if video_desc[:codec_settings][:h265_settings][:color_metadata]
                          fixed_afd video_desc[:codec_settings][:h265_settings][:fixed_afd] if video_desc[:codec_settings][:h265_settings][:fixed_afd]
                          flicker_aq video_desc[:codec_settings][:h265_settings][:flicker_aq] if video_desc[:codec_settings][:h265_settings][:flicker_aq]
                          framerate_control video_desc[:codec_settings][:h265_settings][:framerate_control] if video_desc[:codec_settings][:h265_settings][:framerate_control]
                          framerate_denominator video_desc[:codec_settings][:h265_settings][:framerate_denominator] if video_desc[:codec_settings][:h265_settings][:framerate_denominator]
                          framerate_numerator video_desc[:codec_settings][:h265_settings][:framerate_numerator] if video_desc[:codec_settings][:h265_settings][:framerate_numerator]
                          gop_closed_cadence video_desc[:codec_settings][:h265_settings][:gop_closed_cadence] if video_desc[:codec_settings][:h265_settings][:gop_closed_cadence]
                          gop_size video_desc[:codec_settings][:h265_settings][:gop_size] if video_desc[:codec_settings][:h265_settings][:gop_size]
                          gop_size_units video_desc[:codec_settings][:h265_settings][:gop_size_units] if video_desc[:codec_settings][:h265_settings][:gop_size_units]
                          level video_desc[:codec_settings][:h265_settings][:level] if video_desc[:codec_settings][:h265_settings][:level]
                          look_ahead_rate_control video_desc[:codec_settings][:h265_settings][:look_ahead_rate_control] if video_desc[:codec_settings][:h265_settings][:look_ahead_rate_control]
                          max_bitrate video_desc[:codec_settings][:h265_settings][:max_bitrate] if video_desc[:codec_settings][:h265_settings][:max_bitrate]
                          min_i_interval video_desc[:codec_settings][:h265_settings][:min_i_interval] if video_desc[:codec_settings][:h265_settings][:min_i_interval]
                          par_control video_desc[:codec_settings][:h265_settings][:par_control] if video_desc[:codec_settings][:h265_settings][:par_control]
                          par_denominator video_desc[:codec_settings][:h265_settings][:par_denominator] if video_desc[:codec_settings][:h265_settings][:par_denominator]
                          par_numerator video_desc[:codec_settings][:h265_settings][:par_numerator] if video_desc[:codec_settings][:h265_settings][:par_numerator]
                          profile video_desc[:codec_settings][:h265_settings][:profile] if video_desc[:codec_settings][:h265_settings][:profile]
                          qvbr_quality_level video_desc[:codec_settings][:h265_settings][:qvbr_quality_level] if video_desc[:codec_settings][:h265_settings][:qvbr_quality_level]
                          rate_control_mode video_desc[:codec_settings][:h265_settings][:rate_control_mode] if video_desc[:codec_settings][:h265_settings][:rate_control_mode]
                          scan_type video_desc[:codec_settings][:h265_settings][:scan_type] if video_desc[:codec_settings][:h265_settings][:scan_type]
                          scene_change_detect video_desc[:codec_settings][:h265_settings][:scene_change_detect] if video_desc[:codec_settings][:h265_settings][:scene_change_detect]
                          slices video_desc[:codec_settings][:h265_settings][:slices] if video_desc[:codec_settings][:h265_settings][:slices]
                          tier video_desc[:codec_settings][:h265_settings][:tier] if video_desc[:codec_settings][:h265_settings][:tier]
                          timecode_insertion video_desc[:codec_settings][:h265_settings][:timecode_insertion] if video_desc[:codec_settings][:h265_settings][:timecode_insertion]
                        end
                      end
                    end
                  end
                end
              end
            end
          end
          
          # Destinations
          channel_attrs.destinations.each do |destination|
            destinations do
              id destination[:id]
              
              if destination[:media_package_settings]
                destination[:media_package_settings].each do |mp_setting|
                  media_package_settings do
                    channel_id mp_setting[:channel_id]
                  end
                end
              end
              
              if destination[:multiplex_settings]
                multiplex_settings do
                  multiplex_id destination[:multiplex_settings][:multiplex_id]
                  program_name destination[:multiplex_settings][:program_name]
                end
              end
              
              if destination[:settings]
                destination[:settings].each do |setting|
                  settings do
                    password_param setting[:password_param] if setting[:password_param]
                    stream_name setting[:stream_name] if setting[:stream_name]
                    url setting[:url] if setting[:url]
                    username setting[:username] if setting[:username]
                  end
                end
              end
            end
          end
          
          # Input specification
          input_specification do
            codec channel_attrs.input_specification[:codec]
            maximum_bitrate channel_attrs.input_specification[:maximum_bitrate]
            resolution channel_attrs.input_specification[:resolution]
          end
          
          # Log level
          log_level channel_attrs.log_level
          
          # Maintenance window
          if channel_attrs.maintenance.any?
            maintenance do
              maintenance_day channel_attrs.maintenance[:maintenance_day]
              maintenance_start_time channel_attrs.maintenance[:maintenance_start_time]
            end
          end
          
          # Reserved instances
          channel_attrs.reserved_instances.each do |reserved_instance|
            reserved_instances do
              count reserved_instance[:count]
              name reserved_instance[:name]
            end
          end
          
          # Role ARN
          role_arn channel_attrs.role_arn
          
          # VPC configuration
          if channel_attrs.vpc.any?
            vpc do
              public_address_allocation_ids channel_attrs.vpc[:public_address_allocation_ids]
              security_group_ids channel_attrs.vpc[:security_group_ids]
              subnet_ids channel_attrs.vpc[:subnet_ids]
            end
          end
          
          # Apply tags
          if channel_attrs.tags.any?
            tags do
              channel_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_medialive_channel',
          name: name,
          resource_attributes: channel_attrs.to_h,
          outputs: {
            arn: "${aws_medialive_channel.#{name}.arn}",
            channel_id: "${aws_medialive_channel.#{name}.channel_id}",
            id: "${aws_medialive_channel.#{name}.id}"
          },
          computed: {
            single_pipeline: channel_attrs.single_pipeline?,
            standard_channel: channel_attrs.standard_channel?,
            has_redundancy: channel_attrs.has_redundancy?,
            input_count: channel_attrs.input_count,
            output_group_count: channel_attrs.output_group_count,
            destination_count: channel_attrs.destination_count,
            has_vpc_config: channel_attrs.has_vpc_config?,
            maintenance_scheduled: channel_attrs.maintenance_scheduled?,
            schedule_actions_count: channel_attrs.schedule_actions_count,
            supports_hdr: channel_attrs.supports_hdr?,
            maximum_resolution: channel_attrs.maximum_resolution
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)