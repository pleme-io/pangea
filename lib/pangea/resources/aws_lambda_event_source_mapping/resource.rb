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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_lambda_event_source_mapping/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Lambda event source mapping for stream and queue triggers
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Event source mapping attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_lambda_event_source_mapping(name, attributes = {})
        # Validate attributes using dry-struct
        mapping_attrs = Types::Types::LambdaEventSourceMappingAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_lambda_event_source_mapping, name) do
          event_source_arn mapping_attrs.event_source_arn
          function_name mapping_attrs.function_name
          enabled mapping_attrs.enabled
          batch_size mapping_attrs.batch_size
          
          # Optional batching window
          maximum_batching_window_in_seconds mapping_attrs.maximum_batching_window_in_seconds if mapping_attrs.maximum_batching_window_in_seconds
          
          # Stream-specific configurations
          if mapping_attrs.is_stream_source?
            starting_position mapping_attrs.starting_position if mapping_attrs.starting_position
            starting_position_timestamp mapping_attrs.starting_position_timestamp if mapping_attrs.starting_position_timestamp
            parallelization_factor mapping_attrs.parallelization_factor if mapping_attrs.parallelization_factor
            tumbling_window_in_seconds mapping_attrs.tumbling_window_in_seconds if mapping_attrs.tumbling_window_in_seconds
          end
          
          # Error handling configurations
          maximum_record_age_in_seconds mapping_attrs.maximum_record_age_in_seconds if mapping_attrs.maximum_record_age_in_seconds
          bisect_batch_on_function_error mapping_attrs.bisect_batch_on_function_error
          maximum_retry_attempts mapping_attrs.maximum_retry_attempts if mapping_attrs.maximum_retry_attempts
          
          # Destination configuration
          if mapping_attrs.destination_config && mapping_attrs.destination_config[:on_failure]
            destination_config do
              on_failure do
                destination mapping_attrs.destination_config[:on_failure][:destination]
              end
            end
          end
          
          # Self-managed event source
          if mapping_attrs.self_managed_event_source
            self_managed_event_source do
              endpoints do
                mapping_attrs.self_managed_event_source[:endpoints].each do |key, value|
                  public_send(key, value)
                end
              end
            end
          end
          
          # Source access configurations
          if mapping_attrs.source_access_configuration.any?
            mapping_attrs.source_access_configuration.each do |config|
              source_access_configuration do
                type config[:type]
                uri config[:uri]
              end
            end
          end
          
          # Kafka-specific configurations
          topics mapping_attrs.topics if mapping_attrs.topics
          queues mapping_attrs.queues if mapping_attrs.queues
          
          # Filter criteria
          if mapping_attrs.filter_criteria && mapping_attrs.filter_criteria[:filters]
            filter_criteria do
              mapping_attrs.filter_criteria[:filters].each do |filter|
                filter do
                  pattern filter[:pattern] if filter[:pattern]
                end
              end
            end
          end
          
          # Scaling configuration
          if mapping_attrs.scaling_config
            scaling_config do
              maximum_concurrency mapping_attrs.scaling_config[:maximum_concurrency] if mapping_attrs.scaling_config[:maximum_concurrency]
            end
          end
          
          # Amazon Managed Kafka configuration
          if mapping_attrs.amazon_managed_kafka_event_source_config
            amazon_managed_kafka_event_source_config do
              consumer_group_id mapping_attrs.amazon_managed_kafka_event_source_config[:consumer_group_id] if mapping_attrs.amazon_managed_kafka_event_source_config[:consumer_group_id]
            end
          end
          
          # Self-managed Kafka configuration
          if mapping_attrs.self_managed_kafka_event_source_config
            self_managed_kafka_event_source_config do
              consumer_group_id mapping_attrs.self_managed_kafka_event_source_config[:consumer_group_id] if mapping_attrs.self_managed_kafka_event_source_config[:consumer_group_id]
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_lambda_event_source_mapping',
          name: name,
          resource_attributes: mapping_attrs.to_h,
          outputs: {
            # Core outputs
            id: "${aws_lambda_event_source_mapping.#{name}.id}",
            uuid: "${aws_lambda_event_source_mapping.#{name}.uuid}",
            function_arn: "${aws_lambda_event_source_mapping.#{name}.function_arn}",
            last_modified: "${aws_lambda_event_source_mapping.#{name}.last_modified}",
            last_processing_result: "${aws_lambda_event_source_mapping.#{name}.last_processing_result}",
            state: "${aws_lambda_event_source_mapping.#{name}.state}",
            state_transition_reason: "${aws_lambda_event_source_mapping.#{name}.state_transition_reason}",
            
            # Computed properties
            source_type: mapping_attrs.source_type,
            is_stream_source: mapping_attrs.is_stream_source?,
            is_queue_source: mapping_attrs.is_queue_source?,
            is_kafka_source: mapping_attrs.is_kafka_source?,
            supports_batching_window: mapping_attrs.supports_batching_window?,
            supports_parallelization: mapping_attrs.supports_parallelization?,
            supports_error_handling: mapping_attrs.supports_error_handling?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)