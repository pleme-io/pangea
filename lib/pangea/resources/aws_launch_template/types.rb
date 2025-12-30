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

# Extracted type definitions
require_relative 'types/iam_instance_profile'
require_relative 'types/block_device_mapping'
require_relative 'types/network_interface'
require_relative 'types/tag_specification'

module Pangea
  module Resources
    module AWS
      module Types
        # Launch template data attributes
        class LaunchTemplateData < Dry::Struct
          transform_keys(&:to_sym)

          # Core instance configuration
          attribute :image_id, Resources::Types::String.optional.default(nil)
          attribute :instance_type, Resources::Types::Ec2InstanceType.optional.default(nil)
          attribute :key_name, Resources::Types::String.optional.default(nil)

          # Security and IAM
          attribute :iam_instance_profile, IamInstanceProfile.optional.default(nil)
          attribute :security_group_ids, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
          attribute :vpc_security_group_ids, Resources::Types::Array.of(Resources::Types::String).default([].freeze)

          # User data and metadata
          attribute :user_data, Resources::Types::String.optional.default(nil)
          attribute :instance_initiated_shutdown_behavior, Resources::Types::String.default('stop').enum('stop', 'terminate')
          attribute :disable_api_termination, Resources::Types::Bool.default(false)

          # Monitoring and placement
          attribute :monitoring, Resources::Types::Hash.schema(
            enabled: Resources::Types::Bool
          ).optional.default(nil)

          # Block devices
          attribute :block_device_mappings, Resources::Types::Array.of(BlockDeviceMapping).default([].freeze)

          # Network interfaces
          attribute :network_interfaces, Resources::Types::Array.of(NetworkInterface).default([].freeze)

          # Tag specifications
          attribute :tag_specifications, Resources::Types::Array.of(TagSpecification).default([].freeze)

          def to_h
            hash = {}

            # Add simple attributes
            hash[:image_id] = image_id if image_id
            hash[:instance_type] = instance_type if instance_type
            hash[:key_name] = key_name if key_name
            hash[:user_data] = user_data if user_data
            hash[:instance_initiated_shutdown_behavior] = instance_initiated_shutdown_behavior if instance_initiated_shutdown_behavior != 'stop'
            hash[:disable_api_termination] = disable_api_termination if disable_api_termination

            # Add complex attributes
            hash[:iam_instance_profile] = iam_instance_profile.to_h if iam_instance_profile
            hash[:security_group_ids] = security_group_ids if security_group_ids.any?
            hash[:vpc_security_group_ids] = vpc_security_group_ids if vpc_security_group_ids.any?
            hash[:monitoring] = monitoring if monitoring
            hash[:block_device_mappings] = block_device_mappings.map(&:to_h) if block_device_mappings.any?
            hash[:network_interfaces] = network_interfaces.map(&:to_h) if network_interfaces.any?
            hash[:tag_specifications] = tag_specifications.map(&:to_h) if tag_specifications.any?

            hash
          end
        end

        # Launch Template resource attributes with validation
        class LaunchTemplateAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :name, Resources::Types::String.optional.default(nil)
          attribute :name_prefix, Resources::Types::String.optional.default(nil)
          attribute :description, Resources::Types::String.optional.default(nil)
          attribute :launch_template_data, LaunchTemplateData
          attribute :tags, Resources::Types::AwsTags

          # Validate name/name_prefix exclusivity
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            if attrs[:name] && attrs[:name_prefix]
              raise Dry::Struct::Error, "Cannot specify both 'name' and 'name_prefix'"
            end

            # Ensure launch_template_data is properly structured
            if attrs[:launch_template_data].nil?
              attrs[:launch_template_data] = {}
            end

            super(attrs)
          end

          def to_h
            {
              name: name,
              name_prefix: name_prefix,
              description: description,
              launch_template_data: launch_template_data.to_h,
              tags: tags
            }.compact
          end
        end
      end
    end
  end
end
