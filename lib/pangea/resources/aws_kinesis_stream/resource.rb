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
require 'pangea/resources/aws_kinesis_stream/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Kinesis Stream for real-time data streaming
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Kinesis Stream attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_kinesis_stream(name, attributes = {})
        # Validate attributes using dry-struct
        stream_attrs = Types::Types::KinesisStreamAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_kinesis_stream, name) do
          name stream_attrs.name
          shard_count stream_attrs.shard_count unless stream_attrs.is_on_demand_mode?
          retention_period stream_attrs.retention_period
          
          # Shard level metrics
          if stream_attrs.has_enhanced_metrics?
            shard_level_metrics stream_attrs.shard_level_metrics
          end
          
          # Encryption configuration
          if stream_attrs.is_encrypted?
            encryption_type stream_attrs.encryption_type
            kms_key_id stream_attrs.kms_key_id
          end
          
          # Stream mode configuration
          if stream_attrs.stream_mode_details
            stream_mode_details do
              stream_mode stream_attrs.stream_mode_details[:stream_mode]
            end
          end
          
          # Apply tags if present
          if stream_attrs.tags.any?
            tags do
              stream_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_kinesis_stream',
          name: name,
          resource_attributes: stream_attrs.to_h,
          outputs: {
            id: "${aws_kinesis_stream.#{name}.id}",
            name: "${aws_kinesis_stream.#{name}.name}",
            arn: "${aws_kinesis_stream.#{name}.arn}",
            shard_count: "${aws_kinesis_stream.#{name}.shard_count}",
            retention_period: "${aws_kinesis_stream.#{name}.retention_period}",
            encryption_type: "${aws_kinesis_stream.#{name}.encryption_type}",
            kms_key_id: "${aws_kinesis_stream.#{name}.kms_key_id}",
            stream_mode_details: "${aws_kinesis_stream.#{name}.stream_mode_details}",
            shard_level_metrics: "${aws_kinesis_stream.#{name}.shard_level_metrics}",
            tags_all: "${aws_kinesis_stream.#{name}.tags_all}"
          }
        )
        
        # Add computed properties as singleton methods
        ref.define_singleton_method(:is_encrypted?) { stream_attrs.is_encrypted? }
        ref.define_singleton_method(:is_on_demand_mode?) { stream_attrs.is_on_demand_mode? }
        ref.define_singleton_method(:is_provisioned_mode?) { stream_attrs.is_provisioned_mode? }
        ref.define_singleton_method(:has_enhanced_metrics?) { stream_attrs.has_enhanced_metrics? }
        ref.define_singleton_method(:max_throughput_per_shard_mbps) { stream_attrs.max_throughput_per_shard_mbps }
        ref.define_singleton_method(:max_throughput_per_shard_records) { stream_attrs.max_throughput_per_shard_records }
        ref.define_singleton_method(:total_max_throughput_mbps) { stream_attrs.total_max_throughput_mbps }
        ref.define_singleton_method(:total_max_throughput_records) { stream_attrs.total_max_throughput_records }
        ref.define_singleton_method(:retention_period_days) { stream_attrs.retention_period_days }
        ref.define_singleton_method(:estimated_monthly_cost_usd) { stream_attrs.estimated_monthly_cost_usd }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)