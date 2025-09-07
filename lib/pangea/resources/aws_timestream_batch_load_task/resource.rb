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
require 'pangea/resources/aws_timestream_batch_load_task/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a Timestream batch load task resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_timestream_batch_load_task(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::TimestreamBatchLoadTaskAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_timestream_batch_load_task, name) do
          database_name attrs.database_name if attrs.database_name
          table_name attrs.table_name if attrs.table_name
          data_source_configuration attrs.data_source_configuration if attrs.data_source_configuration
          data_model_configuration attrs.data_model_configuration if attrs.data_model_configuration
          report_configuration attrs.report_configuration if attrs.report_configuration
          target_database_name attrs.target_database_name if attrs.target_database_name
          target_table_name attrs.target_table_name if attrs.target_table_name
          
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
          type: 'aws_timestream_batch_load_task',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_timestream_batch_load_task.#{name}.id}",
            creation_time: "${aws_timestream_batch_load_task.#{name}.creation_time}",
            last_updated_time: "${aws_timestream_batch_load_task.#{name}.last_updated_time}",
            resumable_until: "${aws_timestream_batch_load_task.#{name}.resumable_until}",
            task_status: "${aws_timestream_batch_load_task.#{name}.task_status}"
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