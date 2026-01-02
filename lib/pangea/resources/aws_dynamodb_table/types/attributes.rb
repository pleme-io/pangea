# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'instance_methods'
require_relative 'validations'

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
            attrs = enable_stream_if_view_type_set(attrs)
            DynamoDbTableValidations.validate!(attrs)
          end

          def self.enable_stream_if_view_type_set(attrs)
            if attrs.stream_view_type && !attrs.stream_enabled
              attrs.copy_with(stream_enabled: true)
            else
              attrs
            end
          end
        end
      end
    end
  end
end
