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

require 'pangea/resources/types'
require_relative 'types/instance_methods'
require_relative 'types/configs'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS DynamoDB Global Table resources
        class DynamoDbGlobalTableAttributes < Dry::Struct
          include DynamoDbGlobalTableInstanceMethods

          # Global table name (required)
          attribute :name, Resources::Types::String

          # Billing mode
          attribute :billing_mode, Resources::Types::String.enum("PAY_PER_REQUEST", "PROVISIONED").default("PAY_PER_REQUEST")

          # Replica configurations (required, must have at least 2 regions)
          attribute :replica, Resources::Types::Array.of(
            Types::Hash.schema(
              region_name: Types::String,
              kms_key_id?: Types::String.optional,
              point_in_time_recovery?: Types::Bool.optional,
              table_class?: Types::String.enum("STANDARD", "STANDARD_INFREQUENT_ACCESS").optional,
              global_secondary_index?: Types::Array.of(
                Types::Hash.schema(
                  name: Types::String,
                  read_capacity?: Types::Integer.optional.constrained(gteq: 1),
                  write_capacity?: Types::Integer.optional.constrained(gteq: 1)
                )
              ).optional,
              tags?: Types::AwsTags.optional
            )
          ).constrained(min_size: 2)

          # Stream specification
          attribute :stream_enabled, Resources::Types::Bool.optional
          attribute :stream_view_type, Resources::Types::String.enum("KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES").optional

          # Server-side encryption
          attribute :server_side_encryption, Resources::Types::Hash.schema(
            enabled: Types::Bool.default(true),
            kms_key_id?: Types::String.optional
          ).optional

          # Time-based recovery
          attribute :point_in_time_recovery, Resources::Types::Hash.schema(
            enabled: Types::Bool.default(false)
          ).optional

          # Tags to apply to the global table
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            # Validate minimum regions
            if attrs.replica.size < 2
              raise Dry::Struct::Error, "Global table requires at least 2 regions"
            end

            # Validate unique regions
            regions = attrs.replica.map { |r| r[:region_name] }
            if regions.uniq.size != regions.size
              raise Dry::Struct::Error, "Global table cannot have duplicate regions"
            end

            # Validate stream configuration
            if attrs.stream_enabled && !attrs.stream_view_type
              raise Dry::Struct::Error, "stream_view_type is required when stream_enabled is true"
            end

            if attrs.stream_view_type && !attrs.stream_enabled
              attrs = attrs.copy_with(stream_enabled: true)
            end

            # Validate billing mode consistency with replica GSI capacity
            if attrs.billing_mode == "PROVISIONED"
              attrs.replica.each do |replica|
                next unless replica[:global_secondary_index]

                replica[:global_secondary_index].each do |gsi|
                  unless gsi[:read_capacity] && gsi[:write_capacity]
                    raise Dry::Struct::Error, "GSI '#{gsi[:name]}' in region '#{replica[:region_name]}' requires capacity settings for PROVISIONED billing mode"
                  end
                end
              end
            elsif attrs.billing_mode == "PAY_PER_REQUEST"
              attrs.replica.each do |replica|
                next unless replica[:global_secondary_index]

                replica[:global_secondary_index].each do |gsi|
                  if gsi[:read_capacity] || gsi[:write_capacity]
                    raise Dry::Struct::Error, "GSI '#{gsi[:name]}' in region '#{replica[:region_name]}' should not have capacity settings for PAY_PER_REQUEST billing mode"
                  end
                end
              end
            end

            attrs
          end
        end
      end

      # DynamoDbGlobalTableConfigs is defined in types/configs.rb
    end
  end
end
