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
require 'pangea/resources/aws_timestream_database/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a Timestream database resource for time series data.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_timestream_database(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::TimestreamDatabaseAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_timestream_database, name) do
          database_name attrs.database_name if attrs.database_name
          kms_key_id attrs.kms_key_id if attrs.kms_key_id
          
          # Apply tags if present
          if attrs.tags.any?
            tags do
              attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_timestream_database',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_timestream_database.#{name}.id}",
            arn: "${aws_timestream_database.#{name}.arn}",
            kms_key_id: "${aws_timestream_database.#{name}.kms_key_id}",
            table_count: "${aws_timestream_database.#{name}.table_count}"
          },
          computed_properties: {
            # Computed properties from type definitions
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)