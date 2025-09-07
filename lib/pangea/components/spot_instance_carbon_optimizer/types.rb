# frozen_string_literal: true

require "dry-struct"
require "dry-types"

module Pangea
  module Components
    module SpotInstanceCarbonOptimizer
      module Types
        include Dry.Types()

        # Enums for optimization strategies
        OptimizationStrategy = Types::Coercible::String.enum(
          'carbon_first',      # Prioritize lowest carbon regions
          'cost_first',        # Prioritize lowest cost regions
          'balanced',          # Balance carbon and cost
          'renewable_only',    # Only use renewable-heavy regions
          'follow_the_sun'     # Follow renewable energy availability
        )

        WorkloadType = Types::Coercible::String.enum(
          'stateless',         # Can migrate anytime
          'batch',             # Can checkpoint and resume
          'distributed',       # Multi-region capable
          'gpu_compute',       # GPU-intensive workloads
          'memory_intensive'   # High memory requirements
        )

        MigrationStrategy = Types::Coercible::String.enum(
          'live_migration',    # Migrate without stopping
          'checkpoint_restore', # Save state and restore
          'blue_green',        # Run parallel then switch
          'drain_and_shift'    # Gracefully drain then move
        )

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

        # Output structure containing created resources
        class Output < Dry::Struct
          # Spot fleet requests (per region)
          attribute :spot_fleets, Types::Hash.map(Types::Strict::String, Types::Any)
          
          # Lambda functions
          attribute :carbon_monitor_function, Types::Any
          attribute :fleet_optimizer_function, Types::Any
          attribute :migration_orchestrator_function, Types::Any
          
          # DynamoDB tables
          attribute :fleet_state_table, Types::Any
          attribute :carbon_data_table, Types::Any
          attribute :migration_history_table, Types::Any
          
          # EventBridge rules
          attribute :optimization_schedule, Types::Any
          attribute :carbon_check_schedule, Types::Any
          attribute :spot_interruption_rule, Types::Any
          
          # CloudWatch components
          attribute :carbon_dashboard, Types::Any
          attribute :efficiency_metrics, Types::Array.of(Types::Any)
          attribute :carbon_alarms, Types::Array.of(Types::Any)
          
          # IAM roles
          attribute :fleet_role, Types::Any
          attribute :lambda_role, Types::Any
          
          def active_regions
            spot_fleets.keys
          end
          
          def total_capacity
            spot_fleets.values.sum { |fleet| fleet.target_capacity || 0 }
          end
          
          def dashboard_url
            "https://console.aws.amazon.com/cloudwatch/home?region=#{carbon_dashboard.region}#dashboards:name=#{carbon_dashboard.dashboard_name}"
          end
        end

        # Regional carbon intensity data
        REGIONAL_CARBON_BASELINE = {
          'us-east-1' => 400,      # Virginia - mixed grid
          'us-east-2' => 450,      # Ohio - coal heavy
          'us-west-1' => 250,      # California - mixed renewables
          'us-west-2' => 50,       # Oregon - hydro
          'eu-central-1' => 350,   # Frankfurt - mixed
          'eu-west-1' => 80,       # Ireland - wind heavy
          'eu-north-1' => 40,      # Stockholm - renewable
          'ca-central-1' => 30,    # Montreal - hydro
          'ap-southeast-1' => 600, # Singapore - gas
          'ap-southeast-2' => 700, # Sydney - coal heavy
          'sa-east-1' => 100       # Sao Paulo - hydro
        }.freeze

        # Validation methods
        def self.validate_capacity(capacity)
          raise ArgumentError, "Target capacity must be positive" if capacity <= 0
          raise ArgumentError, "Target capacity cannot exceed 1000 for spot optimizer" if capacity > 1000
        end

        def self.validate_carbon_threshold(threshold)
          raise ArgumentError, "Carbon threshold must be between 0 and 1000 gCO2/kWh" unless (0..1000).include?(threshold)
        end

        def self.validate_regions(allowed, preferred)
          invalid = preferred - allowed
          raise ArgumentError, "Preferred regions must be subset of allowed regions: #{invalid.join(', ')}" unless invalid.empty?
        end

        def self.validate_spot_block_duration(use_blocks, duration)
          return unless use_blocks
          raise ArgumentError, "Spot block duration required when use_spot_blocks is true" if duration.nil?
          raise ArgumentError, "Spot block duration must be 1-6 hours" unless (1..6).include?(duration)
        end
      end
    end
  end
end