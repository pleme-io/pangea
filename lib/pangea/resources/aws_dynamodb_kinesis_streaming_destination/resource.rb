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
require 'pangea/resources/aws_dynamodb_kinesis_streaming_destination/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS DynamoDB Kinesis Streaming Destination with type-safe attributes
      #
      # DynamoDB Kinesis Data Streams for DynamoDB captures data modification events
      # in a DynamoDB table and replicates them to a Kinesis data stream. This enables
      # you to consume the stream and perform real-time analytics, feed data to other
      # AWS services, or replicate data across Regions.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] DynamoDB Kinesis streaming destination attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_dynamodb_kinesis_streaming_destination(name, attributes = {})
        # Validate attributes using dry-struct
        streaming_attrs = DynamoDBKinesisStreamingDestination::Types::DynamoDBKinesisStreamingDestinationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_dynamodb_kinesis_streaming_destination, name) do
          # Required attributes
          stream_arn streaming_attrs.stream_arn
          table_name streaming_attrs.table_name
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_dynamodb_kinesis_streaming_destination',
          name: name,
          resource_attributes: streaming_attrs.to_h,
          outputs: {
            id: "${aws_dynamodb_kinesis_streaming_destination.#{name}.id}",
            stream_arn: "${aws_dynamodb_kinesis_streaming_destination.#{name}.stream_arn}",
            table_name: "${aws_dynamodb_kinesis_streaming_destination.#{name}.table_name}"
          },
          computed: {
            stream_name: streaming_attrs.stream_name,
            stream_region: streaming_attrs.stream_region,
            stream_account_id: streaming_attrs.stream_account_id,
            cross_region_streaming: streaming_attrs.cross_region_streaming?,
            cross_account_streaming: streaming_attrs.cross_account_streaming?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)