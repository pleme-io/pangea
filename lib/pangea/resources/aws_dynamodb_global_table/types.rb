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

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS DynamoDB Global Table resources
      class DynamoDbGlobalTableAttributes < Dry::Struct
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

        # Helper methods
        def is_pay_per_request?
          billing_mode == "PAY_PER_REQUEST"
        end

        def is_provisioned?
          billing_mode == "PROVISIONED"
        end

        def has_stream?
          stream_enabled == true
        end

        def has_encryption?
          !server_side_encryption.nil?
        end

        def has_pitr?
          point_in_time_recovery && point_in_time_recovery[:enabled]
        end

        def region_count
          replica.size
        end

        def regions
          replica.map { |r| r[:region_name] }
        end

        def has_gsi?
          replica.any? { |r| r[:global_secondary_index] && r[:global_secondary_index].any? }
        end

        def total_gsi_count
          replica.sum { |r| (r[:global_secondary_index] || []).size }
        end

        def estimated_monthly_cost
          cost_multiplier = region_count
          base_cost = is_pay_per_request? ? "Variable per region" : "~$50"
          
          "#{base_cost} × #{cost_multiplier} regions (#{total_gsi_count} total GSIs)"
        end

        def multi_region_strategy
          case region_count
          when 2
            "Active-Active (2 regions)"
          when 3
            "Multi-region Active (3 regions)"
          else
            "Global Active-Active (#{region_count} regions)"
          end
        end
      end

      # Common DynamoDB Global Table configurations
      module DynamoDbGlobalTableConfigs
        # Simple global table across two regions
        def self.simple_global_table(name, primary_region: "us-east-1", secondary_region: "us-west-2")
          {
            name: name,
            billing_mode: "PAY_PER_REQUEST",
            replica: [
              { region_name: primary_region },
              { region_name: secondary_region }
            ]
          }
        end

        # Global table with encryption
        def self.encrypted_global_table(name, regions: ["us-east-1", "us-west-2", "eu-west-1"])
          {
            name: name,
            billing_mode: "PAY_PER_REQUEST",
            server_side_encryption: { enabled: true },
            point_in_time_recovery: { enabled: true },
            replica: regions.map { |region| { region_name: region } }
          }
        end

        # Global table with streams
        def self.streaming_global_table(name, regions: ["us-east-1", "us-west-2"], 
                                        stream_view_type: "NEW_AND_OLD_IMAGES")
          {
            name: name,
            billing_mode: "PAY_PER_REQUEST",
            stream_enabled: true,
            stream_view_type: stream_view_type,
            replica: regions.map { |region| { region_name: region } }
          }
        end

        # High-performance global table with provisioned throughput
        def self.high_performance_global_table(name, regions: ["us-east-1", "us-west-2", "eu-west-1"])
          {
            name: name,
            billing_mode: "PROVISIONED",
            server_side_encryption: { enabled: true },
            point_in_time_recovery: { enabled: true },
            replica: regions.map do |region|
              {
                region_name: region,
                point_in_time_recovery: true,
                table_class: "STANDARD"
              }
            end
          }
        end

        # Global table with regional GSI configurations
        def self.global_table_with_gsi(name, regions: ["us-east-1", "us-west-2"], gsi_name: "GSI1")
          {
            name: name,
            billing_mode: "PAY_PER_REQUEST",
            replica: regions.map do |region|
              {
                region_name: region,
                global_secondary_index: [
                  {
                    name: gsi_name
                  }
                ]
              }
            end
          }
        end

        # Multi-region disaster recovery setup
        def self.disaster_recovery_global_table(name, 
                                               primary_region: "us-east-1",
                                               dr_regions: ["us-west-2", "eu-west-1"])
          all_regions = [primary_region] + dr_regions
          
          {
            name: name,
            billing_mode: "PAY_PER_REQUEST",
            server_side_encryption: { enabled: true },
            point_in_time_recovery: { enabled: true },
            stream_enabled: true,
            stream_view_type: "NEW_AND_OLD_IMAGES",
            replica: all_regions.map do |region|
              {
                region_name: region,
                point_in_time_recovery: true,
                table_class: region == primary_region ? "STANDARD" : "STANDARD_INFREQUENT_ACCESS"
              }
            end
          }
        end
      end
    end
      end
    end
  end
end