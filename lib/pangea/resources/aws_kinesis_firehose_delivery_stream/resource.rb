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
require 'pangea/resources/aws_kinesis_firehose_delivery_stream/types'
require 'pangea/resources/aws_kinesis_firehose_delivery_stream/destination_builders'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      include FirehoseDestinationBuilders

      # Create an AWS Kinesis Firehose Delivery Stream for reliable data delivery to destinations
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Kinesis Firehose Delivery Stream attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_kinesis_firehose_delivery_stream(name, attributes = {})
        firehose_attrs = Types::KinesisFirehoseDeliveryStreamAttributes.new(attributes)
        builder_context = self

        resource(:aws_kinesis_firehose_delivery_stream, name) do
          name firehose_attrs.name
          destination firehose_attrs.destination

          # Kinesis source configuration
          if firehose_attrs.has_kinesis_source?
            kinesis_source_configuration do
              kinesis_stream_arn firehose_attrs.kinesis_source_configuration[:kinesis_stream_arn]
              role_arn firehose_attrs.kinesis_source_configuration[:role_arn]
            end
          end

          # Destination configurations
          builder_context.send(:build_s3_configuration, self, firehose_attrs.s3_configuration) if firehose_attrs.s3_configuration
          builder_context.send(:build_extended_s3_configuration, self, firehose_attrs.extended_s3_configuration) if firehose_attrs.extended_s3_configuration
          builder_context.send(:build_redshift_configuration, self, firehose_attrs.redshift_configuration) if firehose_attrs.redshift_configuration
          builder_context.send(:build_elasticsearch_configuration, self, firehose_attrs.elasticsearch_configuration) if firehose_attrs.elasticsearch_configuration
          builder_context.send(:build_opensearch_configuration, self, firehose_attrs.amazonopensearch_configuration) if firehose_attrs.amazonopensearch_configuration
          builder_context.send(:build_splunk_configuration, self, firehose_attrs.splunk_configuration) if firehose_attrs.splunk_configuration
          builder_context.send(:build_http_endpoint_configuration, self, firehose_attrs.http_endpoint_configuration) if firehose_attrs.http_endpoint_configuration

          # Server-side encryption
          if firehose_attrs.is_encrypted?
            server_side_encryption do
              sse_config = firehose_attrs.server_side_encryption
              enabled sse_config[:enabled]
              key_type sse_config[:key_type] if sse_config[:key_type]
              key_arn sse_config[:key_arn] if sse_config[:key_arn]
            end
          end

          # Apply tags if present
          if firehose_attrs.tags.any?
            tags do
              firehose_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_kinesis_firehose_delivery_stream',
          name: name,
          resource_attributes: firehose_attrs.to_h,
          outputs: {
            id: "${aws_kinesis_firehose_delivery_stream.#{name}.id}",
            name: "${aws_kinesis_firehose_delivery_stream.#{name}.name}",
            arn: "${aws_kinesis_firehose_delivery_stream.#{name}.arn}",
            version_id: "${aws_kinesis_firehose_delivery_stream.#{name}.version_id}",
            destination_id: "${aws_kinesis_firehose_delivery_stream.#{name}.destination_id}",
            tags_all: "${aws_kinesis_firehose_delivery_stream.#{name}.tags_all}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
