# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
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
