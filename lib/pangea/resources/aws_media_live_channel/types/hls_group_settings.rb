# frozen_string_literal: true

require 'pangea/resources/types'
require_relative 'output_group_settings'

module Pangea
  module Resources
    module AWS
      module Types
        module MediaLiveChannel
          # HLS output group type definitions
          module HlsGroupSettings
            T = Resources::Types
            OGS = OutputGroupSettings

            # HLS group settings (comprehensive)
            HlsSettings = T::Hash.schema(
              destination: OGS::DestinationRef,
              ad_markers?: T::Array.of(T::String.enum('ADOBE', 'ELEMENTAL', 'ELEMENTAL_SCTE35')).optional,
              base_url_content?: T::String.optional,
              base_url_content1?: T::String.optional,
              base_url_manifest?: T::String.optional,
              base_url_manifest1?: T::String.optional,
              caption_language_mappings?: T::Array.of(OGS::CaptionLanguageMapping).optional,
              caption_language_setting?: T::String.enum('INSERT', 'NONE', 'OMIT').optional,
              client_cache?: T::String.enum('DISABLED', 'ENABLED').optional,
              codec_specification?: T::String.enum('RFC_4281', 'RFC_6381').optional,
              constant_iv?: T::String.optional,
              directory_structure?: T::String.enum('SINGLE_DIRECTORY', 'SUBDIRECTORY_PER_STREAM').optional,
              discontinuity_tags?: T::String.enum('INSERT', 'NEVER_INSERT').optional,
              encryption_type?: T::String.enum('AES128', 'SAMPLE_AES').optional,
              hls_cdn_settings?: OGS::HlsCdnSettings.optional,
              hls_id3_segment_tagging?: T::String.enum('DISABLED', 'ENABLED').optional,
              i_frame_only_playlists?: T::String.enum('DISABLED', 'STANDARD').optional,
              incomplete_segment_behavior?: T::String.enum('AUTO', 'SUPPRESS').optional,
              index_n_segments?: T::Integer.optional,
              input_loss_action?: T::String.enum('EMIT_OUTPUT', 'PAUSE_OUTPUT').optional,
              iv_in_manifest?: T::String.enum('EXCLUDE', 'INCLUDE').optional,
              iv_source?: T::String.enum('EXPLICIT', 'FOLLOWS_SEGMENT_NUMBER').optional,
              keep_segments?: T::Integer.optional,
              key_format?: T::String.optional,
              key_format_versions?: T::String.optional,
              key_provider_settings?: OGS::KeyProviderSettings.optional,
              manifest_compression?: T::String.enum('GZIP', 'NONE').optional,
              manifest_duration_format?: T::String.enum('FLOATING_POINT', 'INTEGER').optional,
              min_segment_length?: T::Integer.optional,
              mode?: T::String.enum('LIVE', 'VOD').optional,
              output_selection?: T::String.enum('MANIFESTS_AND_SEGMENTS', 'SEGMENTS_ONLY', 'VARIANT_MANIFESTS_AND_SEGMENTS').optional,
              program_date_time?: T::String.enum('EXCLUDE', 'INCLUDE').optional,
              program_date_time_clock?: T::String.enum('INITIALIZE_FROM_OUTPUT_TIMECODE', 'SYSTEM_CLOCK').optional,
              program_date_time_period?: T::Integer.optional,
              redundant_manifest?: T::String.enum('DISABLED', 'ENABLED').optional,
              segment_length?: T::Integer.optional,
              segmentation_mode?: T::String.enum('USE_INPUT_SEGMENTATION', 'USE_SEGMENT_DURATION').optional,
              segments_per_subdirectory?: T::Integer.optional,
              stream_inf_resolution?: T::String.enum('EXCLUDE', 'INCLUDE').optional,
              timed_metadata_id3_frame?: T::String.enum('NONE', 'PRIV', 'TDRL').optional,
              timed_metadata_id3_period?: T::Integer.optional,
              timestamp_delta_milliseconds?: T::Integer.optional,
              ts_file_mode?: T::String.enum('SEGMENTED_FILES', 'SINGLE_FILE').optional
            )

            # MS Smooth group settings
            MsSmoothSettings = T::Hash.schema(
              destination: OGS::DestinationRef,
              acquisition_point_id?: T::String.optional,
              audio_only_timecode_control?: T::String.enum('PASSTHROUGH', 'USE_CONFIGURED_CLOCK').optional,
              certificate_mode?: T::String.enum('SELF_SIGNED', 'VERIFY_AUTHENTICITY').optional,
              connection_retry_interval?: T::Integer.optional,
              event_id?: T::String.optional,
              event_id_mode?: T::String.enum('NO_EVENT_ID', 'USE_CONFIGURED', 'USE_TIMESTAMP').optional,
              event_stop_behavior?: T::String.enum('NONE', 'SEND_EOS').optional,
              filecache_duration?: T::Integer.optional,
              fragment_length?: T::Integer.optional,
              input_loss_action?: T::String.enum('EMIT_OUTPUT', 'PAUSE_OUTPUT').optional,
              num_retries?: T::Integer.optional,
              restart_delay?: T::Integer.optional,
              segmentation_mode?: T::String.enum('USE_INPUT_SEGMENTATION', 'USE_SEGMENT_DURATION').optional,
              send_delay_ms?: T::Integer.optional,
              sparse_track_type?: T::String.enum('NONE', 'SCTE_35', 'SCTE_35_WITHOUT_SEGMENTATION').optional,
              stream_manifest_behavior?: T::String.enum('DO_NOT_SEND', 'SEND').optional,
              timestamp_offset?: T::String.optional,
              timestamp_offset_mode?: T::String.enum('USE_CONFIGURED_OFFSET', 'USE_EVENT_START_DATE').optional
            )

            # RTMP group settings
            RtmpSettings = T::Hash.schema(
              ad_markers?: T::Array.of(T::String.enum('ON_CUE_POINT_SCTE35')).optional,
              authentication_scheme?: T::String.enum('AKAMAI', 'COMMON').optional,
              cache_full_behavior?: T::String.enum('DISCONNECT_IMMEDIATELY', 'WAIT_FOR_SERVER').optional,
              cache_length?: T::Integer.optional,
              caption_data?: T::String.enum('ALL', 'FIELD1_608', 'FIELD1_AND_FIELD2_608').optional,
              input_loss_action?: T::String.enum('EMIT_OUTPUT', 'PAUSE_OUTPUT').optional,
              restart_delay?: T::Integer.optional
            )

            # UDP group settings
            UdpSettings = T::Hash.schema(
              input_loss_action?: T::String.enum('DROP_PROGRAM', 'DROP_TS', 'EMIT_PROGRAM').optional,
              timed_metadata_id3_frame?: T::String.enum('NONE', 'PRIV', 'TDRL').optional,
              timed_metadata_id3_period?: T::Integer.optional
            )

            # Media package group settings
            MediaPackageSettings = T::Hash.schema(
              destination: OGS::DestinationRef
            )
          end
        end
      end
    end
  end
end
