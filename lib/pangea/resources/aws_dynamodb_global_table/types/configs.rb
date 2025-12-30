# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
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
