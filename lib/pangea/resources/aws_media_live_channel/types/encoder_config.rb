# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        module MediaLiveChannel
          # Encoder configuration type definitions
          module EncoderConfig
            T = Resources::Types

            # Image input settings (shared)
            ImageInput = T::Hash.schema(
              password_param?: T::String.optional,
              uri: T::String,
              username?: T::String.optional
            )

            # Timecode config
            TimecodeConfig = T::Hash.schema(
              source: T::String.enum('EMBEDDED', 'SYSTEMCLOCK', 'ZEROBASED'),
              sync_threshold?: T::Integer.optional
            )

            # Avail blanking
            AvailBlanking = T::Hash.schema(
              avail_blanking_image?: ImageInput.optional,
              state?: T::String.enum('DISABLED', 'ENABLED').optional
            )

            # SCTE35 avail settings
            Scte35SpliceInsert = T::Hash.schema(
              ad_avail_offset?: T::Integer.optional,
              no_regional_blackout_flag?: T::String.enum('FOLLOW', 'IGNORE').optional,
              web_delivery_allowed_flag?: T::String.enum('FOLLOW', 'IGNORE').optional
            )

            Scte35TimeSignalApos = T::Hash.schema(
              ad_avail_offset?: T::Integer.optional,
              no_regional_blackout_flag?: T::String.enum('FOLLOW', 'IGNORE').optional,
              web_delivery_allowed_flag?: T::String.enum('FOLLOW', 'IGNORE').optional
            )

            AvailSettings = T::Hash.schema(
              scte35_splice_insert?: Scte35SpliceInsert.optional,
              scte35_time_signal_apos?: Scte35TimeSignalApos.optional
            )

            AvailConfiguration = T::Hash.schema(
              avail_settings?: AvailSettings.optional
            )

            # Blackout slate
            BlackoutSlate = T::Hash.schema(
              blackout_slate_image?: ImageInput.optional,
              network_end_blackout?: T::String.enum('DISABLED', 'ENABLED').optional,
              network_end_blackout_image?: ImageInput.optional,
              network_id?: T::String.optional,
              state?: T::String.enum('DISABLED', 'ENABLED').optional
            )

            # Feature activations
            FeatureActivations = T::Hash.schema(
              input_prepare_schedule_actions?: T::String.enum('DISABLED', 'ENABLED').optional
            )

            # Input loss behavior
            InputLossBehavior = T::Hash.schema(
              black_frame_msec?: T::Integer.optional,
              input_loss_image_color?: T::String.optional,
              input_loss_image_slate?: ImageInput.optional,
              input_loss_image_type?: T::String.enum('COLOR', 'SLATE').optional,
              repeat_frame_msec?: T::Integer.optional
            )

            # Global configuration
            GlobalConfiguration = T::Hash.schema(
              initial_audio_gain?: T::Integer.optional,
              input_end_action?: T::String.enum('NONE', 'SWITCH_AND_LOOP_INPUTS').optional,
              input_loss_behavior?: InputLossBehavior.optional,
              output_locking_mode?: T::String.enum('EPOCH_LOCKING', 'PIPELINE_LOCKING').optional,
              output_timing_source?: T::String.enum('INPUT_CLOCK', 'SYSTEM_CLOCK').optional,
              support_low_framerate_inputs?: T::String.enum('DISABLED', 'ENABLED').optional
            )

            # Motion graphics configuration
            MotionGraphicsSettings = T::Hash.schema(
              html_motion_graphics_settings?: T::Hash.optional
            )

            MotionGraphicsConfiguration = T::Hash.schema(
              motion_graphics_insertion?: T::String.enum('DISABLED', 'ENABLED').optional,
              motion_graphics_settings?: MotionGraphicsSettings.optional
            )

            # Nielsen configuration
            NielsenConfiguration = T::Hash.schema(
              distributor_id?: T::String.optional,
              nielsen_pcm_to_id3_tagging?: T::String.enum('DISABLED', 'ENABLED').optional
            )
          end
        end
      end
    end
  end
end
