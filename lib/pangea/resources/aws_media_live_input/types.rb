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
require_relative 'types/validation'
require_relative 'types/helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS MediaLive Input resources
        class MediaLiveInputAttributes < Dry::Struct
          include MediaLiveInput::Helpers
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
          ).default([].freeze)

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
          ).default([].freeze)

          # MediaConnect flows for MediaConnect inputs
          attribute :media_connect_flows, Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              flow_arn: Resources::Types::String
            )
          ).default([].freeze)

          # Input security groups for access control
          attribute :input_security_groups, Resources::Types::Array.of(Resources::Types::String).default([].freeze)

          # Role ARN for accessing input sources
          attribute :role_arn, Resources::Types::String.optional

          # Sources for URL_PULL inputs
          attribute :sources, Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              password_param?: Resources::Types::String.optional,
              url: Resources::Types::String,
              username?: Resources::Types::String.optional
            )
          ).default([].freeze)

          # VPC configuration for enhanced security
          attribute :vpc, Resources::Types::Hash.schema(
            security_group_ids?: Resources::Types::Array.of(Resources::Types::String).optional,
            subnet_ids?: Resources::Types::Array.of(Resources::Types::String).optional
          ).default({}.freeze)

          # Tags
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            MediaLiveInput::Validation.validate(attrs)
            attrs
          end
        end
      end
    end
  end
end
