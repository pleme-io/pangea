# frozen_string_literal: true

require 'pangea/resources/types'
require_relative 'encoder_config'

module Pangea
  module Resources
    module AWS
      module Types
        module MediaLiveChannel
          # Schedule action type definitions
          module ScheduleSettings
            T = Resources::Types
            EC = EncoderConfig

            # Input clipping settings
            StartTimecode = T::Hash.schema(
              timecode: T::String
            )

            StopTimecode = T::Hash.schema(
              last_frame_clipping_behavior?: T::String.enum('EXCLUDE_LAST_FRAME', 'INCLUDE_LAST_FRAME').optional,
              timecode: T::String
            )

            InputClippingSettings = T::Hash.schema(
              input_timecode_source: T::String.enum('EMBEDDED', 'ZEROBASED'),
              start_timecode?: StartTimecode.optional,
              stop_timecode?: StopTimecode.optional
            )

            # Input prepare/switch settings
            InputPrepareSettings = T::Hash.schema(
              input_attachment_name_reference: T::String,
              input_clipping_settings?: InputClippingSettings.optional,
              url_path?: T::Array.of(T::String).optional
            )

            InputSwitchSettings = T::Hash.schema(
              input_attachment_name_reference: T::String,
              input_clipping_settings?: InputClippingSettings.optional,
              url_path?: T::Array.of(T::String).optional
            )

            # Motion graphics settings
            MotionGraphicsImageActivate = T::Hash.schema(
              duration?: T::Integer.optional,
              password_param?: T::String.optional,
              uri: T::String,
              username?: T::String.optional
            )

            # Pause state settings
            PipelineState = T::Hash.schema(
              pipeline_id: T::String.enum('PIPELINE_0', 'PIPELINE_1')
            )

            PauseStateSettings = T::Hash.schema(
              pipelines: T::Array.of(PipelineState)
            )

            # SCTE35 settings
            Scte35ReturnToNetwork = T::Hash.schema(
              splice_event_id: T::Integer
            )

            SpliceInsertMessage = T::Hash.schema(
              avail_num?: T::Integer.optional,
              avails_expected?: T::Integer.optional,
              splice_immediate_flag: T::Bool,
              unique_program_id: T::Integer
            )

            Scte35SpliceInsertSettings = T::Hash.schema(
              duration?: T::Integer.optional,
              splice_event_id: T::Integer,
              splice_insert_message?: SpliceInsertMessage.optional
            )

            # SCTE35 time signal settings
            DeliveryRestrictions = T::Hash.schema(
              archive_allowed_flag: T::Bool,
              device_restrictions: T::String.enum('NONE', 'RESTRICT_GROUP0', 'RESTRICT_GROUP1', 'RESTRICT_GROUP2'),
              no_regional_blackout_flag: T::Bool,
              web_delivery_allowed_flag: T::Bool
            )

            SegmentationDescriptor = T::Hash.schema(
              delivery_restrictions?: DeliveryRestrictions.optional,
              segment_num?: T::Integer.optional,
              segmentation_cancel_indicator: T::Bool,
              segmentation_duration?: T::Integer.optional,
              segmentation_event_id: T::Integer,
              segmentation_type_id?: T::Integer.optional,
              segmentation_upid?: T::String.optional,
              segmentation_upid_type?: T::Integer.optional,
              segments_expected?: T::Integer.optional,
              sub_segment_num?: T::Integer.optional,
              sub_segments_expected?: T::Integer.optional
            )

            Scte35DescriptorSettings = T::Hash.schema(
              segmentation_descriptor_scte35_settings: SegmentationDescriptor
            )

            Scte35Descriptor = T::Hash.schema(
              scte35_descriptor_settings: Scte35DescriptorSettings
            )

            Scte35TimeSignalSettings = T::Hash.schema(
              scte35_descriptors: T::Array.of(Scte35Descriptor)
            )

            # Static image settings
            StaticImage = T::Hash.schema(
              password_param?: T::String.optional,
              uri: T::String,
              username?: T::String.optional
            )

            StaticImageActivateSettings = T::Hash.schema(
              duration?: T::Integer.optional,
              fade_in?: T::Integer.optional,
              fade_out?: T::Integer.optional,
              height?: T::Integer.optional,
              image: StaticImage,
              image_x?: T::Integer.optional,
              image_y?: T::Integer.optional,
              layer?: T::Integer.optional,
              opacity?: T::Integer.optional,
              width?: T::Integer.optional
            )

            StaticImageDeactivateSettings = T::Hash.schema(
              fade_out?: T::Integer.optional,
              layer?: T::Integer.optional
            )

            # HLS settings
            HlsId3SegmentTaggingSettings = T::Hash.schema(
              tag: T::String
            )

            HlsTimedMetadataSettings = T::Hash.schema(
              id3: T::String
            )

            # Schedule action settings container
            ActionSettings = T::Hash.schema(
              hls_id3_segment_tagging_settings?: HlsId3SegmentTaggingSettings.optional,
              hls_timed_metadata_settings?: HlsTimedMetadataSettings.optional,
              input_prepare_settings?: InputPrepareSettings.optional,
              input_switch_settings?: InputSwitchSettings.optional,
              motion_graphics_image_activate_settings?: MotionGraphicsImageActivate.optional,
              motion_graphics_image_deactivate_settings?: T::Hash.optional,
              pause_state_settings?: PauseStateSettings.optional,
              scte35_return_to_network_settings?: Scte35ReturnToNetwork.optional,
              scte35_splice_insert_settings?: Scte35SpliceInsertSettings.optional,
              scte35_time_signal_settings?: Scte35TimeSignalSettings.optional,
              static_image_activate_settings?: StaticImageActivateSettings.optional,
              static_image_deactivate_settings?: StaticImageDeactivateSettings.optional
            )

            # Schedule action start settings
            FixedModeStartSettings = T::Hash.schema(
              time: T::String
            )

            FollowModeStartSettings = T::Hash.schema(
              follow_point: T::String.enum('END', 'START'),
              reference_action_name: T::String
            )

            ActionStartSettings = T::Hash.schema(
              fixed_mode_schedule_action_start_settings?: FixedModeStartSettings.optional,
              follow_mode_schedule_action_start_settings?: FollowModeStartSettings.optional,
              immediate_mode_schedule_action_start_settings?: T::Hash.optional
            )

            # Schedule action
            ScheduleAction = T::Hash.schema(
              action_name: T::String,
              schedule_action_settings: ActionSettings,
              schedule_action_start_settings: ActionStartSettings
            )
          end
        end
      end
    end
  end
end
