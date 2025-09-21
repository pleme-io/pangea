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

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS DynamoDB Table resources
        class DynamoDbTableAttributes < Dry::Struct
        transform_keys(&:to_sym)
        # Table name (required)
        attribute :name, Pangea::Resources::Types::String

        # Billing mode
        attribute :billing_mode, Pangea::Resources::Types::String.constrained(included_in: ["PAY_PER_REQUEST", "PROVISIONED"]).default("PAY_PER_REQUEST")

        # Attribute definitions
        attribute :attribute, Pangea::Resources::Types::Array.of(
          Pangea::Resources::Types::Hash.schema(
            name: Pangea::Resources::Types::String,
            type: Pangea::Resources::Types::String.constrained(included_in: ["S", "N", "B"])
          )
        ).constrained(min_size: 1)

        # Hash key (partition key) - required
        attribute :hash_key, Pangea::Resources::Types::String

        # Range key (sort key) - optional
        attribute? :range_key, Pangea::Resources::Types::String.optional

        # Provisioned throughput (only used when billing_mode is PROVISIONED)
        attribute? :read_capacity, Pangea::Resources::Types::Integer.optional.constrained(gteq: 1, lteq: 40000)
        attribute? :write_capacity, Pangea::Resources::Types::Integer.optional.constrained(gteq: 1, lteq: 40000)

        # Global Secondary Indexes
        attribute :global_secondary_index, Pangea::Resources::Types::Array.of(
          Pangea::Resources::Types::Hash.schema(
            name: Pangea::Resources::Types::String,
            hash_key: Pangea::Resources::Types::String,
            range_key?: Pangea::Resources::Types::String.optional,
            write_capacity?: Pangea::Resources::Types::Integer.optional.constrained(gteq: 1, lteq: 40000),
            read_capacity?: Pangea::Resources::Types::Integer.optional.constrained(gteq: 1, lteq: 40000),
            projection_type?: Pangea::Resources::Types::String.constrained(included_in: ["ALL", "KEYS_ONLY", "INCLUDE"]).default("ALL"),
            non_key_attributes?: Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional
          )
        ).default([].freeze)

        # Local Secondary Indexes
        attribute :local_secondary_index, Pangea::Resources::Types::Array.of(
          Pangea::Resources::Types::Hash.schema(
            name: Pangea::Resources::Types::String,
            range_key: Pangea::Resources::Types::String,
            projection_type?: Pangea::Resources::Types::String.constrained(included_in: ["ALL", "KEYS_ONLY", "INCLUDE"]).default("ALL"),
            non_key_attributes?: Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional
          )
        ).default([].freeze)

        # TTL configuration
        attribute? :ttl, Pangea::Resources::Types::Hash.schema(
          attribute_name: Pangea::Resources::Types::String,
          enabled?: Pangea::Resources::Types::Bool.default(true)
        ).optional

        # Stream configuration
        attribute? :stream_enabled, Pangea::Resources::Types::Bool.optional
        attribute? :stream_view_type, Pangea::Resources::Types::String.constrained(included_in: ["KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"]).optional

        # Point-in-time recovery
        attribute :point_in_time_recovery_enabled, Pangea::Resources::Types::Bool.default(false)

        # Server-side encryption
        attribute? :server_side_encryption, Pangea::Resources::Types::Hash.schema(
          enabled: Pangea::Resources::Types::Bool.default(true),
          kms_key_id?: Pangea::Resources::Types::String.optional
        ).optional

        # Deletion protection
        attribute :deletion_protection_enabled, Pangea::Resources::Types::Bool.default(false)

        # Table class
        attribute :table_class, Pangea::Resources::Types::String.constrained(included_in: ["STANDARD", "STANDARD_INFREQUENT_ACCESS"]).default("STANDARD")

        # Restore configuration
        attribute? :restore_source_name, Pangea::Resources::Types::String.optional
        attribute? :restore_source_table_arn, Pangea::Resources::Types::String.optional
        attribute? :restore_to_time, Pangea::Resources::Types::String.optional
        attribute? :restore_date_time, Pangea::Resources::Types::String.optional

        # Import configuration
        attribute? :import_table, Pangea::Resources::Types::Hash.schema(
          input_format: Pangea::Resources::Types::String.constrained(included_in: ["DYNAMODB_EXPORT", "ION", "CSV"]),
          s3_bucket_source: Pangea::Resources::Types::Hash.schema(
            bucket: Pangea::Resources::Types::String,
            bucket_owner?: Pangea::Resources::Types::String.optional,
            key_prefix?: Pangea::Resources::Types::String.optional
          ),
          input_format_options?: Pangea::Resources::Types::Hash.schema(
            csv?: Pangea::Resources::Types::Hash.schema(
              delimiter?: Pangea::Resources::Types::String.optional,
              header_list?: Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional
            ).optional
          ).optional,
          input_compression_type?: Pangea::Resources::Types::String.constrained(included_in: ["GZIP", "ZSTD", "NONE"]).optional
        ).optional

        # Replica configuration for Global Tables
        attribute :replica, Pangea::Resources::Types::Array.of(
          Pangea::Resources::Types::Hash.schema(
            region_name: Pangea::Resources::Types::String,
            kms_key_id?: Pangea::Resources::Types::String.optional,
            point_in_time_recovery?: Pangea::Resources::Types::Bool.optional,
            global_secondary_index?: Pangea::Resources::Types::Array.of(
              Pangea::Resources::Types::Hash.schema(
                name: Pangea::Resources::Types::String,
                read_capacity?: Pangea::Resources::Types::Integer.optional.constrained(gteq: 1),
                write_capacity?: Pangea::Resources::Types::Integer.optional.constrained(gteq: 1)
              )
            ).optional,
            table_class?: Pangea::Resources::Types::String.constrained(included_in: ["STANDARD", "STANDARD_INFREQUENT_ACCESS"]).optional
          )
        ).default([].freeze)

        # Tags to apply to the table
        attribute :tags, Pangea::Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate billing mode consistency
          if attrs.billing_mode == "PROVISIONED"
            unless attrs.read_capacity && attrs.write_capacity
              raise Dry::Struct::Error, "PROVISIONED billing mode requires read_capacity and write_capacity"
            end
            
            # Validate GSI capacity settings for PROVISIONED mode
            attrs.global_secondary_index.each do |gsi|
              unless gsi[:read_capacity] && gsi[:write_capacity]
                raise Dry::Struct::Error, "GSI '#{gsi[:name]}' requires read_capacity and write_capacity for PROVISIONED billing mode"
              end
            end
          elsif attrs.billing_mode == "PAY_PER_REQUEST"
            if attrs.read_capacity || attrs.write_capacity
              raise Dry::Struct::Error, "PAY_PER_REQUEST billing mode does not support read_capacity or write_capacity"
            end
            
            # Validate GSI capacity settings for PAY_PER_REQUEST mode
            attrs.global_secondary_index.each do |gsi|
              if gsi[:read_capacity] || gsi[:write_capacity]
                raise Dry::Struct::Error, "GSI '#{gsi[:name]}' does not support capacity settings for PAY_PER_REQUEST billing mode"
              end
            end
          end

          # Validate stream configuration
          if attrs.stream_enabled && !attrs.stream_view_type
            raise Dry::Struct::Error, "stream_view_type is required when stream_enabled is true"
          end
          
          if attrs.stream_view_type && !attrs.stream_enabled
            attrs = attrs.copy_with(stream_enabled: true)
          end

          # Validate attribute definitions
          all_key_attributes = [attrs.hash_key]
          all_key_attributes << attrs.range_key if attrs.range_key
          
          attrs.global_secondary_index.each do |gsi|
            all_key_attributes << gsi[:hash_key]
            all_key_attributes << gsi[:range_key] if gsi[:range_key]
          end
          
          attrs.local_secondary_index.each do |lsi|
            all_key_attributes << lsi[:range_key]
          end
          
          defined_attributes = attrs.attribute.map { |attr| attr[:name] }
          missing_attributes = all_key_attributes.uniq - defined_attributes
          
          unless missing_attributes.empty?
            raise Dry::Struct::Error, "Missing attribute definitions for: #{missing_attributes.join(', ')}"
          end

          # Validate GSI projection settings
          attrs.global_secondary_index.each do |gsi|
            if gsi[:projection_type] == "INCLUDE" && (!gsi[:non_key_attributes] || gsi[:non_key_attributes].empty?)
              raise Dry::Struct::Error, "GSI '#{gsi[:name]}' with INCLUDE projection_type requires non_key_attributes"
            end
            
            if gsi[:projection_type] != "INCLUDE" && gsi[:non_key_attributes]
              raise Dry::Struct::Error, "GSI '#{gsi[:name]}' with #{gsi[:projection_type]} projection_type cannot have non_key_attributes"
            end
          end

          # Validate LSI projection settings
          attrs.local_secondary_index.each do |lsi|
            if lsi[:projection_type] == "INCLUDE" && (!lsi[:non_key_attributes] || lsi[:non_key_attributes].empty?)
              raise Dry::Struct::Error, "LSI '#{lsi[:name]}' with INCLUDE projection_type requires non_key_attributes"
            end
            
            if lsi[:projection_type] != "INCLUDE" && lsi[:non_key_attributes]
              raise Dry::Struct::Error, "LSI '#{lsi[:name]}' with #{lsi[:projection_type]} projection_type cannot have non_key_attributes"
            end
          end

          # Validate LSI limitations (max 10 LSIs per table)
          if attrs.local_secondary_index.size > 10
            raise Dry::Struct::Error, "Maximum of 10 Local Secondary Indexes allowed per table"
          end

          # Validate GSI limitations (max 20 GSIs per table)
          if attrs.global_secondary_index.size > 20
            raise Dry::Struct::Error, "Maximum of 20 Global Secondary Indexes allowed per table"
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

        def has_range_key?
          !range_key.nil?
        end

        def has_gsi?
          global_secondary_index.any?
        end

        def has_lsi?
          local_secondary_index.any?
        end

        def has_stream?
          stream_enabled == true
        end

        def has_ttl?
          !ttl.nil?
        end

        def has_encryption?
          !server_side_encryption.nil?
        end

        def has_pitr?
          point_in_time_recovery_enabled
        end

        def is_global_table?
          replica.any?
        end

        def total_indexes
          global_secondary_index.size + local_secondary_index.size
        end

        def estimated_monthly_cost
          return "Variable (Pay per request)" if is_pay_per_request?
          
          # Calculate based on provisioned capacity
          base_cost = 0.0
          
          # Table capacity
          if read_capacity && write_capacity
            read_cost = read_capacity * 0.00013 * 730  # $0.00013 per RCU per hour
            write_cost = write_capacity * 0.00065 * 730  # $0.00065 per WCU per hour
            base_cost += read_cost + write_cost
          end
          
          # GSI capacity
          global_secondary_index.each do |gsi|
            if gsi[:read_capacity] && gsi[:write_capacity]
              gsi_read_cost = gsi[:read_capacity] * 0.00013 * 730
              gsi_write_cost = gsi[:write_capacity] * 0.00065 * 730
              base_cost += gsi_read_cost + gsi_write_cost
            end
          end
          
          "~$#{base_cost.round(2)}/month (capacity only)"
        end
      end
      end

      # Common DynamoDB configurations
      module DynamoDbConfigs
        # Simple table with hash key only
        def self.simple_table(name, hash_key_name: "id", hash_key_type: "S")
          {
            name: name,
            billing_mode: "PAY_PER_REQUEST",
            attribute: [
              { name: hash_key_name, type: hash_key_type }
            ],
            hash_key: hash_key_name
          }
        end

        # Table with hash and range key
        def self.hash_range_table(name, hash_key_name: "pk", range_key_name: "sk", 
                                  hash_key_type: "S", range_key_type: "S")
          {
            name: name,
            billing_mode: "PAY_PER_REQUEST",
            attribute: [
              { name: hash_key_name, type: hash_key_type },
              { name: range_key_name, type: range_key_type }
            ],
            hash_key: hash_key_name,
            range_key: range_key_name
          }
        end

        # High-throughput provisioned table
        def self.high_throughput_table(name, read_capacity: 1000, write_capacity: 1000)
          {
            name: name,
            billing_mode: "PROVISIONED",
            read_capacity: read_capacity,
            write_capacity: write_capacity,
            attribute: [
              { name: "id", type: "S" }
            ],
            hash_key: "id",
            point_in_time_recovery_enabled: true,
            server_side_encryption: { enabled: true }
          }
        end

        # Table with GSI
        def self.table_with_gsi(name, gsi_name: "GSI1")
          {
            name: name,
            billing_mode: "PAY_PER_REQUEST",
            attribute: [
              { name: "pk", type: "S" },
              { name: "sk", type: "S" },
              { name: "gsi1pk", type: "S" },
              { name: "gsi1sk", type: "S" }
            ],
            hash_key: "pk",
            range_key: "sk",
            global_secondary_index: [
              {
                name: gsi_name,
                hash_key: "gsi1pk",
                range_key: "gsi1sk",
                projection_type: "ALL"
              }
            ]
          }
        end

        # Table with streams enabled
        def self.streaming_table(name, stream_view_type: "NEW_AND_OLD_IMAGES")
          {
            name: name,
            billing_mode: "PAY_PER_REQUEST",
            attribute: [
              { name: "id", type: "S" }
            ],
            hash_key: "id",
            stream_enabled: true,
            stream_view_type: stream_view_type
          }
        end

        # Table with TTL
        def self.ttl_table(name, ttl_attribute: "expires_at")
          {
            name: name,
            billing_mode: "PAY_PER_REQUEST",
            attribute: [
              { name: "id", type: "S" }
            ],
            hash_key: "id",
            ttl: {
              attribute_name: ttl_attribute,
              enabled: true
            }
          }
        end
      end
    end
  end
end