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
  module Resources
    module AWS
      module Types
        # Lambda event source mapping attributes with validation
        class LambdaEventSourceMappingAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :event_source_arn, Resources::Types::String
          attribute :function_name, Resources::Types::String
          
          # Optional attributes
          attribute :enabled, Resources::Types::Bool.default(true)
          attribute :batch_size, Resources::Types::Integer.default(10)
          attribute :maximum_batching_window_in_seconds, Resources::Types::Integer.constrained(gteq: 0, lteq: 300).optional
          attribute :parallelization_factor, Resources::Types::Integer.constrained(gteq: 1, lteq: 10).optional
          attribute :starting_position, Resources::Types::LambdaEventSourcePosition.optional
          attribute :starting_position_timestamp, Resources::Types::String.optional
          attribute :maximum_record_age_in_seconds, Resources::Types::Integer.constrained(gteq: 60, lteq: 604800).optional
          attribute :bisect_batch_on_function_error, Resources::Types::Bool.default(false)
          attribute :maximum_retry_attempts, Resources::Types::Integer.constrained(gteq: 0, lteq: 10000).optional
          attribute :tumbling_window_in_seconds, Resources::Types::Integer.constrained(gteq: 0, lteq: 900).optional
          
          # Destination configuration
          attribute :destination_config, Resources::Types::Hash.schema(
            on_failure?: Resources::Types::LambdaDestinationOnFailure.optional
          ).optional
          
          # Self-managed event source (Kafka)
          attribute :self_managed_event_source, Resources::Types::LambdaSelfManagedEventSource.optional
          
          # Source access configurations
          attribute :source_access_configuration, Resources::Types::Array.of(
            Resources::Types::LambdaSourceAccessConfiguration
          ).default([].freeze)
          
          # Event source specific configurations
          attribute :topics, Resources::Types::Array.of(Resources::Types::String).optional
          attribute :queues, Resources::Types::Array.of(Resources::Types::String).optional
          
          # Filter criteria
          attribute :filter_criteria, Resources::Types::Hash.schema(
            filters?: Resources::Types::Array.of(
              Resources::Types::Hash.schema(
                pattern?: Resources::Types::String.optional
              )
            ).optional
          ).optional
          
          # Scaling configuration
          attribute :scaling_config, Resources::Types::Hash.schema(
            maximum_concurrency?: Resources::Types::Integer.constrained(gteq: 2, lteq: 1000).optional
          ).optional
          
          # Amazon MQ specific
          attribute :amazon_managed_kafka_event_source_config, Resources::Types::Hash.schema(
            consumer_group_id?: Resources::Types::String.optional
          ).optional
          
          # Self-managed Kafka specific
          attribute :self_managed_kafka_event_source_config, Resources::Types::Hash.schema(
            consumer_group_id?: Resources::Types::String.optional
          ).optional
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Determine event source type from ARN
            if attrs[:event_source_arn]
              source_type = detect_source_type(attrs[:event_source_arn])
              
              # Validate batch size based on source type
              validate_batch_size(attrs[:batch_size], source_type) if attrs[:batch_size]
              
              # Validate starting position for stream sources
              if %w[kinesis dynamodb].include?(source_type)
                if attrs[:starting_position].nil? && !attrs[:event_source_arn].include?('table/')
                  raise Dry::Struct::Error, "starting_position is required for #{source_type} event sources"
                end
              elsif attrs[:starting_position]
                raise Dry::Struct::Error, "starting_position is only valid for Kinesis and DynamoDB streams"
              end
              
              # Validate parallelization factor
              if attrs[:parallelization_factor] && source_type != 'kinesis'
                raise Dry::Struct::Error, "parallelization_factor is only valid for Kinesis event sources"
              end
              
              # Validate tumbling window
              if attrs[:tumbling_window_in_seconds] && !%w[kinesis dynamodb].include?(source_type)
                raise Dry::Struct::Error, "tumbling_window_in_seconds is only valid for Kinesis and DynamoDB streams"
              end
              
              # Validate topics/queues
              if attrs[:topics] && !%w[msk self-managed-kafka].include?(source_type)
                raise Dry::Struct::Error, "topics is only valid for Kafka event sources"
              end
              
              if attrs[:queues] && source_type != 'rabbitmq'
                raise Dry::Struct::Error, "queues is only valid for RabbitMQ event sources"
              end
            end
            
            # Validate self-managed event source
            if attrs[:self_managed_event_source] && !attrs[:event_source_arn]&.start_with?('arn:aws:kafka')
              raise Dry::Struct::Error, "self_managed_event_source requires a self-managed Kafka event source"
            end
            
            # Validate starting position timestamp
            if attrs[:starting_position_timestamp] && attrs[:starting_position] != 'AT_TIMESTAMP'
              raise Dry::Struct::Error, "starting_position_timestamp requires starting_position to be AT_TIMESTAMP"
            end
            
            super(attrs)
          end
          
          # Detect event source type from ARN
          def self.detect_source_type(arn)
            case arn
            when /kinesis/ then 'kinesis'
            when /dynamodb.*stream/ then 'dynamodb'
            when /sqs/ then 'sqs'
            when /kafka.*cluster/ then 'msk'
            when /mq:broker/ then 'rabbitmq'
            when /sns/ then 'sns'
            else 'unknown'
            end
          end
          
          # Validate batch size based on source type
          def self.validate_batch_size(batch_size, source_type)
            limits = {
              'kinesis' => { min: 1, max: 10000 },
              'dynamodb' => { min: 1, max: 10000 },
              'sqs' => { min: 1, max: 10000 },
              'msk' => { min: 1, max: 10000 },
              'rabbitmq' => { min: 1, max: 10000 }
            }
            
            if limits[source_type]
              min, max = limits[source_type].values_at(:min, :max)
              unless batch_size.between?(min, max)
                raise Dry::Struct::Error, "batch_size must be between #{min} and #{max} for #{source_type}"
              end
            end
          end
          
          # Computed properties
          def source_type
            self.class.detect_source_type(event_source_arn)
          end
          
          def is_stream_source?
            %w[kinesis dynamodb].include?(source_type)
          end
          
          def is_queue_source?
            %w[sqs rabbitmq].include?(source_type)
          end
          
          def is_kafka_source?
            %w[msk self-managed-kafka].include?(source_type)
          end
          
          def supports_batching_window?
            %w[kinesis dynamodb sqs msk rabbitmq].include?(source_type)
          end
          
          def supports_parallelization?
            source_type == 'kinesis'
          end
          
          def supports_error_handling?
            %w[kinesis dynamodb sqs].include?(source_type)
          end
        end
      end
    end
  end
end