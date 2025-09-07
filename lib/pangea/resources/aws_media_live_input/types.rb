# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS MediaLive Input resources
      class MediaLiveInputAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Input name (required)
        attribute :name, Resources::Types::String

        # Input type - determines the protocol and method
        attribute :type, Resources::Types::String.enum(
          'UDP_PUSH',           # UDP unicast or multicast push
          'RTP_PUSH',           # RTP push 
          'RTMP_PUSH',          # RTMP push from encoder
          'RTMP_PULL',          # RTMP pull from source
          'URL_PULL',           # HTTP/HTTPS URL pull
          'MP4_FILE',           # MP4 file input
          'MEDIACONNECT',       # AWS Elemental MediaConnect
          'INPUT_DEVICE',       # AWS Elemental Link input device
          'AWS_CDI',            # AWS Cloud Digital Interface
          'TS_FILE'             # Transport stream file
        )

        # Input class for billing and performance
        attribute :input_class, Resources::Types::String.enum('STANDARD', 'SINGLE_PIPELINE').default('STANDARD')

        # Input destinations for redundancy
        attribute :destinations, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            stream_name?: Resources::Types::String.optional,
            url?: Resources::Types::String.optional
          )
        ).default([])

        # Input devices for hardware inputs
        attribute :input_devices, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            id: Resources::Types::String,
            settings?: Resources::Types::Hash.schema(
              audio_channel_pairs?: Resources::Types::Array.of(
                Resources::Types::Hash.schema(
                  id: Resources::Types::Integer,
                  profile?: Resources::Types::String.enum('CBR-1000', 'CBR-2000', 'VBR-1000', 'VBR-2000').optional
                )
              ).optional,
              codec?: Resources::Types::String.enum('MPEG2', 'AVC', 'HEVC').optional,
              max_bitrate?: Resources::Types::Integer.optional,
              resolution?: Resources::Types::String.enum('SD', 'HD', 'UHD').optional,
              scan_type?: Resources::Types::String.enum('PROGRESSIVE', 'INTERLACED').optional
            ).optional
          )
        ).default([])

        # MediaConnect flows for MediaConnect inputs
        attribute :media_connect_flows, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            flow_arn: Resources::Types::String
          )
        ).default([])

        # Input security groups for access control
        attribute :input_security_groups, Resources::Types::Array.of(Resources::Types::String).default([])

        # Role ARN for accessing input sources
        attribute :role_arn, Resources::Types::String.optional

        # Sources for URL_PULL inputs
        attribute :sources, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            password_param?: Resources::Types::String.optional,
            url: Resources::Types::String,
            username?: Resources::Types::String.optional
          )
        ).default([])

        # VPC configuration for enhanced security
        attribute :vpc, Resources::Types::Hash.schema(
          security_group_ids?: Resources::Types::Array.of(Resources::Types::String).optional,
          subnet_ids?: Resources::Types::Array.of(Resources::Types::String).optional
        ).default({})

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate type-specific requirements
          case attrs.type
          when 'RTMP_PUSH', 'RTP_PUSH', 'UDP_PUSH'
            if attrs.destinations.empty?
              raise Dry::Struct::Error, "Push inputs require at least one destination"
            end
          when 'RTMP_PULL', 'URL_PULL'
            if attrs.sources.empty?
              raise Dry::Struct::Error, "Pull inputs require at least one source"
            end
          when 'MEDIACONNECT'
            if attrs.media_connect_flows.empty?
              raise Dry::Struct::Error, "MediaConnect inputs require at least one flow"
            end
          when 'INPUT_DEVICE'
            if attrs.input_devices.empty?
              raise Dry::Struct::Error, "Input device inputs require at least one device"
            end
          when 'MP4_FILE', 'TS_FILE'
            if attrs.sources.empty?
              raise Dry::Struct::Error, "File inputs require at least one source"
            end
          end

          # Validate single pipeline constraints
          if attrs.input_class == 'SINGLE_PIPELINE'
            if attrs.destinations.size > 1
              raise Dry::Struct::Error, "Single pipeline inputs support only one destination"
            end
            if attrs.sources.size > 1
              raise Dry::Struct::Error, "Single pipeline inputs support only one source"  
            end
          end

          # Validate security group requirements for VPC
          if attrs.vpc[:subnet_ids] && attrs.vpc[:subnet_ids].any?
            unless attrs.vpc[:security_group_ids] && attrs.vpc[:security_group_ids].any?
              raise Dry::Struct::Error, "VPC inputs require security group IDs"
            end
          end

          # Validate MediaConnect flow ARNs
          attrs.media_connect_flows.each do |flow|
            unless flow[:flow_arn].match?(/^arn:aws:mediaconnect:/)
              raise Dry::Struct::Error, "Invalid MediaConnect flow ARN format"
            end
          end

          # Validate input device settings
          attrs.input_devices.each do |device|
            if device[:settings] && device[:settings][:max_bitrate]
              unless device[:settings][:max_bitrate].between?(1000000, 50000000)
                raise Dry::Struct::Error, "Input device max bitrate must be between 1-50 Mbps"
              end
            end
          end

          attrs
        end

        # Helper methods
        def push_input?
          %w[UDP_PUSH RTP_PUSH RTMP_PUSH].include?(type)
        end

        def pull_input?
          %w[RTMP_PULL URL_PULL].include?(type)
        end

        def file_input?
          %w[MP4_FILE TS_FILE].include?(type)
        end

        def device_input?
          type == 'INPUT_DEVICE'
        end

        def mediaconnect_input?
          type == 'MEDIACONNECT'
        end

        def cdi_input?
          type == 'AWS_CDI'
        end

        def single_pipeline?
          input_class == 'SINGLE_PIPELINE'
        end

        def standard_input?
          input_class == 'STANDARD'
        end

        def has_redundancy?
          standard_input? && (destinations.size > 1 || sources.size > 1)
        end

        def destination_count
          destinations.size
        end

        def source_count
          sources.size
        end

        def device_count
          input_devices.size
        end

        def mediaconnect_flow_count
          media_connect_flows.size
        end

        def has_vpc_config?
          vpc[:subnet_ids] && vpc[:subnet_ids].any?
        end

        def has_security_groups?
          input_security_groups.any? || (vpc[:security_group_ids] && vpc[:security_group_ids].any?)
        end

        def requires_role?
          mediaconnect_input? || has_vpc_config?
        end

        def supports_failover?
          standard_input? && (push_input? || pull_input?)
        end

        def is_live_input?
          !file_input?
        end
      end
    end
      end
    end
  end
end