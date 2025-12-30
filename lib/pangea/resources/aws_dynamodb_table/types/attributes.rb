# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'instance_methods'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS DynamoDB Table resources
        class DynamoDbTableAttributes < Dry::Struct
          include DynamoDbTableInstanceMethods

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
        end
      end
    end
  end
end
