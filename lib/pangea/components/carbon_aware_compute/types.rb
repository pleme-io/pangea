# frozen_string_literal: true

require "dry-struct"
require "dry-types"

module Pangea
  module Components
    module CarbonAwareCompute
      module Types
        include Dry.Types()

        # Enums for carbon awareness strategies
        CarbonOptimizationStrategy = Types::Coercible::String.enum(
          'time_shifting',      # Shift workloads to lower carbon intensity times
          'location_shifting',  # Move workloads to greener regions
          'combined',          # Use both time and location shifting
          'efficiency_first'   # Optimize for computational efficiency
        )

        WorkloadType = Types::Coercible::String.enum(
          'batch',        # Batch processing jobs
          'streaming',    # Real-time streaming workloads
          'ml_training',  # Machine learning training
          'web_service',  # Web application services
          'data_pipeline' # Data processing pipelines
        )

        CarbonIntensityLevel = Types::Coercible::String.enum(
          'very_low',   # < 50 gCO2/kWh
          'low',        # 50-150 gCO2/kWh
          'medium',     # 150-300 gCO2/kWh
          'high',       # 300-500 gCO2/kWh
          'very_high'   # > 500 gCO2/kWh
        )

        # Input structure for carbon aware compute
        class Input < Dry::Struct
          attribute :name, Types::Strict::String
          attribute :workload_type, WorkloadType
          attribute :optimization_strategy, CarbonOptimizationStrategy.default('combined')
          
          # VPC configuration
          attribute :vpc_id, Types::Strict::String
          attribute :subnet_ids, Types::Array.of(Types::Strict::String).constrained(min_size: 1)
          
          # Carbon awareness configuration
          attribute :carbon_intensity_threshold, Types::Coercible::Integer.default(150)
          attribute :preferred_regions, Types::Array.of(Types::Strict::String).default([
            'us-west-2',    # Oregon - high renewable energy
            'eu-north-1',   # Stockholm - high renewable energy
            'eu-west-1',    # Ireland - carbon neutral
            'ca-central-1'  # Canada - hydroelectric power
          ].freeze)
          
          # Workload configuration
          attribute :min_execution_window_hours, Types::Coercible::Integer.default(1)
          attribute :max_execution_window_hours, Types::Coercible::Integer.default(24)
          attribute :deadline_hours, Types::Coercible::Integer.optional.default(nil)
          
          # Performance configuration
          attribute :cpu_units, Types::Coercible::Integer.default(256)
          attribute :memory_mb, Types::Coercible::Integer.default(512)
          attribute :ephemeral_storage_gb, Types::Coercible::Integer.default(20)
          
          # Monitoring and reporting
          attribute :enable_carbon_reporting, Types::Strict::Bool.default(true)
          attribute :enable_cost_optimization, Types::Strict::Bool.default(true)
          attribute :alert_on_high_carbon, Types::Strict::Bool.default(true)
          
          # Advanced options
          attribute :use_graviton, Types::Strict::Bool.default(true)
          attribute :use_spot_instances, Types::Strict::Bool.default(true)
          attribute :carbon_data_source, Types::Strict::String.default('electricity-maps')
          
          # Tags
          attribute :tags, Types::Hash.map(Types::Coercible::String, Types::Coercible::String).default({})

          def self.example
            new(
              name: "carbon-aware-batch-processor",
              workload_type: "batch",
              vpc_id: "vpc-12345",
              subnet_ids: ["subnet-1a", "subnet-1b"],
              optimization_strategy: "combined",
              carbon_intensity_threshold: 100,
              deadline_hours: 48,
              tags: {
                "Environment" => "production",
                "Sustainability" => "enabled"
              }
            )
          end
        end

        # Output structure containing created resources
        class Output < Dry::Struct
          # Lambda functions
          attribute :scheduler_function, Types::Any # Lambda for carbon-aware scheduling
          attribute :executor_function, Types::Any  # Lambda for workload execution
          attribute :monitor_function, Types::Any   # Lambda for carbon monitoring
          
          # EventBridge components
          attribute :scheduler_rule, Types::Any     # Scheduler rule
          attribute :carbon_check_rule, Types::Any  # Carbon intensity check rule
          
          # DynamoDB tables
          attribute :workload_table, Types::Any     # Workload queue and state
          attribute :carbon_data_table, Types::Any  # Carbon intensity data cache
          
          # CloudWatch components
          attribute :carbon_metric, Types::Any      # Carbon emissions metric
          attribute :efficiency_metric, Types::Any  # Computational efficiency metric
          attribute :dashboard, Types::Any          # Monitoring dashboard
          
          # IAM roles
          attribute :execution_role, Types::Any     # Lambda execution role
          attribute :scheduler_role, Types::Any     # EventBridge scheduler role
          
          # CloudWatch alarms
          attribute :high_carbon_alarm, Types::Any.optional  # High carbon intensity alarm
          attribute :efficiency_alarm, Types::Any.optional   # Low efficiency alarm
          
          def scheduler_function_arn
            scheduler_function.arn
          end
          
          def workload_table_name
            workload_table.table_name
          end
          
          def dashboard_url
            "https://console.aws.amazon.com/cloudwatch/home?region=#{dashboard.region}#dashboards:name=#{dashboard.dashboard_name}"
          end
        end

        # Validation methods
        def self.validate_carbon_threshold(threshold)
          raise ArgumentError, "Carbon intensity threshold must be between 0 and 1000 gCO2/kWh" unless (0..1000).include?(threshold)
        end

        def self.validate_execution_window(min_hours, max_hours)
          raise ArgumentError, "Min execution window must be less than max" if min_hours > max_hours
          raise ArgumentError, "Max execution window cannot exceed 168 hours (1 week)" if max_hours > 168
        end

        def self.validate_deadline(deadline_hours, max_window)
          return if deadline_hours.nil?
          raise ArgumentError, "Deadline must be at least as long as max execution window" if deadline_hours < max_window
        end
      end
    end
  end
end