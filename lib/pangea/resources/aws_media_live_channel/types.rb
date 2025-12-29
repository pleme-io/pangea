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

require 'dry-struct'
require 'pangea/resources/types'

# Load extracted type modules
require_relative 'types/input_settings'
require_relative 'types/audio_codec_settings'
require_relative 'types/video_codec_settings'
require_relative 'types/video_codec_h265_mpeg2'
require_relative 'types/output_group_settings'
require_relative 'types/hls_group_settings'
require_relative 'types/output_settings'
require_relative 'types/output_groups'
require_relative 'types/encoder_config'
require_relative 'types/caption_settings'
require_relative 'types/schedule_settings'
require_relative 'types/channel_config'
require_relative 'types/helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS MediaLive Channel resources
        class MediaLiveChannelAttributes < Dry::Struct
          include MediaLiveChannel::Helpers
          transform_keys(&:to_sym)

          # Shorthand aliases for extracted modules
          IS = MediaLiveChannel::InputSettings
          ACS = MediaLiveChannel::AudioCodecSettings
          VCS = MediaLiveChannel::VideoCodecH265Mpeg2
          OG = MediaLiveChannel::OutputGroups
          EC = MediaLiveChannel::EncoderConfig
          CS = MediaLiveChannel::CaptionSettings
          SS = MediaLiveChannel::ScheduleSettings
          CC = MediaLiveChannel::ChannelConfig

          attribute :name, Resources::Types::String
          attribute :channel_class, CC::ChannelClass.default('STANDARD')
          attribute :input_attachments, Resources::Types::Array.of(IS::InputAttachment)
          attribute :encoder_settings, Resources::Types::Hash.schema(
            audio_descriptions: Resources::Types::Array.of(ACS::AudioDescription),
            output_groups: Resources::Types::Array.of(OG::OutputGroup),
            timecode_config: EC::TimecodeConfig,
            video_descriptions?: Resources::Types::Array.of(VCS::VideoDescription).optional,
            avail_blanking?: EC::AvailBlanking.optional,
            avail_configuration?: EC::AvailConfiguration.optional,
            blackout_slate?: EC::BlackoutSlate.optional,
            caption_descriptions?: Resources::Types::Array.of(CS::CaptionDescription).optional,
            feature_activations?: EC::FeatureActivations.optional,
            global_configuration?: EC::GlobalConfiguration.optional,
            motion_graphics_configuration?: EC::MotionGraphicsConfiguration.optional,
            nielsen_configuration?: EC::NielsenConfiguration.optional
          )
          attribute :destinations, Resources::Types::Array.of(CC::Destination)
          attribute :input_specification, CC::InputSpecification
          attribute :log_level, CC::LogLevel.default('INFO')
          attribute :maintenance, CC::MaintenanceWindow.default({}.freeze)
          attribute :reserved_instances, Resources::Types::Array.of(CC::ReservedInstance).default([].freeze)
          attribute :role_arn, Resources::Types::String
          attribute :schedule, Resources::Types::Array.of(SS::ScheduleAction).default([].freeze)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)
          attribute :vpc, CC::VpcConfig.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            validate_channel(attrs)
            attrs
          end

          class << self
            private

            def validate_channel(attrs)
              validate_single_pipeline(attrs)
              validate_input_attachments(attrs)
              validate_encoder_settings(attrs)
              validate_destinations(attrs)
              validate_maintenance(attrs)
              validate_vpc(attrs)
            end

            def validate_single_pipeline(attrs)
              return unless attrs.channel_class == 'SINGLE_PIPELINE' && attrs.reserved_instances.any?

              raise Dry::Struct::Error, 'Single pipeline channels cannot use reserved instances'
            end

            def validate_input_attachments(attrs)
              raise Dry::Struct::Error, 'At least one input attachment is required' if attrs.input_attachments.empty?
            end

            def validate_encoder_settings(attrs)
              raise Dry::Struct::Error, 'At least one output group is required' if attrs.encoder_settings[:output_groups].empty?
            end

            def validate_destinations(attrs)
              attrs.destinations.each do |dest|
                settings = [dest[:media_package_settings], dest[:multiplex_settings], dest[:settings]].compact
                raise Dry::Struct::Error, 'Destination must have exactly one type of settings' unless settings.size == 1
              end
            end

            def validate_maintenance(attrs)
              start_time = attrs.maintenance[:maintenance_start_time]
              return unless start_time && !start_time.match?(/^\d{2}:\d{2}$/)

              raise Dry::Struct::Error, 'Maintenance start time must be in HH:MM format'
            end

            def validate_vpc(attrs)
              return unless attrs.vpc.any?

              required = %i[public_address_allocation_ids security_group_ids subnet_ids]
              missing = required - attrs.vpc.keys
              raise Dry::Struct::Error, "VPC configuration requires: #{missing.join(', ')}" unless missing.empty?
            end
          end
        end
      end
    end
  end
end
