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

require_relative 'types/event_source'
require_relative 'types/event_store_config'
require_relative 'types/cqrs_config'
require_relative 'types/saga_config'
require_relative 'types/event_replay_config'
require_relative 'types/function_config'
require_relative 'types/monitoring_config'

module Pangea
  module Components
    module EventDrivenMicroservice
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
