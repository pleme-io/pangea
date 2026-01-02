# frozen_string_literal: true

require 'pangea/resources/types'
require_relative 'output_group_settings'

module Pangea
  module Resources
    module AWS
      module Types
        module MediaLiveChannel
          # Output settings type definitions
          module OutputSettings
            T = Resources::Types
            OGS = OutputGroupSettings

            # Archive output settings
            ArchiveContainerSettings = T::Hash.schema(
              m2ts_settings?: T::Hash.optional,
              raw_settings?: T::Hash.optional
            )

            ArchiveOutputSettings = T::Hash.schema(
              container_settings: ArchiveContainerSettings,
              extension?: T::String.optional,
              name_modifier?: T::String.optional
            )

            # Frame capture output settings
            FrameCaptureOutputSettings = T::Hash.schema(
              name_modifier?: T::String.optional
            )

            # HLS output settings
            AudioOnlyImage = T::Hash.schema(
              password_param?: T::String.optional,
              uri: T::String,
              username?: T::String.optional
            )

            AudioOnlyHlsSettings = T::Hash.schema(
              audio_group_id?: T::String.optional,
              audio_only_image?: AudioOnlyImage.optional,
              audio_track_type?: T::String.enum('ALTERNATE_AUDIO_AUTO_SELECT', 'ALTERNATE_AUDIO_AUTO_SELECT_DEFAULT', 'ALTERNATE_AUDIO_NOT_AUTO_SELECT', 'AUDIO_ONLY_VARIANT_STREAM').optional,
              segment_type?: T::String.enum('AAC', 'FMP4').optional
            )

            Fmp4HlsSettings = T::Hash.schema(
              audio_rendition_sets?: T::String.optional,
              nielsen_id3_behavior?: T::String.enum('NO_PASSTHROUGH', 'PASSTHROUGH').optional,
              timed_metadata_behavior?: T::String.enum('NO_PASSTHROUGH', 'PASSTHROUGH').optional
            )

            M3u8Settings = T::Hash.schema(
              audio_frames_per_pes?: T::Integer.optional,
              audio_pids?: T::String.optional,
              ecm_pid?: T::String.optional,
              nielsen_id3_behavior?: T::String.enum('NO_PASSTHROUGH', 'PASSTHROUGH').optional,
              pat_interval?: T::Integer.optional,
              pcr_control?: T::String.enum('CONFIGURED_PCR_PERIOD', 'PCR_EVERY_PES_PACKET').optional,
              pcr_period?: T::Integer.optional,
              pcr_pid?: T::String.optional,
              pmt_interval?: T::Integer.optional,
              pmt_pid?: T::String.optional,
              program_num?: T::Integer.optional,
              scte35_behavior?: T::String.enum('NO_PASSTHROUGH', 'PASSTHROUGH').optional,
              scte35_pid?: T::String.optional,
              timed_metadata_behavior?: T::String.enum('NO_PASSTHROUGH', 'PASSTHROUGH').optional,
              timed_metadata_pid?: T::String.optional,
              transport_stream_id?: T::Integer.optional,
              video_pid?: T::String.optional
            )

            StandardHlsSettings = T::Hash.schema(
              audio_rendition_sets?: T::String.optional,
              m3u8_settings: M3u8Settings
            )

            HlsSettingsContainer = T::Hash.schema(
              audio_only_hls_settings?: AudioOnlyHlsSettings.optional,
              fmp4_hls_settings?: Fmp4HlsSettings.optional,
              standard_hls_settings?: StandardHlsSettings.optional
            )

            HlsOutputSettings = T::Hash.schema(
              h265_packaging_type?: T::String.enum('HEV1', 'HVC1').optional,
              hls_settings: HlsSettingsContainer,
              name_modifier?: T::String.optional,
              segment_modifier?: T::String.optional
            )

            # MS Smooth output settings
            MsSmoothOutputSettings = T::Hash.schema(
              h265_packaging_type?: T::String.enum('HEV1', 'HVC1').optional,
              name_modifier?: T::String.optional
            )

            # Multiplex output settings
            MultiplexOutputSettings = T::Hash.schema(
              destination: OGS::DestinationRef
            )

            # RTMP output settings
            RtmpOutputSettings = T::Hash.schema(
              certificate_mode?: T::String.enum('SELF_SIGNED', 'VERIFY_AUTHENTICITY').optional,
              connection_retry_interval?: T::Integer.optional,
              destination: OGS::DestinationRef,
              num_retries?: T::Integer.optional
            )

            # UDP FEC output settings
            FecOutputSettings = T::Hash.schema(
              column_depth?: T::Integer.optional,
              include_fec?: T::String.enum('COLUMN', 'COLUMN_AND_ROW').optional,
              row_length?: T::Integer.optional
            )

            UdpContainerSettings = T::Hash.schema(
              m2ts_settings?: T::Hash.optional
            )

            UdpOutputSettings = T::Hash.schema(
              buffer_msec?: T::Integer.optional,
              container_settings: UdpContainerSettings,
              destination: OGS::DestinationRef,
              fec_output_settings?: FecOutputSettings.optional
            )

            # Output settings container
            Settings = T::Hash.schema(
              archive_output_settings?: ArchiveOutputSettings.optional,
              frame_capture_output_settings?: FrameCaptureOutputSettings.optional,
              hls_output_settings?: HlsOutputSettings.optional,
              media_package_output_settings?: T::Hash.optional,
              ms_smooth_output_settings?: MsSmoothOutputSettings.optional,
              multiplex_output_settings?: MultiplexOutputSettings.optional,
              rtmp_output_settings?: RtmpOutputSettings.optional,
              udp_output_settings?: UdpOutputSettings.optional
            )

            # Output definition
            Output = T::Hash.schema(
              audio_description_names?: T::Array.of(T::String).optional,
              caption_description_names?: T::Array.of(T::String).optional,
              output_name?: T::String.optional,
              output_settings: Settings,
              video_description_name?: T::String.optional
            )
          end
        end
      end
    end
  end
end
