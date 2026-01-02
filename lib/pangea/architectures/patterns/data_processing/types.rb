# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Architectures
    module Patterns
      module DataProcessing
        Types = Pangea::Resources::Types

        # Data lake architecture attributes
        class DataLakeAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Core configuration
          attribute :data_lake_name, Types::String
          attribute :environment, Types::String.default('development').enum('development', 'staging', 'production')
          attribute :vpc_cidr, Types::String.default('10.1.0.0/16')
          attribute :availability_zones, Types::Array.of(Types::String).default(%w[us-east-1a us-east-1b].freeze)

          # Data sources
          attribute :data_sources, Types::Array.of(Types::String).default(%w[s3 rds kinesis].freeze)
          attribute :real_time_processing, Types::Bool.default(true)
          attribute :batch_processing, Types::Bool.default(true)

          # Storage configuration
          attribute :raw_data_retention_days, Types::Integer.default(2555)
          attribute :processed_data_retention_days, Types::Integer.default(365)
          attribute :data_encryption, Types::Bool.default(true)
          attribute :cross_region_replication, Types::Bool.default(false)

          # Processing configuration
          attribute :batch_processing_schedule, Types::String.default('daily').enum('hourly', 'daily', 'weekly')
          attribute :streaming_buffer_size, Types::Integer.default(128)
          attribute :streaming_buffer_interval, Types::Integer.default(60)

          # Analytics configuration
          attribute :data_warehouse, Types::String.default('athena').enum('redshift', 'snowflake', 'athena', 'none')
          attribute :machine_learning, Types::Bool.default(false)
          attribute :business_intelligence, Types::Bool.default(true)

          # Compute configuration
          attribute :emr_enabled, Types::Bool.default(true)
          attribute :glue_enabled, Types::Bool.default(true)
          attribute :lambda_enabled, Types::Bool.default(true)

          attribute :tags, Types::Hash.default({}.freeze)
        end

        # Real-time streaming architecture attributes
        class StreamingArchitectureAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Stream configuration
          attribute :stream_name, Types::String
          attribute :stream_type, Types::String.default('kinesis').enum('kinesis', 'kafka', 'pulsar')
          attribute :shard_count, Types::Integer.default(1)
          attribute :retention_hours, Types::Integer.default(24)

          # Processing configuration
          attribute :stream_processing_framework, Types::String.default('kinesis-analytics').enum('kinesis-analytics', 'flink', 'spark-streaming')
          attribute :windowing_strategy, Types::String.default('tumbling').enum('tumbling', 'sliding', 'session')
          attribute :window_size_minutes, Types::Integer.default(5)

          # Output configuration
          attribute :output_destinations, Types::Array.of(Types::String).default(%w[s3 elasticsearch dynamodb].freeze)
          attribute :error_handling, Types::String.default('dlq').enum('retry', 'dlq', 'ignore')

          # Monitoring
          attribute :monitoring_enabled, Types::Bool.default(true)
          attribute :alerting_enabled, Types::Bool.default(true)

          attribute :tags, Types::Hash.default({}.freeze)
        end
      end
    end
  end
end
