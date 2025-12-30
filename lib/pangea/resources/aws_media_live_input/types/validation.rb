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

module Pangea
  module Resources
    module AWS
      module Types
        module MediaLiveInput
          # Validation methods for MediaLiveInput attributes
          module Validation
            def self.validate(attrs)
              validate_type_requirements(attrs)
              validate_single_pipeline_constraints(attrs)
              validate_vpc_config(attrs)
              validate_mediaconnect_flows(attrs)
              validate_input_devices(attrs)
            end

            def self.validate_type_requirements(attrs)
              case attrs.type
              when 'RTMP_PUSH', 'RTP_PUSH', 'UDP_PUSH'
                raise Dry::Struct::Error, 'Push inputs require at least one destination' if attrs.destinations.empty?
              when 'RTMP_PULL', 'URL_PULL'
                raise Dry::Struct::Error, 'Pull inputs require at least one source' if attrs.sources.empty?
              when 'MEDIACONNECT'
                raise Dry::Struct::Error, 'MediaConnect inputs require at least one flow' if attrs.media_connect_flows.empty?
              when 'INPUT_DEVICE'
                raise Dry::Struct::Error, 'Input device inputs require at least one device' if attrs.input_devices.empty?
              when 'MP4_FILE', 'TS_FILE'
                raise Dry::Struct::Error, 'File inputs require at least one source' if attrs.sources.empty?
              end
            end

            def self.validate_single_pipeline_constraints(attrs)
              return unless attrs.input_class == 'SINGLE_PIPELINE'

              if attrs.destinations.size > 1
                raise Dry::Struct::Error, 'Single pipeline inputs support only one destination'
              end
              if attrs.sources.size > 1
                raise Dry::Struct::Error, 'Single pipeline inputs support only one source'
              end
            end

            def self.validate_vpc_config(attrs)
              return unless attrs.vpc[:subnet_ids] && attrs.vpc[:subnet_ids].any?
              return if attrs.vpc[:security_group_ids] && attrs.vpc[:security_group_ids].any?

              raise Dry::Struct::Error, 'VPC inputs require security group IDs'
            end

            def self.validate_mediaconnect_flows(attrs)
              attrs.media_connect_flows.each do |flow|
                unless flow[:flow_arn].match?(/^arn:aws:mediaconnect:/)
                  raise Dry::Struct::Error, 'Invalid MediaConnect flow ARN format'
                end
              end
            end

            def self.validate_input_devices(attrs)
              attrs.input_devices.each do |device|
                next unless device[:settings] && device[:settings][:max_bitrate]
                next if device[:settings][:max_bitrate].between?(1_000_000, 50_000_000)

                raise Dry::Struct::Error, 'Input device max bitrate must be between 1-50 Mbps'
              end
            end
          end
        end
      end
    end
  end
end
