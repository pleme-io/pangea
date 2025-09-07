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
require 'pangea/resources/aws_timestream_scheduled_query/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a Timestream scheduled query resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_timestream_scheduled_query(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::TimestreamScheduledQueryAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_timestream_scheduled_query, name) do
          name attrs.name if attrs.name
          query_string attrs.query_string if attrs.query_string
          schedule_configuration attrs.schedule_configuration if attrs.schedule_configuration
          notification_configuration attrs.notification_configuration if attrs.notification_configuration
          target_configuration attrs.target_configuration if attrs.target_configuration
          client_token attrs.client_token if attrs.client_token
          scheduled_query_execution_role_arn attrs.scheduled_query_execution_role_arn if attrs.scheduled_query_execution_role_arn
          error_report_configuration attrs.error_report_configuration if attrs.error_report_configuration
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
          type: 'aws_timestream_scheduled_query',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_timestream_scheduled_query.#{name}.id}",
            arn: "${aws_timestream_scheduled_query.#{name}.arn}",
            state: "${aws_timestream_scheduled_query.#{name}.state}"
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