# frozen_string_literal: true

require 'pangea/resources/types'
require_relative 'output_group_settings'
require_relative 'hls_group_settings'
require_relative 'output_settings'

module Pangea
  module Resources
    module AWS
      module Types
        module MediaLiveChannel
          # Output group type definitions
          module OutputGroups
            T = Resources::Types
            OGS = OutputGroupSettings
            HGS = HlsGroupSettings
            OS = OutputSettings

            # Output group settings container
            GroupSettings = T::Hash.schema(
              archive_group_settings?: OGS::ArchiveGroupSettings.optional,
              frame_capture_group_settings?: OGS::FrameCaptureGroupSettings.optional,
              hls_group_settings?: HGS::HlsSettings.optional,
              media_package_group_settings?: HGS::MediaPackageSettings.optional,
              ms_smooth_group_settings?: HGS::MsSmoothSettings.optional,
              multiplex_group_settings?: T::Hash.optional,
              rtmp_group_settings?: HGS::RtmpSettings.optional,
              udp_group_settings?: HGS::UdpSettings.optional
            )

            # Output group
            OutputGroup = T::Hash.schema(
              name?: T::String.optional,
              output_group_settings: GroupSettings,
              outputs: T::Array.of(OS::Output)
            )
          end
        end
      end
    end
  end
end
