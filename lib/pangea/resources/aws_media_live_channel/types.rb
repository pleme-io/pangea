# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS MediaLive Channel resources
      class MediaLiveChannelAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Channel name (required)
        attribute :name, Resources::Types::String

        # Channel class for billing (STANDARD or SINGLE_PIPELINE)
        attribute :channel_class, Resources::Types::String.enum('STANDARD', 'SINGLE_PIPELINE').default('STANDARD')

        # Input attachments configuration
        attribute :input_attachments, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            input_attachment_name: Resources::Types::String,
            input_id: Resources::Types::String,
            input_settings?: Resources::Types::Hash.schema(
              audio_selectors?: Resources::Types::Array.of(
                Resources::Types::Hash.schema(
                  name: Resources::Types::String,
                  selector_settings?: Resources::Types::Hash.schema(
                    audio_language_selection?: Resources::Types::Hash.schema(
                      language_code: Resources::Types::String,
                      language_selection_policy?: Resources::Types::String.enum('LOOSE', 'STRICT').optional
                    ).optional,
                    audio_pid_selection?: Resources::Types::Hash.schema(
                      pid: Resources::Types::Integer
                    ).optional
                  ).optional
                )
              ).optional,
              caption_selectors?: Resources::Types::Array.of(
                Resources::Types::Hash.schema(
                  name: Resources::Types::String,
                  language_code?: Resources::Types::String.optional,
                  selector_settings?: Resources::Types::Hash.schema(
                    ancillary_source_settings?: Resources::Types::Hash.optional,
                    embedded_source_settings?: Resources::Types::Hash.optional,
                    scte20_source_settings?: Resources::Types::Hash.optional,
                    teletext_source_settings?: Resources::Types::Hash.optional
                  ).optional
                )
              ).optional,
              deblock_filter?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
              denoise_filter?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
              filter_strength?: Resources::Types::Integer.optional,
              input_filter?: Resources::Types::String.enum('AUTO', 'DISABLED', 'FORCED').optional,
              network_input_settings?: Resources::Types::Hash.schema(
                hls_input_settings?: Resources::Types::Hash.schema(
                  bandwidth?: Resources::Types::Integer.optional,
                  buffer_segments?: Resources::Types::Integer.optional,
                  retries?: Resources::Types::Integer.optional,
                  retry_interval?: Resources::Types::Integer.optional
                ).optional,
                server_validation?: Resources::Types::String.enum('CHECK_CRYPTOGRAPHY_AND_VALIDATE_NAME', 'CHECK_CRYPTOGRAPHY_ONLY').optional
              ).optional,
              smpte2038_data_preference?: Resources::Types::String.enum('IGNORE', 'PREFER').optional,
              source_end_behavior?: Resources::Types::String.enum('CONTINUE', 'LOOP').optional,
              video_selector?: Resources::Types::Hash.schema(
                color_space?: Resources::Types::String.enum('FOLLOW', 'HDR10', 'HLG_2020', 'REC_601', 'REC_709').optional,
                color_space_usage?: Resources::Types::String.enum('FALLBACK', 'FORCE').optional,
                selector_settings?: Resources::Types::Hash.schema(
                  video_selector_pid?: Resources::Types::Hash.schema(
                    pid: Resources::Types::Integer
                  ).optional,
                  video_selector_program_id?: Resources::Types::Hash.schema(
                    program_id: Resources::Types::Integer
                  ).optional
                ).optional
              ).optional
            ).optional
          )
        )

        # Encoder settings for the channel
        attribute :encoder_settings, Resources::Types::Hash.schema(
          audio_descriptions: Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              audio_selector_name: Resources::Types::String,
              audio_type?: Resources::Types::String.enum('CLEAN_EFFECTS', 'HEARING_IMPAIRED', 'UNDEFINED', 'VISUAL_IMPAIRED_COMMENTARY').optional,
              audio_type_control?: Resources::Types::String.enum('FOLLOW_INPUT', 'USE_CONFIGURED').optional,
              codec_settings?: Resources::Types::Hash.schema(
                aac_settings?: Resources::Types::Hash.schema(
                  bitrate?: Resources::Types::Float.optional,
                  coding_mode?: Resources::Types::String.enum('AD_RECEIVER_MIX', 'CODING_MODE_1_0', 'CODING_MODE_1_1', 'CODING_MODE_2_0', 'CODING_MODE_5_1').optional,
                  input_type?: Resources::Types::String.enum('BROADCASTER_MIXED_AD', 'NORMAL').optional,
                  profile?: Resources::Types::String.enum('HEV1', 'HEV2', 'LC').optional,
                  rate_control_mode?: Resources::Types::String.enum('CBR', 'VBR').optional,
                  raw_format?: Resources::Types::String.enum('LATM_LOAS', 'NONE').optional,
                  sample_rate?: Resources::Types::Float.optional,
                  spec?: Resources::Types::String.enum('MPEG2', 'MPEG4').optional,
                  vbr_quality?: Resources::Types::String.enum('HIGH', 'LOW', 'MEDIUM_HIGH', 'MEDIUM_LOW').optional
                ).optional,
                ac3_settings?: Resources::Types::Hash.schema(
                  bitrate?: Resources::Types::Float.optional,
                  bitstream_mode?: Resources::Types::String.enum('COMMENTARY', 'COMPLETE_MAIN', 'DIALOGUE', 'EMERGENCY', 'HEARING_IMPAIRED', 'MUSIC_AND_EFFECTS', 'VISUALLY_IMPAIRED', 'VOICE_OVER').optional,
                  coding_mode?: Resources::Types::String.enum('CODING_MODE_1_0', 'CODING_MODE_1_1', 'CODING_MODE_2_0', 'CODING_MODE_3_2_LFE').optional,
                  dialnorm?: Resources::Types::Integer.optional,
                  drc_profile?: Resources::Types::String.enum('FILM_STANDARD', 'NONE').optional,
                  lfe_filter?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
                  metadata_control?: Resources::Types::String.enum('FOLLOW_INPUT', 'USE_CONFIGURED').optional
                ).optional,
                eac3_settings?: Resources::Types::Hash.schema(
                  attenuation_control?: Resources::Types::String.enum('ATTENUATE_3_DB', 'NONE').optional,
                  bitrate?: Resources::Types::Float.optional,
                  bitstream_mode?: Resources::Types::String.enum('COMMENTARY', 'COMPLETE_MAIN', 'EMERGENCY', 'HEARING_IMPAIRED', 'VISUALLY_IMPAIRED').optional,
                  coding_mode?: Resources::Types::String.enum('CODING_MODE_1_0', 'CODING_MODE_2_0', 'CODING_MODE_3_2').optional,
                  dc_filter?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
                  dialnorm?: Resources::Types::Integer.optional,
                  drc_line?: Resources::Types::String.enum('FILM_LIGHT', 'FILM_STANDARD', 'MUSIC_LIGHT', 'MUSIC_STANDARD', 'NONE', 'SPEECH').optional,
                  drc_rf?: Resources::Types::String.enum('FILM_LIGHT', 'FILM_STANDARD', 'MUSIC_LIGHT', 'MUSIC_STANDARD', 'NONE', 'SPEECH').optional,
                  lfe_control?: Resources::Types::String.enum('LFE', 'NO_LFE').optional,
                  lfe_filter?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
                  lo_ro_center_mix_level?: Resources::Types::Float.optional,
                  lo_ro_surround_mix_level?: Resources::Types::Float.optional,
                  lt_rt_center_mix_level?: Resources::Types::Float.optional,
                  lt_rt_surround_mix_level?: Resources::Types::Float.optional,
                  metadata_control?: Resources::Types::String.enum('FOLLOW_INPUT', 'USE_CONFIGURED').optional,
                  passthrough_control?: Resources::Types::String.enum('NO_PASSTHROUGH', 'WHEN_POSSIBLE').optional,
                  phase_control?: Resources::Types::String.enum('NO_SHIFT', 'SHIFT_90_DEGREES').optional,
                  stereo_downmix?: Resources::Types::String.enum('DPL2', 'LO_RO', 'LT_RT', 'NOT_INDICATED').optional,
                  surround_ex_mode?: Resources::Types::String.enum('DISABLED', 'ENABLED', 'NOT_INDICATED').optional,
                  surround_mode?: Resources::Types::String.enum('DISABLED', 'ENABLED', 'NOT_INDICATED').optional
                ).optional
              ).optional,
              language_code?: Resources::Types::String.optional,
              language_code_control?: Resources::Types::String.enum('FOLLOW_INPUT', 'USE_CONFIGURED').optional,
              name: Resources::Types::String,
              remix_settings?: Resources::Types::Hash.schema(
                channel_mappings: Resources::Types::Array.of(
                  Resources::Types::Hash.schema(
                    input_channel_levels: Resources::Types::Array.of(
                      Resources::Types::Hash.schema(
                        gain: Resources::Types::Integer,
                        input_channel: Resources::Types::Integer
                      )
                    ),
                    output_channel: Resources::Types::Integer
                  )
                ),
                channels_in?: Resources::Types::Integer.optional,
                channels_out?: Resources::Types::Integer.optional
              ).optional,
              stream_name?: Resources::Types::String.optional
            )
          ),
          output_groups: Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              name?: Resources::Types::String.optional,
              output_group_settings: Resources::Types::Hash.schema(
                archive_group_settings?: Resources::Types::Hash.schema(
                  destination: Resources::Types::Hash.schema(
                    destination_ref_id: Resources::Types::String
                  ),
                  rollover_interval?: Resources::Types::Integer.optional
                ).optional,
                frame_capture_group_settings?: Resources::Types::Hash.schema(
                  destination: Resources::Types::Hash.schema(
                    destination_ref_id: Resources::Types::String
                  ),
                  frame_capture_cdn_settings?: Resources::Types::Hash.optional
                ).optional,
                hls_group_settings?: Resources::Types::Hash.schema(
                  destination: Resources::Types::Hash.schema(
                    destination_ref_id: Resources::Types::String
                  ),
                  ad_markers?: Resources::Types::Array.of(Resources::Types::String.enum('ADOBE', 'ELEMENTAL', 'ELEMENTAL_SCTE35')).optional,
                  base_url_content?: Resources::Types::String.optional,
                  base_url_content1?: Resources::Types::String.optional,
                  base_url_manifest?: Resources::Types::String.optional,
                  base_url_manifest1?: Resources::Types::String.optional,
                  caption_language_mappings?: Resources::Types::Array.of(
                    Resources::Types::Hash.schema(
                      caption_channel: Resources::Types::Integer,
                      language_code: Resources::Types::String,
                      language_description: Resources::Types::String
                    )
                  ).optional,
                  caption_language_setting?: Resources::Types::String.enum('INSERT', 'NONE', 'OMIT').optional,
                  client_cache?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
                  codec_specification?: Resources::Types::String.enum('RFC_4281', 'RFC_6381').optional,
                  constant_iv?: Resources::Types::String.optional,
                  directory_structure?: Resources::Types::String.enum('SINGLE_DIRECTORY', 'SUBDIRECTORY_PER_STREAM').optional,
                  discontinuity_tags?: Resources::Types::String.enum('INSERT', 'NEVER_INSERT').optional,
                  encryption_type?: Resources::Types::String.enum('AES128', 'SAMPLE_AES').optional,
                  hls_cdn_settings?: Resources::Types::Hash.schema(
                    hls_akamai_settings?: Resources::Types::Hash.schema(
                      connection_retry_interval?: Resources::Types::Integer.optional,
                      filecache_duration?: Resources::Types::Integer.optional,
                      http_transfer_mode?: Resources::Types::String.enum('CHUNKED', 'NON_CHUNKED').optional,
                      num_retries?: Resources::Types::Integer.optional,
                      restart_delay?: Resources::Types::Integer.optional,
                      salt?: Resources::Types::String.optional,
                      token?: Resources::Types::String.optional
                    ).optional,
                    hls_basic_put_settings?: Resources::Types::Hash.schema(
                      connection_retry_interval?: Resources::Types::Integer.optional,
                      filecache_duration?: Resources::Types::Integer.optional,
                      num_retries?: Resources::Types::Integer.optional,
                      restart_delay?: Resources::Types::Integer.optional
                    ).optional,
                    hls_media_store_settings?: Resources::Types::Hash.schema(
                      connection_retry_interval?: Resources::Types::Integer.optional,
                      filecache_duration?: Resources::Types::Integer.optional,
                      media_store_storage_class?: Resources::Types::String.enum('TEMPORAL').optional,
                      num_retries?: Resources::Types::Integer.optional,
                      restart_delay?: Resources::Types::Integer.optional
                    ).optional,
                    hls_s3_settings?: Resources::Types::Hash.schema(
                      canned_acl?: Resources::Types::String.enum('AUTHENTICATED_READ', 'BUCKET_OWNER_FULL_CONTROL', 'BUCKET_OWNER_READ', 'PUBLIC_READ').optional
                    ).optional,
                    hls_webdav_settings?: Resources::Types::Hash.schema(
                      connection_retry_interval?: Resources::Types::Integer.optional,
                      filecache_duration?: Resources::Types::Integer.optional,
                      http_transfer_mode?: Resources::Types::String.enum('CHUNKED', 'NON_CHUNKED').optional,
                      num_retries?: Resources::Types::Integer.optional,
                      restart_delay?: Resources::Types::Integer.optional
                    ).optional
                  ).optional,
                  hls_id3_segment_tagging?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
                  i_frame_only_playlists?: Resources::Types::String.enum('DISABLED', 'STANDARD').optional,
                  incomplete_segment_behavior?: Resources::Types::String.enum('AUTO', 'SUPPRESS').optional,
                  index_n_segments?: Resources::Types::Integer.optional,
                  input_loss_action?: Resources::Types::String.enum('EMIT_OUTPUT', 'PAUSE_OUTPUT').optional,
                  iv_in_manifest?: Resources::Types::String.enum('EXCLUDE', 'INCLUDE').optional,
                  iv_source?: Resources::Types::String.enum('EXPLICIT', 'FOLLOWS_SEGMENT_NUMBER').optional,
                  keep_segments?: Resources::Types::Integer.optional,
                  key_format?: Resources::Types::String.optional,
                  key_format_versions?: Resources::Types::String.optional,
                  key_provider_settings?: Resources::Types::Hash.schema(
                    static_key_settings?: Resources::Types::Hash.schema(
                      key_provider_server?: Resources::Types::Hash.schema(
                        password_param: Resources::Types::String,
                        uri: Resources::Types::String,
                        username: Resources::Types::String
                      ).optional,
                      static_key_value: Resources::Types::String
                    ).optional
                  ).optional,
                  manifest_compression?: Resources::Types::String.enum('GZIP', 'NONE').optional,
                  manifest_duration_format?: Resources::Types::String.enum('FLOATING_POINT', 'INTEGER').optional,
                  min_segment_length?: Resources::Types::Integer.optional,
                  mode?: Resources::Types::String.enum('LIVE', 'VOD').optional,
                  output_selection?: Resources::Types::String.enum('MANIFESTS_AND_SEGMENTS', 'SEGMENTS_ONLY', 'VARIANT_MANIFESTS_AND_SEGMENTS').optional,
                  program_date_time?: Resources::Types::String.enum('EXCLUDE', 'INCLUDE').optional,
                  program_date_time_clock?: Resources::Types::String.enum('INITIALIZE_FROM_OUTPUT_TIMECODE', 'SYSTEM_CLOCK').optional,
                  program_date_time_period?: Resources::Types::Integer.optional,
                  redundant_manifest?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
                  segment_length?: Resources::Types::Integer.optional,
                  segmentation_mode?: Resources::Types::String.enum('USE_INPUT_SEGMENTATION', 'USE_SEGMENT_DURATION').optional,
                  segments_per_subdirectory?: Resources::Types::Integer.optional,
                  stream_inf_resolution?: Resources::Types::String.enum('EXCLUDE', 'INCLUDE').optional,
                  timed_metadata_id3_frame?: Resources::Types::String.enum('NONE', 'PRIV', 'TDRL').optional,
                  timed_metadata_id3_period?: Resources::Types::Integer.optional,
                  timestamp_delta_milliseconds?: Resources::Types::Integer.optional,
                  ts_file_mode?: Resources::Types::String.enum('SEGMENTED_FILES', 'SINGLE_FILE').optional
                ).optional,
                media_package_group_settings?: Resources::Types::Hash.schema(
                  destination: Resources::Types::Hash.schema(
                    destination_ref_id: Resources::Types::String
                  )
                ).optional,
                ms_smooth_group_settings?: Resources::Types::Hash.schema(
                  destination: Resources::Types::Hash.schema(
                    destination_ref_id: Resources::Types::String
                  ),
                  acquisition_point_id?: Resources::Types::String.optional,
                  audio_only_timecode_control?: Resources::Types::String.enum('PASSTHROUGH', 'USE_CONFIGURED_CLOCK').optional,
                  certificate_mode?: Resources::Types::String.enum('SELF_SIGNED', 'VERIFY_AUTHENTICITY').optional,
                  connection_retry_interval?: Resources::Types::Integer.optional,
                  event_id?: Resources::Types::String.optional,
                  event_id_mode?: Resources::Types::String.enum('NO_EVENT_ID', 'USE_CONFIGURED', 'USE_TIMESTAMP').optional,
                  event_stop_behavior?: Resources::Types::String.enum('NONE', 'SEND_EOS').optional,
                  filecache_duration?: Resources::Types::Integer.optional,
                  fragment_length?: Resources::Types::Integer.optional,
                  input_loss_action?: Resources::Types::String.enum('EMIT_OUTPUT', 'PAUSE_OUTPUT').optional,
                  num_retries?: Resources::Types::Integer.optional,
                  restart_delay?: Resources::Types::Integer.optional,
                  segmentation_mode?: Resources::Types::String.enum('USE_INPUT_SEGMENTATION', 'USE_SEGMENT_DURATION').optional,
                  send_delay_ms?: Resources::Types::Integer.optional,
                  sparse_track_type?: Resources::Types::String.enum('NONE', 'SCTE_35', 'SCTE_35_WITHOUT_SEGMENTATION').optional,
                  stream_manifest_behavior?: Resources::Types::String.enum('DO_NOT_SEND', 'SEND').optional,
                  timestamp_offset?: Resources::Types::String.optional,
                  timestamp_offset_mode?: Resources::Types::String.enum('USE_CONFIGURED_OFFSET', 'USE_EVENT_START_DATE').optional
                ).optional,
                multiplex_group_settings?: Resources::Types::Hash.optional,
                rtmp_group_settings?: Resources::Types::Hash.schema(
                  ad_markers?: Resources::Types::Array.of(Resources::Types::String.enum('ON_CUE_POINT_SCTE35')).optional,
                  authentication_scheme?: Resources::Types::String.enum('AKAMAI', 'COMMON').optional,
                  cache_full_behavior?: Resources::Types::String.enum('DISCONNECT_IMMEDIATELY', 'WAIT_FOR_SERVER').optional,
                  cache_length?: Resources::Types::Integer.optional,
                  caption_data?: Resources::Types::String.enum('ALL', 'FIELD1_608', 'FIELD1_AND_FIELD2_608').optional,
                  input_loss_action?: Resources::Types::String.enum('EMIT_OUTPUT', 'PAUSE_OUTPUT').optional,
                  restart_delay?: Resources::Types::Integer.optional
                ).optional,
                udp_group_settings?: Resources::Types::Hash.schema(
                  input_loss_action?: Resources::Types::String.enum('DROP_PROGRAM', 'DROP_TS', 'EMIT_PROGRAM').optional,
                  timed_metadata_id3_frame?: Resources::Types::String.enum('NONE', 'PRIV', 'TDRL').optional,
                  timed_metadata_id3_period?: Resources::Types::Integer.optional
                ).optional
              ),
              outputs: Resources::Types::Array.of(
                Resources::Types::Hash.schema(
                  audio_description_names?: Resources::Types::Array.of(Resources::Types::String).optional,
                  caption_description_names?: Resources::Types::Array.of(Resources::Types::String).optional,
                  output_name?: Resources::Types::String.optional,
                  output_settings: Resources::Types::Hash.schema(
                    archive_output_settings?: Resources::Types::Hash.schema(
                      container_settings: Resources::Types::Hash.schema(
                        m2ts_settings?: Resources::Types::Hash.optional,
                        raw_settings?: Resources::Types::Hash.optional
                      ),
                      extension?: Resources::Types::String.optional,
                      name_modifier?: Resources::Types::String.optional
                    ).optional,
                    frame_capture_output_settings?: Resources::Types::Hash.schema(
                      name_modifier?: Resources::Types::String.optional
                    ).optional,
                    hls_output_settings?: Resources::Types::Hash.schema(
                      h265_packaging_type?: Resources::Types::String.enum('HEV1', 'HVC1').optional,
                      hls_settings: Resources::Types::Hash.schema(
                        audio_only_hls_settings?: Resources::Types::Hash.schema(
                          audio_group_id?: Resources::Types::String.optional,
                          audio_only_image?: Resources::Types::Hash.schema(
                            password_param?: Resources::Types::String.optional,
                            uri: Resources::Types::String,
                            username?: Resources::Types::String.optional
                          ).optional,
                          audio_track_type?: Resources::Types::String.enum('ALTERNATE_AUDIO_AUTO_SELECT', 'ALTERNATE_AUDIO_AUTO_SELECT_DEFAULT', 'ALTERNATE_AUDIO_NOT_AUTO_SELECT', 'AUDIO_ONLY_VARIANT_STREAM').optional,
                          segment_type?: Resources::Types::String.enum('AAC', 'FMP4').optional
                        ).optional,
                        fmp4_hls_settings?: Resources::Types::Hash.schema(
                          audio_rendition_sets?: Resources::Types::String.optional,
                          nielsen_id3_behavior?: Resources::Types::String.enum('NO_PASSTHROUGH', 'PASSTHROUGH').optional,
                          timed_metadata_behavior?: Resources::Types::String.enum('NO_PASSTHROUGH', 'PASSTHROUGH').optional
                        ).optional,
                        standard_hls_settings?: Resources::Types::Hash.schema(
                          audio_rendition_sets?: Resources::Types::String.optional,
                          m3u8_settings: Resources::Types::Hash.schema(
                            audio_frames_per_pes?: Resources::Types::Integer.optional,
                            audio_pids?: Resources::Types::String.optional,
                            ecm_pid?: Resources::Types::String.optional,
                            nielsen_id3_behavior?: Resources::Types::String.enum('NO_PASSTHROUGH', 'PASSTHROUGH').optional,
                            pat_interval?: Resources::Types::Integer.optional,
                            pcr_control?: Resources::Types::String.enum('CONFIGURED_PCR_PERIOD', 'PCR_EVERY_PES_PACKET').optional,
                            pcr_period?: Resources::Types::Integer.optional,
                            pcr_pid?: Resources::Types::String.optional,
                            pmt_interval?: Resources::Types::Integer.optional,
                            pmt_pid?: Resources::Types::String.optional,
                            program_num?: Resources::Types::Integer.optional,
                            scte35_behavior?: Resources::Types::String.enum('NO_PASSTHROUGH', 'PASSTHROUGH').optional,
                            scte35_pid?: Resources::Types::String.optional,
                            timed_metadata_behavior?: Resources::Types::String.enum('NO_PASSTHROUGH', 'PASSTHROUGH').optional,
                            timed_metadata_pid?: Resources::Types::String.optional,
                            transport_stream_id?: Resources::Types::Integer.optional,
                            video_pid?: Resources::Types::String.optional
                          )
                        ).optional
                      ),
                      name_modifier?: Resources::Types::String.optional,
                      segment_modifier?: Resources::Types::String.optional
                    ).optional,
                    media_package_output_settings?: Resources::Types::Hash.optional,
                    ms_smooth_output_settings?: Resources::Types::Hash.schema(
                      h265_packaging_type?: Resources::Types::String.enum('HEV1', 'HVC1').optional,
                      name_modifier?: Resources::Types::String.optional
                    ).optional,
                    multiplex_output_settings?: Resources::Types::Hash.schema(
                      destination: Resources::Types::Hash.schema(
                        destination_ref_id: Resources::Types::String
                      )
                    ).optional,
                    rtmp_output_settings?: Resources::Types::Hash.schema(
                      certificate_mode?: Resources::Types::String.enum('SELF_SIGNED', 'VERIFY_AUTHENTICITY').optional,
                      connection_retry_interval?: Resources::Types::Integer.optional,
                      destination: Resources::Types::Hash.schema(
                        destination_ref_id: Resources::Types::String
                      ),
                      num_retries?: Resources::Types::Integer.optional
                    ).optional,
                    udp_output_settings?: Resources::Types::Hash.schema(
                      buffer_msec?: Resources::Types::Integer.optional,
                      container_settings: Resources::Types::Hash.schema(
                        m2ts_settings?: Resources::Types::Hash.optional
                      ),
                      destination: Resources::Types::Hash.schema(
                        destination_ref_id: Resources::Types::String
                      ),
                      fec_output_settings?: Resources::Types::Hash.schema(
                        column_depth?: Resources::Types::Integer.optional,
                        include_fec?: Resources::Types::String.enum('COLUMN', 'COLUMN_AND_ROW').optional,
                        row_length?: Resources::Types::Integer.optional
                      ).optional
                    ).optional
                  ),
                  video_description_name?: Resources::Types::String.optional
                )
              )
            )
          ),
          timecode_config: Resources::Types::Hash.schema(
            source: Resources::Types::String.enum('EMBEDDED', 'SYSTEMCLOCK', 'ZEROBASED'),
            sync_threshold?: Resources::Types::Integer.optional
          ),
          video_descriptions?: Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              codec_settings?: Resources::Types::Hash.schema(
                frame_capture_settings?: Resources::Types::Hash.schema(
                  capture_interval?: Resources::Types::Integer.optional,
                  capture_interval_units?: Resources::Types::String.enum('MILLISECONDS', 'SECONDS').optional
                ).optional,
                h264_settings?: Resources::Types::Hash.schema(
                  adaptive_quantization?: Resources::Types::String.enum('AUTO', 'HIGH', 'HIGHER', 'LOW', 'MAX', 'MEDIUM', 'OFF').optional,
                  afd_signaling?: Resources::Types::String.enum('AUTO', 'FIXED', 'NONE').optional,
                  bitrate?: Resources::Types::Integer.optional,
                  buf_fill_pct?: Resources::Types::Integer.optional,
                  buf_size?: Resources::Types::Integer.optional,
                  color_metadata?: Resources::Types::String.enum('IGNORE', 'INSERT').optional,
                  entropy_encoding?: Resources::Types::String.enum('CABAC', 'CAVLC').optional,
                  filter_settings?: Resources::Types::Hash.schema(
                    temporal_filter_settings?: Resources::Types::Hash.schema(
                      post_filter_sharpening?: Resources::Types::String.enum('AUTO', 'DISABLED', 'ENABLED').optional,
                      strength?: Resources::Types::String.enum('AUTO', 'STRENGTH_1', 'STRENGTH_2', 'STRENGTH_3', 'STRENGTH_4', 'STRENGTH_5', 'STRENGTH_6', 'STRENGTH_7', 'STRENGTH_8', 'STRENGTH_9', 'STRENGTH_10', 'STRENGTH_11', 'STRENGTH_12', 'STRENGTH_13', 'STRENGTH_14', 'STRENGTH_15', 'STRENGTH_16').optional
                    ).optional
                  ).optional,
                  fixed_afd?: Resources::Types::String.enum('AFD_0000', 'AFD_0010', 'AFD_0011', 'AFD_0100', 'AFD_1000', 'AFD_1001', 'AFD_1010', 'AFD_1011', 'AFD_1101', 'AFD_1110', 'AFD_1111').optional,
                  flicker_aq?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
                  force_field_pictures?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
                  framerate_control?: Resources::Types::String.enum('INITIALIZE_FROM_SOURCE', 'SPECIFIED').optional,
                  framerate_denominator?: Resources::Types::Integer.optional,
                  framerate_numerator?: Resources::Types::Integer.optional,
                  gop_b_reference?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
                  gop_closed_cadence?: Resources::Types::Integer.optional,
                  gop_num_b_frames?: Resources::Types::Integer.optional,
                  gop_size?: Resources::Types::Float.optional,
                  gop_size_units?: Resources::Types::String.enum('FRAMES', 'SECONDS').optional,
                  level?: Resources::Types::String.enum('H264_LEVEL_1', 'H264_LEVEL_1_1', 'H264_LEVEL_1_2', 'H264_LEVEL_1_3', 'H264_LEVEL_2', 'H264_LEVEL_2_1', 'H264_LEVEL_2_2', 'H264_LEVEL_3', 'H264_LEVEL_3_1', 'H264_LEVEL_3_2', 'H264_LEVEL_4', 'H264_LEVEL_4_1', 'H264_LEVEL_4_2', 'H264_LEVEL_5', 'H264_LEVEL_5_1', 'H264_LEVEL_5_2', 'H264_LEVEL_AUTO').optional,
                  look_ahead_rate_control?: Resources::Types::String.enum('HIGH', 'LOW', 'MEDIUM').optional,
                  max_bitrate?: Resources::Types::Integer.optional,
                  min_i_interval?: Resources::Types::Integer.optional,
                  num_ref_frames?: Resources::Types::Integer.optional,
                  par_control?: Resources::Types::String.enum('INITIALIZE_FROM_SOURCE', 'SPECIFIED').optional,
                  par_denominator?: Resources::Types::Integer.optional,
                  par_numerator?: Resources::Types::Integer.optional,
                  profile?: Resources::Types::String.enum('BASELINE', 'HIGH', 'HIGH_10BIT', 'HIGH_422', 'HIGH_422_10BIT', 'MAIN').optional,
                  quality_level?: Resources::Types::String.enum('ENHANCED_QUALITY', 'STANDARD_QUALITY').optional,
                  qvbr_quality_level?: Resources::Types::Integer.optional,
                  rate_control_mode?: Resources::Types::String.enum('CBR', 'MULTIPLEX', 'QVBR', 'VBR').optional,
                  scan_type?: Resources::Types::String.enum('INTERLACED', 'PROGRESSIVE').optional,
                  scene_change_detect?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
                  slices?: Resources::Types::Integer.optional,
                  softness?: Resources::Types::Integer.optional,
                  spatial_aq?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
                  subgop_length?: Resources::Types::String.enum('DYNAMIC', 'FIXED').optional,
                  syntax?: Resources::Types::String.enum('DEFAULT', 'RP2027').optional,
                  temporal_aq?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
                  timecode_insertion?: Resources::Types::String.enum('DISABLED', 'PIC_TIMING_SEI').optional,
                  timecode_burnin_settings?: Resources::Types::Hash.schema(
                    font_size?: Resources::Types::String.enum('EXTRA_SMALL_10', 'LARGE_48', 'MEDIUM_16', 'SMALL_12').optional,
                    position?: Resources::Types::String.enum('BOTTOM_CENTER', 'BOTTOM_LEFT', 'BOTTOM_RIGHT', 'MIDDLE_CENTER', 'MIDDLE_LEFT', 'MIDDLE_RIGHT', 'TOP_CENTER', 'TOP_LEFT', 'TOP_RIGHT').optional,
                    prefix?: Resources::Types::String.optional
                  ).optional
                ).optional,
                h265_settings?: Resources::Types::Hash.schema(
                  adaptive_quantization?: Resources::Types::String.enum('AUTO', 'HIGH', 'HIGHER', 'LOW', 'MAX', 'MEDIUM', 'OFF').optional,
                  afd_signaling?: Resources::Types::String.enum('AUTO', 'FIXED', 'NONE').optional,
                  alternative_transfer_function?: Resources::Types::String.enum('INSERT', 'OMIT').optional,
                  bitrate?: Resources::Types::Integer.optional,
                  buf_size?: Resources::Types::Integer.optional,
                  color_metadata?: Resources::Types::String.enum('IGNORE', 'INSERT').optional,
                  color_space_settings?: Resources::Types::Hash.schema(
                    colorspace_passthrough_settings?: Resources::Types::Hash.optional,
                    dolby_vision81_settings?: Resources::Types::Hash.optional,
                    hdr10_settings?: Resources::Types::Hash.schema(
                      max_cll?: Resources::Types::Integer.optional,
                      max_fall?: Resources::Types::Integer.optional
                    ).optional,
                    rec601_settings?: Resources::Types::Hash.optional,
                    rec709_settings?: Resources::Types::Hash.optional
                  ).optional,
                  filter_settings?: Resources::Types::Hash.schema(
                    temporal_filter_settings?: Resources::Types::Hash.schema(
                      post_filter_sharpening?: Resources::Types::String.enum('AUTO', 'DISABLED', 'ENABLED').optional,
                      strength?: Resources::Types::String.enum('AUTO', 'STRENGTH_1', 'STRENGTH_2', 'STRENGTH_3', 'STRENGTH_4', 'STRENGTH_5', 'STRENGTH_6', 'STRENGTH_7', 'STRENGTH_8', 'STRENGTH_9', 'STRENGTH_10', 'STRENGTH_11', 'STRENGTH_12', 'STRENGTH_13', 'STRENGTH_14', 'STRENGTH_15', 'STRENGTH_16').optional
                    ).optional
                  ).optional,
                  fixed_afd?: Resources::Types::String.enum('AFD_0000', 'AFD_0010', 'AFD_0011', 'AFD_0100', 'AFD_1000', 'AFD_1001', 'AFD_1010', 'AFD_1011', 'AFD_1101', 'AFD_1110', 'AFD_1111').optional,
                  flicker_aq?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
                  framerate_control?: Resources::Types::String.enum('INITIALIZE_FROM_SOURCE', 'SPECIFIED').optional,
                  framerate_denominator?: Resources::Types::Integer.optional,
                  framerate_numerator?: Resources::Types::Integer.optional,
                  gop_closed_cadence?: Resources::Types::Integer.optional,
                  gop_size?: Resources::Types::Float.optional,
                  gop_size_units?: Resources::Types::String.enum('FRAMES', 'SECONDS').optional,
                  level?: Resources::Types::String.enum('H265_LEVEL_1', 'H265_LEVEL_2', 'H265_LEVEL_2_1', 'H265_LEVEL_3', 'H265_LEVEL_3_1', 'H265_LEVEL_4', 'H265_LEVEL_4_1', 'H265_LEVEL_5', 'H265_LEVEL_5_1', 'H265_LEVEL_5_2', 'H265_LEVEL_6', 'H265_LEVEL_6_1', 'H265_LEVEL_6_2', 'H265_LEVEL_AUTO').optional,
                  look_ahead_rate_control?: Resources::Types::String.enum('HIGH', 'LOW', 'MEDIUM').optional,
                  max_bitrate?: Resources::Types::Integer.optional,
                  min_i_interval?: Resources::Types::Integer.optional,
                  par_control?: Resources::Types::String.enum('INITIALIZE_FROM_SOURCE', 'SPECIFIED').optional,
                  par_denominator?: Resources::Types::Integer.optional,
                  par_numerator?: Resources::Types::Integer.optional,
                  profile?: Resources::Types::String.enum('MAIN', 'MAIN_10BIT').optional,
                  qvbr_quality_level?: Resources::Types::Integer.optional,
                  rate_control_mode?: Resources::Types::String.enum('CBR', 'MULTIPLEX', 'QVBR').optional,
                  scan_type?: Resources::Types::String.enum('INTERLACED', 'PROGRESSIVE').optional,
                  scene_change_detect?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
                  slices?: Resources::Types::Integer.optional,
                  tier?: Resources::Types::String.enum('HIGH', 'MAIN').optional,
                  timecode_insertion?: Resources::Types::String.enum('DISABLED', 'PIC_TIMING_SEI').optional,
                  timecode_burnin_settings?: Resources::Types::Hash.schema(
                    font_size?: Resources::Types::String.enum('EXTRA_SMALL_10', 'LARGE_48', 'MEDIUM_16', 'SMALL_12').optional,
                    position?: Resources::Types::String.enum('BOTTOM_CENTER', 'BOTTOM_LEFT', 'BOTTOM_RIGHT', 'MIDDLE_CENTER', 'MIDDLE_LEFT', 'MIDDLE_RIGHT', 'TOP_CENTER', 'TOP_LEFT', 'TOP_RIGHT').optional,
                    prefix?: Resources::Types::String.optional
                  ).optional
                ).optional,
                mpeg2_settings?: Resources::Types::Hash.schema(
                  adaptive_quantization?: Resources::Types::String.enum('AUTO', 'HIGH', 'LOW', 'MEDIUM', 'OFF').optional,
                  afd_signaling?: Resources::Types::String.enum('AUTO', 'FIXED', 'NONE').optional,
                  color_metadata?: Resources::Types::String.enum('IGNORE', 'INSERT').optional,
                  color_space?: Resources::Types::String.enum('AUTO', 'PASSTHROUGH').optional,
                  display_aspect_ratio?: Resources::Types::String.enum('DISPLAYRATIO16X9', 'DISPLAYRATIO4X3').optional,
                  filter_settings?: Resources::Types::Hash.schema(
                    temporal_filter_settings?: Resources::Types::Hash.schema(
                      post_filter_sharpening?: Resources::Types::String.enum('AUTO', 'DISABLED', 'ENABLED').optional,
                      strength?: Resources::Types::String.enum('AUTO', 'STRENGTH_1', 'STRENGTH_2', 'STRENGTH_3', 'STRENGTH_4', 'STRENGTH_5', 'STRENGTH_6', 'STRENGTH_7', 'STRENGTH_8', 'STRENGTH_9', 'STRENGTH_10', 'STRENGTH_11', 'STRENGTH_12', 'STRENGTH_13', 'STRENGTH_14', 'STRENGTH_15', 'STRENGTH_16').optional
                    ).optional
                  ).optional,
                  fixed_afd?: Resources::Types::String.enum('AFD_0000', 'AFD_0010', 'AFD_0011', 'AFD_0100', 'AFD_1000', 'AFD_1001', 'AFD_1010', 'AFD_1011', 'AFD_1101', 'AFD_1110', 'AFD_1111').optional,
                  framerate_control?: Resources::Types::String.enum('INITIALIZE_FROM_SOURCE', 'SPECIFIED').optional,
                  framerate_denominator?: Resources::Types::Integer.optional,
                  framerate_numerator?: Resources::Types::Integer.optional,
                  gop_closed_cadence?: Resources::Types::Integer.optional,
                  gop_num_b_frames?: Resources::Types::Integer.optional,
                  gop_size?: Resources::Types::Float.optional,
                  gop_size_units?: Resources::Types::String.enum('FRAMES', 'SECONDS').optional,
                  scan_type?: Resources::Types::String.enum('INTERLACED', 'PROGRESSIVE').optional,
                  subgop_length?: Resources::Types::String.enum('DYNAMIC', 'FIXED').optional,
                  timecode_insertion?: Resources::Types::String.enum('DISABLED', 'GOP_TIMECODE').optional,
                  timecode_burnin_settings?: Resources::Types::Hash.schema(
                    font_size?: Resources::Types::String.enum('EXTRA_SMALL_10', 'LARGE_48', 'MEDIUM_16', 'SMALL_12').optional,
                    position?: Resources::Types::String.enum('BOTTOM_CENTER', 'BOTTOM_LEFT', 'BOTTOM_RIGHT', 'MIDDLE_CENTER', 'MIDDLE_LEFT', 'MIDDLE_RIGHT', 'TOP_CENTER', 'TOP_LEFT', 'TOP_RIGHT').optional,
                    prefix?: Resources::Types::String.optional
                  ).optional
                ).optional
              ).optional,
              height?: Resources::Types::Integer.optional,
              name: Resources::Types::String,
              respond_to_afd?: Resources::Types::String.enum('NONE', 'PASSTHROUGH', 'RESPOND').optional,
              scaling_behavior?: Resources::Types::String.enum('DEFAULT', 'STRETCH_TO_OUTPUT').optional,
              sharpness?: Resources::Types::Integer.optional,
              width?: Resources::Types::Integer.optional
            )
          ).optional,
          avail_blanking?: Resources::Types::Hash.schema(
            avail_blanking_image?: Resources::Types::Hash.schema(
              password_param?: Resources::Types::String.optional,
              uri: Resources::Types::String,
              username?: Resources::Types::String.optional
            ).optional,
            state?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional
          ).optional,
          avail_configuration?: Resources::Types::Hash.schema(
            avail_settings?: Resources::Types::Hash.schema(
              scte35_splice_insert?: Resources::Types::Hash.schema(
                ad_avail_offset?: Resources::Types::Integer.optional,
                no_regional_blackout_flag?: Resources::Types::String.enum('FOLLOW', 'IGNORE').optional,
                web_delivery_allowed_flag?: Resources::Types::String.enum('FOLLOW', 'IGNORE').optional
              ).optional,
              scte35_time_signal_apos?: Resources::Types::Hash.schema(
                ad_avail_offset?: Resources::Types::Integer.optional,
                no_regional_blackout_flag?: Resources::Types::String.enum('FOLLOW', 'IGNORE').optional,
                web_delivery_allowed_flag?: Resources::Types::String.enum('FOLLOW', 'IGNORE').optional
              ).optional
            ).optional
          ).optional,
          blackout_slate?: Resources::Types::Hash.schema(
            blackout_slate_image?: Resources::Types::Hash.schema(
              password_param?: Resources::Types::String.optional,
              uri: Resources::Types::String,
              username?: Resources::Types::String.optional
            ).optional,
            network_end_blackout?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
            network_end_blackout_image?: Resources::Types::Hash.schema(
              password_param?: Resources::Types::String.optional,
              uri: Resources::Types::String,
              username?: Resources::Types::String.optional
            ).optional,
            network_id?: Resources::Types::String.optional,
            state?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional
          ).optional,
          caption_descriptions?: Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              caption_selector_name: Resources::Types::String,
              destination_settings?: Resources::Types::Hash.schema(
                arib_destination_settings?: Resources::Types::Hash.optional,
                burn_in_destination_settings?: Resources::Types::Hash.schema(
                  alignment?: Resources::Types::String.enum('CENTERED', 'LEFT', 'SMART').optional,
                  background_color?: Resources::Types::String.enum('BLACK', 'NONE', 'WHITE').optional,
                  background_opacity?: Resources::Types::Integer.optional,
                  font?: Resources::Types::Hash.schema(
                    password_param?: Resources::Types::String.optional,
                    uri: Resources::Types::String,
                    username?: Resources::Types::String.optional
                  ).optional,
                  font_color?: Resources::Types::String.enum('BLACK', 'BLUE', 'GREEN', 'RED', 'WHITE', 'YELLOW').optional,
                  font_opacity?: Resources::Types::Integer.optional,
                  font_resolution?: Resources::Types::Integer.optional,
                  font_size?: Resources::Types::String.optional,
                  outline_color?: Resources::Types::String.enum('BLACK', 'BLUE', 'GREEN', 'RED', 'WHITE', 'YELLOW').optional,
                  outline_size?: Resources::Types::Integer.optional,
                  shadow_color?: Resources::Types::String.enum('BLACK', 'NONE', 'WHITE').optional,
                  shadow_opacity?: Resources::Types::Integer.optional,
                  shadow_x_offset?: Resources::Types::Integer.optional,
                  shadow_y_offset?: Resources::Types::Integer.optional,
                  teletext_grid_control?: Resources::Types::String.enum('FIXED', 'SCALED').optional,
                  x_position?: Resources::Types::Integer.optional,
                  y_position?: Resources::Types::Integer.optional
                ).optional,
                dvb_sub_destination_settings?: Resources::Types::Hash.schema(
                  alignment?: Resources::Types::String.enum('CENTERED', 'LEFT', 'SMART').optional,
                  background_color?: Resources::Types::String.enum('BLACK', 'NONE', 'WHITE').optional,
                  background_opacity?: Resources::Types::Integer.optional,
                  font?: Resources::Types::Hash.schema(
                    password_param?: Resources::Types::String.optional,
                    uri: Resources::Types::String,
                    username?: Resources::Types::String.optional
                  ).optional,
                  font_color?: Resources::Types::String.enum('BLACK', 'BLUE', 'GREEN', 'RED', 'WHITE', 'YELLOW').optional,
                  font_opacity?: Resources::Types::Integer.optional,
                  font_resolution?: Resources::Types::Integer.optional,
                  font_size?: Resources::Types::String.optional,
                  outline_color?: Resources::Types::String.enum('BLACK', 'BLUE', 'GREEN', 'RED', 'WHITE', 'YELLOW').optional,
                  outline_size?: Resources::Types::Integer.optional,
                  shadow_color?: Resources::Types::String.enum('BLACK', 'NONE', 'WHITE').optional,
                  shadow_opacity?: Resources::Types::Integer.optional,
                  shadow_x_offset?: Resources::Types::Integer.optional,
                  shadow_y_offset?: Resources::Types::Integer.optional,
                  teletext_grid_control?: Resources::Types::String.enum('FIXED', 'SCALED').optional,
                  x_position?: Resources::Types::Integer.optional,
                  y_position?: Resources::Types::Integer.optional
                ).optional,
                ebu_tt_d_destination_settings?: Resources::Types::Hash.schema(
                  copyright_holder?: Resources::Types::String.optional,
                  fill_line_gap?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
                  font_family?: Resources::Types::String.optional,
                  style_control?: Resources::Types::String.enum('EXCLUDE', 'INCLUDE').optional
                ).optional,
                embedded_destination_settings?: Resources::Types::Hash.optional,
                embedded_plus_scte20_destination_settings?: Resources::Types::Hash.optional,
                rtmp_caption_info_destination_settings?: Resources::Types::Hash.optional,
                scte20_plus_embedded_destination_settings?: Resources::Types::Hash.optional,
                scte27_destination_settings?: Resources::Types::Hash.optional,
                smpte_tt_destination_settings?: Resources::Types::Hash.optional,
                teletext_destination_settings?: Resources::Types::Hash.optional,
                ttml_destination_settings?: Resources::Types::Hash.schema(
                  style_control?: Resources::Types::String.enum('PASSTHROUGH', 'USE_CONFIGURED').optional
                ).optional,
                webvtt_destination_settings?: Resources::Types::Hash.schema(
                  style_control?: Resources::Types::String.enum('NO_STYLE_DATA', 'PASSTHROUGH').optional
                ).optional
              ).optional,
              language_code?: Resources::Types::String.optional,
              language_description?: Resources::Types::String.optional,
              name: Resources::Types::String
            )
          ).optional,
          feature_activations?: Resources::Types::Hash.schema(
            input_prepare_schedule_actions?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional
          ).optional,
          global_configuration?: Resources::Types::Hash.schema(
            initial_audio_gain?: Resources::Types::Integer.optional,
            input_end_action?: Resources::Types::String.enum('NONE', 'SWITCH_AND_LOOP_INPUTS').optional,
            input_loss_behavior?: Resources::Types::Hash.schema(
              black_frame_msec?: Resources::Types::Integer.optional,
              input_loss_image_color?: Resources::Types::String.optional,
              input_loss_image_slate?: Resources::Types::Hash.schema(
                password_param?: Resources::Types::String.optional,
                uri: Resources::Types::String,
                username?: Resources::Types::String.optional
              ).optional,
              input_loss_image_type?: Resources::Types::String.enum('COLOR', 'SLATE').optional,
              repeat_frame_msec?: Resources::Types::Integer.optional
            ).optional,
            output_locking_mode?: Resources::Types::String.enum('EPOCH_LOCKING', 'PIPELINE_LOCKING').optional,
            output_timing_source?: Resources::Types::String.enum('INPUT_CLOCK', 'SYSTEM_CLOCK').optional,
            support_low_framerate_inputs?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional
          ).optional,
          motion_graphics_configuration?: Resources::Types::Hash.schema(
            motion_graphics_insertion?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional,
            motion_graphics_settings?: Resources::Types::Hash.schema(
              html_motion_graphics_settings?: Resources::Types::Hash.optional
            ).optional
          ).optional,
          nielsen_configuration?: Resources::Types::Hash.schema(
            distributor_id?: Resources::Types::String.optional,
            nielsen_pcm_to_id3_tagging?: Resources::Types::String.enum('DISABLED', 'ENABLED').optional
          ).optional
        )

        # Channel destinations
        attribute :destinations, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            id: Resources::Types::String,
            media_package_settings?: Resources::Types::Array.of(
              Resources::Types::Hash.schema(
                channel_id: Resources::Types::String
              )
            ).optional,
            multiplex_settings?: Resources::Types::Hash.schema(
              multiplex_id: Resources::Types::String,
              program_name: Resources::Types::String
            ).optional,
            settings?: Resources::Types::Array.of(
              Resources::Types::Hash.schema(
                password_param?: Resources::Types::String.optional,
                stream_name?: Resources::Types::String.optional,
                url?: Resources::Types::String.optional,
                username?: Resources::Types::String.optional
              )
            ).optional
          )
        )

        # Input specification for the channel
        attribute :input_specification, Resources::Types::Hash.schema(
          codec: Resources::Types::String.enum('MPEG2', 'AVC', 'HEVC'),
          maximum_bitrate: Resources::Types::String.enum('MAX_10_MBPS', 'MAX_20_MBPS', 'MAX_50_MBPS'),
          resolution: Resources::Types::String.enum('SD', 'HD', 'UHD')
        )

        # Log level for the channel
        attribute :log_level, Resources::Types::String.enum('ERROR', 'WARNING', 'INFO', 'DEBUG', 'DISABLED').default('INFO')

        # Maintenance window
        attribute :maintenance, Resources::Types::Hash.schema(
          maintenance_day: Resources::Types::String.enum('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'),
          maintenance_start_time: Resources::Types::String
        ).default({})

        # Reserved instances for pipeline redundancy
        attribute :reserved_instances, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            count: Resources::Types::Integer,
            name: Resources::Types::String
          )
        ).default([])

        # IAM role ARN for the channel
        attribute :role_arn, Resources::Types::String

        # Scheduling configuration
        attribute :schedule, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            action_name: Resources::Types::String,
            schedule_action_settings: Resources::Types::Hash.schema(
              hls_id3_segment_tagging_settings?: Resources::Types::Hash.schema(
                tag: Resources::Types::String
              ).optional,
              hls_timed_metadata_settings?: Resources::Types::Hash.schema(
                id3: Resources::Types::String
              ).optional,
              input_prepare_settings?: Resources::Types::Hash.schema(
                input_attachment_name_reference: Resources::Types::String,
                input_clipping_settings?: Resources::Types::Hash.schema(
                  input_timecode_source: Resources::Types::String.enum('EMBEDDED', 'ZEROBASED'),
                  start_timecode?: Resources::Types::Hash.schema(
                    timecode: Resources::Types::String
                  ).optional,
                  stop_timecode?: Resources::Types::Hash.schema(
                    last_frame_clipping_behavior?: Resources::Types::String.enum('EXCLUDE_LAST_FRAME', 'INCLUDE_LAST_FRAME').optional,
                    timecode: Resources::Types::String
                  ).optional
                ).optional,
                url_path?: Resources::Types::Array.of(Resources::Types::String).optional
              ).optional,
              input_switch_settings?: Resources::Types::Hash.schema(
                input_attachment_name_reference: Resources::Types::String,
                input_clipping_settings?: Resources::Types::Hash.schema(
                  input_timecode_source: Resources::Types::String.enum('EMBEDDED', 'ZEROBASED'),
                  start_timecode?: Resources::Types::Hash.schema(
                    timecode: Resources::Types::String
                  ).optional,
                  stop_timecode?: Resources::Types::Hash.schema(
                    last_frame_clipping_behavior?: Resources::Types::String.enum('EXCLUDE_LAST_FRAME', 'INCLUDE_LAST_FRAME').optional,
                    timecode: Resources::Types::String
                  ).optional
                ).optional,
                url_path?: Resources::Types::Array.of(Resources::Types::String).optional
              ).optional,
              motion_graphics_image_activate_settings?: Resources::Types::Hash.schema(
                duration?: Resources::Types::Integer.optional,
                password_param?: Resources::Types::String.optional,
                uri: Resources::Types::String,
                username?: Resources::Types::String.optional
              ).optional,
              motion_graphics_image_deactivate_settings?: Resources::Types::Hash.optional,
              pause_state_settings?: Resources::Types::Hash.schema(
                pipelines: Resources::Types::Array.of(
                  Resources::Types::Hash.schema(
                    pipeline_id: Resources::Types::String.enum('PIPELINE_0', 'PIPELINE_1')
                  )
                )
              ).optional,
              scte35_return_to_network_settings?: Resources::Types::Hash.schema(
                splice_event_id: Resources::Types::Integer
              ).optional,
              scte35_splice_insert_settings?: Resources::Types::Hash.schema(
                duration?: Resources::Types::Integer.optional,
                splice_event_id: Resources::Types::Integer,
                splice_insert_message?: Resources::Types::Hash.schema(
                  avail_num?: Resources::Types::Integer.optional,
                  avails_expected?: Resources::Types::Integer.optional,
                  splice_immediate_flag: Resources::Types::Bool,
                  unique_program_id: Resources::Types::Integer
                ).optional
              ).optional,
              scte35_time_signal_settings?: Resources::Types::Hash.schema(
                scte35_descriptors: Resources::Types::Array.of(
                  Resources::Types::Hash.schema(
                    scte35_descriptor_settings: Resources::Types::Hash.schema(
                      segmentation_descriptor_scte35_settings: Resources::Types::Hash.schema(
                        delivery_restrictions?: Resources::Types::Hash.schema(
                          archive_allowed_flag: Resources::Types::Bool,
                          device_restrictions: Resources::Types::String.enum('NONE', 'RESTRICT_GROUP0', 'RESTRICT_GROUP1', 'RESTRICT_GROUP2'),
                          no_regional_blackout_flag: Resources::Types::Bool,
                          web_delivery_allowed_flag: Resources::Types::Bool
                        ).optional,
                        segment_num?: Resources::Types::Integer.optional,
                        segmentation_cancel_indicator: Resources::Types::Bool,
                        segmentation_duration?: Resources::Types::Integer.optional,
                        segmentation_event_id: Resources::Types::Integer,
                        segmentation_type_id?: Resources::Types::Integer.optional,
                        segmentation_upid?: Resources::Types::String.optional,
                        segmentation_upid_type?: Resources::Types::Integer.optional,
                        segments_expected?: Resources::Types::Integer.optional,
                        sub_segment_num?: Resources::Types::Integer.optional,
                        sub_segments_expected?: Resources::Types::Integer.optional
                      )
                    )
                  )
                )
              ).optional,
              static_image_activate_settings?: Resources::Types::Hash.schema(
                duration?: Resources::Types::Integer.optional,
                fade_in?: Resources::Types::Integer.optional,
                fade_out?: Resources::Types::Integer.optional,
                height?: Resources::Types::Integer.optional,
                image: Resources::Types::Hash.schema(
                  password_param?: Resources::Types::String.optional,
                  uri: Resources::Types::String,
                  username?: Resources::Types::String.optional
                ),
                image_x?: Resources::Types::Integer.optional,
                image_y?: Resources::Types::Integer.optional,
                layer?: Resources::Types::Integer.optional,
                opacity?: Resources::Types::Integer.optional,
                width?: Resources::Types::Integer.optional
              ).optional,
              static_image_deactivate_settings?: Resources::Types::Hash.schema(
                fade_out?: Resources::Types::Integer.optional,
                layer?: Resources::Types::Integer.optional
              ).optional
            ),
            schedule_action_start_settings: Resources::Types::Hash.schema(
              fixed_mode_schedule_action_start_settings?: Resources::Types::Hash.schema(
                time: Resources::Types::String
              ).optional,
              follow_mode_schedule_action_start_settings?: Resources::Types::Hash.schema(
                follow_point: Resources::Types::String.enum('END', 'START'),
                reference_action_name: Resources::Types::String
              ).optional,
              immediate_mode_schedule_action_start_settings?: Resources::Types::Hash.optional
            )
          )
        ).default([])

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({})

        # VPC configuration for enhanced security
        attribute :vpc, Resources::Types::Hash.schema(
          public_address_allocation_ids: Resources::Types::Array.of(Resources::Types::String),
          security_group_ids: Resources::Types::Array.of(Resources::Types::String),
          subnet_ids: Resources::Types::Array.of(Resources::Types::String)
        ).default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate channel class requirements
          if attrs.channel_class == 'SINGLE_PIPELINE' && attrs.reserved_instances.any?
            raise Dry::Struct::Error, "Single pipeline channels cannot use reserved instances"
          end

          # Validate input attachments
          if attrs.input_attachments.empty?
            raise Dry::Struct::Error, "At least one input attachment is required"
          end

          # Validate encoder settings have required components
          if attrs.encoder_settings[:output_groups].empty?
            raise Dry::Struct::Error, "At least one output group is required"
          end

          # Validate destinations have correct settings
          attrs.destinations.each do |dest|
            settings_count = [dest[:media_package_settings], dest[:multiplex_settings], dest[:settings]].compact.size
            if settings_count != 1
              raise Dry::Struct::Error, "Destination must have exactly one type of settings"
            end
          end

          # Validate maintenance window format
          if attrs.maintenance[:maintenance_start_time] && !attrs.maintenance[:maintenance_start_time].match?(/^\d{2}:\d{2}$/)
            raise Dry::Struct::Error, "Maintenance start time must be in HH:MM format"
          end

          # Validate VPC configuration
          if attrs.vpc.any?
            required_vpc_fields = [:public_address_allocation_ids, :security_group_ids, :subnet_ids]
            missing_fields = required_vpc_fields - attrs.vpc.keys
            unless missing_fields.empty?
              raise Dry::Struct::Error, "VPC configuration requires all of: #{missing_fields.join(', ')}"
            end
          end

          attrs
        end

        # Helper methods
        def single_pipeline?
          channel_class == 'SINGLE_PIPELINE'
        end

        def standard_channel?
          channel_class == 'STANDARD'
        end

        def has_redundancy?
          standard_channel? && reserved_instances.any?
        end

        def input_count
          input_attachments.size
        end

        def output_group_count
          encoder_settings[:output_groups].size
        end

        def destination_count
          destinations.size
        end

        def has_vpc_config?
          vpc.any?
        end

        def maintenance_scheduled?
          maintenance[:maintenance_day] && maintenance[:maintenance_start_time]
        end

        def schedule_actions_count
          schedule.size
        end

        def supports_hdr?
          input_specification[:codec] == 'HEVC'
        end

        def maximum_resolution
          input_specification[:resolution]
        end
      end
    end
      end
    end
  end
end