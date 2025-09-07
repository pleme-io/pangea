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
require 'pangea/resources/aws_athena_named_query/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Athena Named Query with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Athena Named Query attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_athena_named_query(name, attributes = {})
        # Validate attributes using dry-struct
        query_attrs = Types::AthenaNamedQueryAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_athena_named_query, name) do
          # Required attributes
          query_name = query_attrs.name
          database query_attrs.database
          query query_attrs.query
          
          # Optional description
          description query_attrs.description if query_attrs.description
          
          # Workgroup
          workgroup query_attrs.workgroup
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_athena_named_query',
          name: name,
          resource_attributes: query_attrs.to_h,
          outputs: {
            id: "${aws_athena_named_query.#{name}.id}"
          },
          computed_properties: {
            is_select_query: query_attrs.is_select_query?,
            is_ddl_query: query_attrs.is_ddl_query?,
            is_insert_query: query_attrs.is_insert_query?,
            is_maintenance_query: query_attrs.is_maintenance_query?,
            query_type: query_attrs.query_type,
            referenced_tables: query_attrs.referenced_tables,
            uses_partitions: query_attrs.uses_partitions?,
            uses_aggregations: query_attrs.uses_aggregations?,
            uses_window_functions: query_attrs.uses_window_functions?,
            query_complexity_score: query_attrs.query_complexity_score,
            parameterized_query: query_attrs.parameterized_query,
            documentation: query_attrs.generate_documentation
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)