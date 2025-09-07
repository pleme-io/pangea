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


require "dry-struct"
require "dry-types"

module Pangea
  module Components
    module GreenDataLifecycle
      module Types
        include Dry.Types()

        # Enums for lifecycle strategies
        LifecycleStrategy = Types::Coercible::String.enum(
          'access_pattern_based',  # Move based on actual access patterns
          'time_based',           # Move based on age
          'size_based',           # Archive large objects first
          'carbon_optimized',     # Optimize for lowest carbon storage
          'cost_optimized'        # Optimize for lowest cost
        )

        StorageClass = Types::Coercible::String.enum(
          'STANDARD',
          'INTELLIGENT_TIERING',
          'STANDARD_IA',
          'ONEZONE_IA',
          'GLACIER_IR',
          'GLACIER_FLEXIBLE',
          'DEEP_ARCHIVE'
        )

        DataClassification = Types::Coercible::String.enum(
          'hot',      # Frequently accessed
          'warm',     # Occasionally accessed
          'cool',     # Rarely accessed
          'cold',     # Archive
          'frozen'    # Deep archive
        )

        # Input structure for green data lifecycle
        class Input < Dry::Struct
          attribute :name, Types::Strict::String
          attribute :bucket_prefix, Types::Strict::String.optional.default(nil)
          
          # Lifecycle configuration
          attribute :lifecycle_strategy, LifecycleStrategy.default('carbon_optimized')
          attribute :enable_intelligent_tiering, Types::Strict::Bool.default(true)
          attribute :enable_glacier_archive, Types::Strict::Bool.default(true)
          
          # Transition rules (days)
          attribute :transition_to_ia_days, Types::Coercible::Integer.default(30)
          attribute :transition_to_glacier_ir_days, Types::Coercible::Integer.default(90)
          attribute :transition_to_glacier_days, Types::Coercible::Integer.default(180)
          attribute :transition_to_deep_archive_days, Types::Coercible::Integer.default(365)
          attribute :expire_days, Types::Coercible::Integer.optional.default(nil)
          
          # Access pattern configuration
          attribute :monitor_access_patterns, Types::Strict::Bool.default(true)
          attribute :access_pattern_window_days, Types::Coercible::Integer.default(90)
          attribute :optimize_for_read_heavy, Types::Strict::Bool.default(false)
          
          # Size-based rules
          attribute :large_object_threshold_mb, Types::Coercible::Integer.default(100)
          attribute :archive_large_objects_days, Types::Coercible::Integer.default(7)
          
          # Carbon optimization
          attribute :prefer_renewable_regions, Types::Strict::Bool.default(true)
          attribute :carbon_threshold_gco2_per_gb, Types::Coercible::Float.default(0.5)
          
          # Compliance and governance
          attribute :compliance_mode, Types::Strict::Bool.default(false)
          attribute :legal_hold_tags, Types::Array.of(Types::Strict::String).default([])
          attribute :deletion_protection, Types::Strict::Bool.default(true)
          
          # Monitoring
          attribute :enable_metrics, Types::Strict::Bool.default(true)
          attribute :enable_inventory, Types::Strict::Bool.default(true)
          attribute :alert_on_high_storage_carbon, Types::Strict::Bool.default(true)
          
          # Tags
          attribute :tags, Types::Hash.map(Types::Coercible::String, Types::Coercible::String).default({})

          def self.example
            new(
              name: "sustainable-data-storage",
              bucket_prefix: "green-data",
              lifecycle_strategy: "carbon_optimized",
              enable_intelligent_tiering: true,
              monitor_access_patterns: true,
              prefer_renewable_regions: true,
              tags: {
                "Environment" => "production",
                "Sustainability" => "enabled"
              }
            )
          end
        end

        # Output structure containing created resources
        class Output < Dry::Struct
          # S3 buckets
          attribute :primary_bucket, Types::Any
          attribute :archive_bucket, Types::Any.optional
          
          # Lifecycle configurations
          attribute :lifecycle_configuration, Types::Any
          attribute :intelligent_tiering_configuration, Types::Any.optional
          
          # Glacier vault for deep archive
          attribute :glacier_vault, Types::Any.optional
          
          # Lambda functions
          attribute :access_analyzer_function, Types::Any
          attribute :carbon_optimizer_function, Types::Any
          attribute :lifecycle_manager_function, Types::Any
          
          # CloudWatch components
          attribute :storage_metrics, Types::Array.of(Types::Any)
          attribute :carbon_dashboard, Types::Any
          attribute :efficiency_alarms, Types::Array.of(Types::Any)
          
          # S3 Inventory
          attribute :inventory_configuration, Types::Any.optional
          
          # IAM roles
          attribute :lifecycle_role, Types::Any
          attribute :analyzer_role, Types::Any
          
          def primary_bucket_name
            primary_bucket.bucket
          end
          
          def archive_bucket_name
            archive_bucket&.bucket
          end
          
          def dashboard_url
            "https://console.aws.amazon.com/cloudwatch/home?region=#{carbon_dashboard.region}#dashboards:name=#{carbon_dashboard.dashboard_name}"
          end
        end

        # Carbon intensity by storage class (gCO2/GB/month)
        STORAGE_CARBON_INTENSITY = {
          'STANDARD' => 0.55,
          'INTELLIGENT_TIERING' => 0.45,  # Optimized storage
          'STANDARD_IA' => 0.35,          # Less active storage
          'ONEZONE_IA' => 0.30,           # Single AZ
          'GLACIER_IR' => 0.15,           # Cold storage
          'GLACIER_FLEXIBLE' => 0.10,     # Archival
          'DEEP_ARCHIVE' => 0.05          # Tape storage
        }.freeze

        # Validation methods
        def self.validate_transition_days(ia, glacier_ir, glacier, deep_archive)
          raise ArgumentError, "Transition days must be in ascending order" unless ia < glacier_ir && glacier_ir < glacier && glacier < deep_archive
          raise ArgumentError, "Minimum 30 days before first transition" if ia < 30
        end

        def self.validate_carbon_threshold(threshold)
          raise ArgumentError, "Carbon threshold must be positive" if threshold <= 0
          raise ArgumentError, "Carbon threshold unrealistically low" if threshold < 0.01
        end

        def self.validate_access_window(window_days)
          raise ArgumentError, "Access pattern window must be at least 7 days" if window_days < 7
          raise ArgumentError, "Access pattern window cannot exceed 365 days" if window_days > 365
        end
      end
    end
  end
end