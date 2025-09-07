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
require 'pangea/resources/aws_qldb_stream/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS QLDB Stream with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] QLDB stream attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_qldb_stream(name, attributes = {})
        # Validate attributes using dry-struct
        stream_attrs = Types::QldbStreamAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_qldb_stream, name) do
          # Set stream name
          stream_name stream_attrs.stream_name
          
          # Set ledger name
          ledger_name stream_attrs.ledger_name
          
          # Set role ARN
          role_arn stream_attrs.role_arn
          
          # Set inclusive start time
          inclusive_start_time stream_attrs.inclusive_start_time
          
          # Set exclusive end time if provided
          exclusive_end_time stream_attrs.exclusive_end_time if stream_attrs.exclusive_end_time
          
          # Set Kinesis configuration
          kinesis_configuration do
            stream_arn stream_attrs.kinesis_configuration[:stream_arn]
            aggregation_enabled stream_attrs.kinesis_configuration[:aggregation_enabled]
          end
          
          # Set tags if provided
          if stream_attrs.tags && !stream_attrs.tags.empty?
            tags stream_attrs.tags
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_qldb_stream',
          name: name,
          resource_attributes: stream_attrs.to_h,
          outputs: {
            id: "${aws_qldb_stream.#{name}.id}",
            arn: "${aws_qldb_stream.#{name}.arn}",
            stream_name: "${aws_qldb_stream.#{name}.stream_name}",
            ledger_name: "${aws_qldb_stream.#{name}.ledger_name}",
            status: "${aws_qldb_stream.#{name}.status}",
            creation_time: "${aws_qldb_stream.#{name}.creation_time}",
            inclusive_start_time: "${aws_qldb_stream.#{name}.inclusive_start_time}",
            exclusive_end_time: "${aws_qldb_stream.#{name}.exclusive_end_time}",
            kinesis_configuration: "${aws_qldb_stream.#{name}.kinesis_configuration}"
          },
          computed: {
            kinesis_stream_arn: stream_attrs.kinesis_stream_arn,
            aggregation_enabled: stream_attrs.aggregation_enabled?,
            is_continuous_stream: stream_attrs.is_continuous_stream?,
            is_bounded_stream: stream_attrs.is_bounded_stream?,
            stream_duration: stream_attrs.stream_duration,
            stream_type: stream_attrs.stream_type,
            estimated_monthly_cost: stream_attrs.estimated_monthly_cost,
            stream_features: stream_attrs.stream_features,
            use_cases: stream_attrs.use_cases,
            kinesis_region: stream_attrs.kinesis_region,
            role_account_id: stream_attrs.role_account_id,
            required_iam_permissions: stream_attrs.required_iam_permissions,
            stream_record_format: stream_attrs.stream_record_format
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)