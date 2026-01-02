# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        module MediaLiveChannel
          # Channel configuration type definitions
          module ChannelConfig
            T = Resources::Types

            # Destination media package settings
            MediaPackageChannelSettings = T::Hash.schema(
              channel_id: T::String
            )

            # Destination multiplex settings
            MultiplexSettings = T::Hash.schema(
              multiplex_id: T::String,
              program_name: T::String
            )

            # Destination URL settings
            UrlSettings = T::Hash.schema(
              password_param?: T::String.optional,
              stream_name?: T::String.optional,
              url?: T::String.optional,
              username?: T::String.optional
            )

            # Channel destination
            Destination = T::Hash.schema(
              id: T::String,
              media_package_settings?: T::Array.of(MediaPackageChannelSettings).optional,
              multiplex_settings?: MultiplexSettings.optional,
              settings?: T::Array.of(UrlSettings).optional
            )

            # Input specification
            InputSpecification = T::Hash.schema(
              codec: T::String.enum('MPEG2', 'AVC', 'HEVC'),
              maximum_bitrate: T::String.enum('MAX_10_MBPS', 'MAX_20_MBPS', 'MAX_50_MBPS'),
              resolution: T::String.enum('SD', 'HD', 'UHD')
            )

            # Maintenance window
            MaintenanceWindow = T::Hash.schema(
              maintenance_day: T::String.enum('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'),
              maintenance_start_time: T::String
            )

            # Reserved instance
            ReservedInstance = T::Hash.schema(
              count: T::Integer,
              name: T::String
            )

            # VPC configuration
            VpcConfig = T::Hash.schema(
              public_address_allocation_ids: T::Array.of(T::String),
              security_group_ids: T::Array.of(T::String),
              subnet_ids: T::Array.of(T::String)
            )

            # Log level enum
            LogLevel = T::String.enum('ERROR', 'WARNING', 'INFO', 'DEBUG', 'DISABLED')

            # Channel class enum
            ChannelClass = T::String.enum('STANDARD', 'SINGLE_PIPELINE')
          end
        end
      end
    end
  end
end
