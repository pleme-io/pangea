# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        module MediaLiveChannel
          # Input attachment and selector type definitions
          module InputSettings
            T = Resources::Types

            # Audio selector settings
            AudioLanguageSelection = T::Hash.schema(
              language_code: T::String,
              language_selection_policy?: T::String.enum('LOOSE', 'STRICT').optional
            )

            AudioPidSelection = T::Hash.schema(
              pid: T::Integer
            )

            AudioSelectorSettings = T::Hash.schema(
              audio_language_selection?: AudioLanguageSelection.optional,
              audio_pid_selection?: AudioPidSelection.optional
            )

            AudioSelector = T::Hash.schema(
              name: T::String,
              selector_settings?: AudioSelectorSettings.optional
            )

            # Caption selector settings
            CaptionSelectorSettings = T::Hash.schema(
              ancillary_source_settings?: T::Hash.optional,
              embedded_source_settings?: T::Hash.optional,
              scte20_source_settings?: T::Hash.optional,
              teletext_source_settings?: T::Hash.optional
            )

            CaptionSelector = T::Hash.schema(
              name: T::String,
              language_code?: T::String.optional,
              selector_settings?: CaptionSelectorSettings.optional
            )

            # Video selector settings
            VideoSelectorPid = T::Hash.schema(
              pid: T::Integer
            )

            VideoSelectorProgramId = T::Hash.schema(
              program_id: T::Integer
            )

            VideoSelectorSettings = T::Hash.schema(
              video_selector_pid?: VideoSelectorPid.optional,
              video_selector_program_id?: VideoSelectorProgramId.optional
            )

            VideoSelector = T::Hash.schema(
              color_space?: T::String.enum('FOLLOW', 'HDR10', 'HLG_2020', 'REC_601', 'REC_709').optional,
              color_space_usage?: T::String.enum('FALLBACK', 'FORCE').optional,
              selector_settings?: VideoSelectorSettings.optional
            )

            # Network input settings
            HlsInputSettings = T::Hash.schema(
              bandwidth?: T::Integer.optional,
              buffer_segments?: T::Integer.optional,
              retries?: T::Integer.optional,
              retry_interval?: T::Integer.optional
            )

            NetworkInputSettings = T::Hash.schema(
              hls_input_settings?: HlsInputSettings.optional,
              server_validation?: T::String.enum('CHECK_CRYPTOGRAPHY_AND_VALIDATE_NAME', 'CHECK_CRYPTOGRAPHY_ONLY').optional
            )

            # Complete input settings
            InputSettingsSchema = T::Hash.schema(
              audio_selectors?: T::Array.of(AudioSelector).optional,
              caption_selectors?: T::Array.of(CaptionSelector).optional,
              deblock_filter?: T::String.enum('DISABLED', 'ENABLED').optional,
              denoise_filter?: T::String.enum('DISABLED', 'ENABLED').optional,
              filter_strength?: T::Integer.optional,
              input_filter?: T::String.enum('AUTO', 'DISABLED', 'FORCED').optional,
              network_input_settings?: NetworkInputSettings.optional,
              smpte2038_data_preference?: T::String.enum('IGNORE', 'PREFER').optional,
              source_end_behavior?: T::String.enum('CONTINUE', 'LOOP').optional,
              video_selector?: VideoSelector.optional
            )

            # Input attachment
            InputAttachment = T::Hash.schema(
              input_attachment_name: T::String,
              input_id: T::String,
              input_settings?: InputSettingsSchema.optional
            )
          end
        end
      end
    end
  end
end
