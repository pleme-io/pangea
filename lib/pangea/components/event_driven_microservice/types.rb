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
  module Components
    module EventDrivenMicroservice
      # Event source configuration
      class EventSource < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :type, Types::String.enum('EventBridge', 'SQS', 'SNS', 'Kinesis', 'DynamoDB')
        attribute :source_arn, Types::String.optional
        attribute :source_ref, Types::ResourceReference.optional
        attribute :event_pattern, Types::Hash.optional
        attribute :batch_size, Types::Integer.default(10)
        attribute :maximum_batching_window, Types::Integer.default(0)
        attribute :starting_position, Types::String.enum('TRIM_HORIZON', 'LATEST').optional
        attribute :parallelization_factor, Types::Integer.default(1)
        attribute :maximum_retry_attempts, Types::Integer.default(3)
        attribute :on_failure_destination_arn, Types::String.optional
      end
      
      # Event store configuration for event sourcing
      class EventStoreConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :table_name, Types::String
        attribute :stream_enabled, Types::Bool.default(true)
        attribute :ttl_days, Types::Integer.optional
        attribute :encryption_type, Types::String.enum('DEFAULT', 'KMS').default('KMS')
        attribute :kms_key_ref, Types::ResourceReference.optional
        attribute :point_in_time_recovery, Types::Bool.default(true)
        attribute :global_secondary_indexes, Types::Array.of(Types::Hash).default([].freeze)
      end
      
      # Command/Query separation configuration
      class CqrsConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :command_table_name, Types::String
        attribute :query_table_name, Types::String
        attribute :projection_enabled, Types::Bool.default(true)
        attribute :eventual_consistency_window, Types::Integer.default(1000) # milliseconds
      end
      
      # Saga orchestration configuration
      class SagaConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(false)
        attribute :state_machine_ref, Types::ResourceReference.optional
        attribute :compensation_enabled, Types::Bool.default(true)
        attribute :timeout_seconds, Types::Integer.default(300)
        attribute :retry_attempts, Types::Integer.default(3)
      end
      
      # Event replay configuration
      class EventReplayConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :snapshot_enabled, Types::Bool.default(true)
        attribute :snapshot_frequency, Types::Integer.default(100) # events
        attribute :replay_dead_letter_queue_ref, Types::ResourceReference.optional
      end
      
      # Lambda function configuration
      class FunctionConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :runtime, Types::String.default("python3.9")
        attribute :handler, Types::String
        attribute :timeout, Types::Integer.default(60)
        attribute :memory_size, Types::Integer.default(512)
        attribute :environment_variables, Types::Hash.default({}.freeze)
        attribute :layers, Types::Array.of(Types::String).default([].freeze)
        attribute :reserved_concurrent_executions, Types::Integer.optional
        attribute :dead_letter_config_arn, Types::String.optional
      end
      
      # Monitoring and alerting configuration
      class MonitoringConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :dashboard_enabled, Types::Bool.default(true)
        attribute :alarm_email, Types::String.optional
        attribute :event_processing_threshold, Types::Integer.default(1000) # ms
        attribute :error_rate_threshold, Types::Float.default(0.01) # 1%
        attribute :dead_letter_threshold, Types::Integer.default(10)
      end
      
      # Main component attributes
      class EventDrivenMicroserviceAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Core configuration
        attribute :service_name, Types::String
        attribute :service_description, Types::String.default("Event-driven microservice")
        
        # Event sources
        attribute :event_sources, Types::Array.of(EventSource).constrained(min_size: 1)
        
        # Function configuration
        attribute :command_handler, FunctionConfig
        attribute :query_handler, FunctionConfig.optional
        attribute :event_processor, FunctionConfig.optional
        
        # Event sourcing configuration
        attribute :event_store, EventStoreConfig
        attribute :cqrs, CqrsConfig.optional
        attribute :saga, SagaConfig.optional
        attribute :event_replay, EventReplayConfig.default { EventReplayConfig.new({}) }
        
        # Infrastructure
        attribute :vpc_ref, Types::ResourceReference.optional
        attribute :subnet_refs, Types::Array.of(Types::ResourceReference).default([].freeze)
        attribute :security_group_refs, Types::Array.of(Types::ResourceReference).default([].freeze)
        
        # Dead letter queue configuration
        attribute :dead_letter_queue_enabled, Types::Bool.default(true)
        attribute :dead_letter_max_receive_count, Types::Integer.default(3)
        
        # API Gateway integration (optional)
        attribute :api_gateway_enabled, Types::Bool.default(false)
        attribute :api_gateway_ref, Types::ResourceReference.optional
        
        # Monitoring
        attribute :monitoring, MonitoringConfig.default { MonitoringConfig.new({}) }
        
        # Tags
        attribute :tags, Types::Hash.default({}.freeze)
        
        # Custom validations
        def validate!
          errors = []
          
          # Validate event sources
          event_sources.each do |source|
            unless source.source_arn || source.source_ref
              errors << "Event source must have either source_arn or source_ref"
            end
            
            if source.type == 'EventBridge' && !source.event_pattern
              errors << "EventBridge source requires event_pattern"
            end
            
            if ['Kinesis', 'DynamoDB'].include?(source.type) && !source.starting_position
              errors << "#{source.type} source requires starting_position"
            end
          end
          
          # Validate function configurations
          if command_handler.memory_size < 128 || command_handler.memory_size > 10240
            errors << "Function memory must be between 128 and 10240 MB"
          end
          
          if command_handler.timeout < 1 || command_handler.timeout > 900
            errors << "Function timeout must be between 1 and 900 seconds"
          end
          
          # Validate CQRS configuration
          if cqrs&.enabled
            if cqrs.command_table_name == cqrs.query_table_name
              errors << "Command and query tables must be different for CQRS"
            end
            
            unless query_handler
              errors << "CQRS requires a query_handler to be configured"
            end
          end
          
          # Validate saga configuration
          if saga&.enabled && !saga.state_machine_ref
            errors << "Saga orchestration requires a state machine reference"
          end
          
          # Validate event replay configuration
          if event_replay.enabled && !event_store.stream_enabled
            errors << "Event replay requires event store streams to be enabled"
          end
          
          # Validate VPC configuration
          if vpc_ref && subnet_refs.empty?
            errors << "VPC configuration requires at least one subnet"
          end
          
          # Validate monitoring thresholds
          if monitoring.error_rate_threshold < 0 || monitoring.error_rate_threshold > 1
            errors << "Error rate threshold must be between 0 and 1"
          end
          
          raise ArgumentError, errors.join(", ") unless errors.empty?
          
          true
        end
      end
    end
  end
end