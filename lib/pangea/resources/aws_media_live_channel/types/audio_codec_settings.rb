# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        module MediaLiveChannel
          # Audio codec and description type definitions
          module AudioCodecSettings
            T = Resources::Types

            # AAC codec settings
            AacSettings = T::Hash.schema(
              bitrate?: T::Float.optional,
              coding_mode?: T::String.enum('AD_RECEIVER_MIX', 'CODING_MODE_1_0', 'CODING_MODE_1_1', 'CODING_MODE_2_0', 'CODING_MODE_5_1').optional,
              input_type?: T::String.enum('BROADCASTER_MIXED_AD', 'NORMAL').optional,
              profile?: T::String.enum('HEV1', 'HEV2', 'LC').optional,
              rate_control_mode?: T::String.enum('CBR', 'VBR').optional,
              raw_format?: T::String.enum('LATM_LOAS', 'NONE').optional,
              sample_rate?: T::Float.optional,
              spec?: T::String.enum('MPEG2', 'MPEG4').optional,
              vbr_quality?: T::String.enum('HIGH', 'LOW', 'MEDIUM_HIGH', 'MEDIUM_LOW').optional
            )

            # AC3 codec settings
            Ac3Settings = T::Hash.schema(
              bitrate?: T::Float.optional,
              bitstream_mode?: T::String.enum('COMMENTARY', 'COMPLETE_MAIN', 'DIALOGUE', 'EMERGENCY', 'HEARING_IMPAIRED', 'MUSIC_AND_EFFECTS', 'VISUALLY_IMPAIRED', 'VOICE_OVER').optional,
              coding_mode?: T::String.enum('CODING_MODE_1_0', 'CODING_MODE_1_1', 'CODING_MODE_2_0', 'CODING_MODE_3_2_LFE').optional,
              dialnorm?: T::Integer.optional,
              drc_profile?: T::String.enum('FILM_STANDARD', 'NONE').optional,
              lfe_filter?: T::String.enum('DISABLED', 'ENABLED').optional,
              metadata_control?: T::String.enum('FOLLOW_INPUT', 'USE_CONFIGURED').optional
            )

            # EAC3 codec settings
            Eac3Settings = T::Hash.schema(
              attenuation_control?: T::String.enum('ATTENUATE_3_DB', 'NONE').optional,
              bitrate?: T::Float.optional,
              bitstream_mode?: T::String.enum('COMMENTARY', 'COMPLETE_MAIN', 'EMERGENCY', 'HEARING_IMPAIRED', 'VISUALLY_IMPAIRED').optional,
              coding_mode?: T::String.enum('CODING_MODE_1_0', 'CODING_MODE_2_0', 'CODING_MODE_3_2').optional,
              dc_filter?: T::String.enum('DISABLED', 'ENABLED').optional,
              dialnorm?: T::Integer.optional,
              drc_line?: T::String.enum('FILM_LIGHT', 'FILM_STANDARD', 'MUSIC_LIGHT', 'MUSIC_STANDARD', 'NONE', 'SPEECH').optional,
              drc_rf?: T::String.enum('FILM_LIGHT', 'FILM_STANDARD', 'MUSIC_LIGHT', 'MUSIC_STANDARD', 'NONE', 'SPEECH').optional,
              lfe_control?: T::String.enum('LFE', 'NO_LFE').optional,
              lfe_filter?: T::String.enum('DISABLED', 'ENABLED').optional,
              lo_ro_center_mix_level?: T::Float.optional,
              lo_ro_surround_mix_level?: T::Float.optional,
              lt_rt_center_mix_level?: T::Float.optional,
              lt_rt_surround_mix_level?: T::Float.optional,
              metadata_control?: T::String.enum('FOLLOW_INPUT', 'USE_CONFIGURED').optional,
              passthrough_control?: T::String.enum('NO_PASSTHROUGH', 'WHEN_POSSIBLE').optional,
              phase_control?: T::String.enum('NO_SHIFT', 'SHIFT_90_DEGREES').optional,
              stereo_downmix?: T::String.enum('DPL2', 'LO_RO', 'LT_RT', 'NOT_INDICATED').optional,
              surround_ex_mode?: T::String.enum('DISABLED', 'ENABLED', 'NOT_INDICATED').optional,
              surround_mode?: T::String.enum('DISABLED', 'ENABLED', 'NOT_INDICATED').optional
            )

            # Codec settings container
            CodecSettings = T::Hash.schema(
              aac_settings?: AacSettings.optional,
              ac3_settings?: Ac3Settings.optional,
              eac3_settings?: Eac3Settings.optional
            )

            # Remix settings
            ChannelMapping = T::Hash.schema(
              input_channel_levels: T::Array.of(
                T::Hash.schema(
                  gain: T::Integer,
                  input_channel: T::Integer
                )
              ),
              output_channel: T::Integer
            )

            RemixSettings = T::Hash.schema(
              channel_mappings: T::Array.of(ChannelMapping),
              channels_in?: T::Integer.optional,
              channels_out?: T::Integer.optional
            )

            # Audio description
            AudioDescription = T::Hash.schema(
              audio_selector_name: T::String,
              audio_type?: T::String.enum('CLEAN_EFFECTS', 'HEARING_IMPAIRED', 'UNDEFINED', 'VISUAL_IMPAIRED_COMMENTARY').optional,
              audio_type_control?: T::String.enum('FOLLOW_INPUT', 'USE_CONFIGURED').optional,
              codec_settings?: CodecSettings.optional,
              language_code?: T::String.optional,
              language_code_control?: T::String.enum('FOLLOW_INPUT', 'USE_CONFIGURED').optional,
              name: T::String,
              remix_settings?: RemixSettings.optional,
              stream_name?: T::String.optional
            )
          end
        end
      end
    end
  end
end
