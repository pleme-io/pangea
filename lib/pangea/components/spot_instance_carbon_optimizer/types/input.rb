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
require_relative "enums"

module Pangea
  module Components
    module SpotInstanceCarbonOptimizer
      module Types
        # Input structure for spot instance carbon optimizer
        class Input < Dry::Struct
          attribute :name, Types::Strict::String

          # Spot fleet configuration
          attribute :target_capacity, Types::Coercible::Integer
          attribute :workload_type, WorkloadType
          attribute :instance_types, Types::Array.of(Types::Strict::String).constrained(min_size: 1)

          # Carbon optimization settings
          attribute :optimization_strategy, OptimizationStrategy.default('balanced')
          attribute :carbon_intensity_threshold, Types::Coercible::Integer.default(200)
          attribute :renewable_percentage_minimum, Types::Coercible::Integer.default(50)

          # Regional preferences
          attribute :allowed_regions, Types::Array.of(Types::Strict::String).default([
            'us-west-2',     # Oregon - 80% renewable
            'us-west-1',     # California - 50% renewable
            'eu-north-1',    # Stockholm - 95% renewable
            'eu-west-1',     # Ireland - Carbon neutral
            'ca-central-1',  # Montreal - 99% hydro
            'eu-central-1',  # Frankfurt - 40% renewable
            'ap-southeast-2', # Sydney - 20% renewable
            'sa-east-1'      # Sao Paulo - 80% hydro
          ].freeze)
          attribute :preferred_regions, Types::Array.of(Types::Strict::String).default([
            'us-west-2',
            'eu-north-1',
            'ca-central-1'
          ].freeze)

          # Migration settings
          attribute :migration_strategy, MigrationStrategy.default('checkpoint_restore')
          attribute :migration_threshold_minutes, Types::Coercible::Integer.default(5)
          attribute :enable_cross_region_migration, Types::Strict::Bool.default(true)

          # Spot configuration
          attribute :spot_price_buffer_percentage, Types::Coercible::Integer.default(20)
          attribute :interruption_behavior, Types::Strict::String.default('terminate')
          attribute :use_spot_blocks, Types::Strict::Bool.default(false)
          attribute :spot_block_duration_hours, Types::Coercible::Integer.optional.default(nil)

          # Performance requirements
          attribute :min_cpu_units, Types::Coercible::Integer.default(2)
          attribute :min_memory_gb, Types::Coercible::Integer.default(4)
          attribute :require_gpu, Types::Strict::Bool.default(false)
          attribute :network_performance, Types::Strict::String.default('moderate')

          # Monitoring and alerts
          attribute :enable_carbon_monitoring, Types::Strict::Bool.default(true)
          attribute :enable_cost_monitoring, Types::Strict::Bool.default(true)
          attribute :alert_on_high_carbon, Types::Strict::Bool.default(true)
          attribute :carbon_reporting_interval_minutes, Types::Coercible::Integer.default(15)

          # VPC configuration (per region)
          attribute :vpc_configs, Types::Hash.map(
            Types::Strict::String, # region
            Types::Hash.map(Types::Strict::Symbol, Types::Strict::String) # vpc_id, subnet_ids
          ).default({})

          # Tags
          attribute :tags, Types::Hash.map(Types::Coercible::String, Types::Coercible::String).default({})

          def self.example
            new(
              name: "carbon-optimized-compute-fleet",
              target_capacity: 10,
              workload_type: "batch",
              instance_types: ["t3.large", "t3a.large", "t4g.large"],
              optimization_strategy: "balanced",
              enable_cross_region_migration: true,
              vpc_configs: {
                "us-west-2" => { vpc_id: "vpc-12345", subnet_ids: "subnet-1a,subnet-1b" },
                "eu-north-1" => { vpc_id: "vpc-67890", subnet_ids: "subnet-2a,subnet-2b" }
              },
              tags: {
                "Environment" => "production",
                "Sustainability" => "carbon-optimized"
              }
            )
          end
        end
      end
    end
  end
end
