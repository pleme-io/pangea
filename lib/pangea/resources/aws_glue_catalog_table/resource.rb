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
require 'pangea/resources/aws_glue_catalog_table/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Glue Catalog Table with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Glue Catalog Table attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_glue_catalog_table(name, attributes = {})
        # Validate attributes using dry-struct
        table_attrs = Types::GlueCatalogTableAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_glue_catalog_table, name) do
          # Required attributes
          database_name table_attrs.database_name
          table_name = table_attrs.name
          
          # Catalog ID
          catalog_id table_attrs.catalog_id if table_attrs.catalog_id
          
          # Table input block
          table_input do
            name table_name
            owner table_attrs.owner if table_attrs.owner
            description table_attrs.description if table_attrs.description
            table_type table_attrs.table_type if table_attrs.table_type
            
            # Parameters
            if table_attrs.parameters.any?
              parameters do
                table_attrs.parameters.each do |key, value|
                  public_send(key, value)
                end
              end
            end
            
            # Storage descriptor
            if table_attrs.storage_descriptor
              storage_descriptor do
                sd = table_attrs.storage_descriptor
                
                location sd[:location] if sd[:location]
                input_format sd[:input_format] if sd[:input_format]
                output_format sd[:output_format] if sd[:output_format]
                compressed sd[:compressed] unless sd[:compressed].nil?
                number_of_buckets sd[:number_of_buckets] if sd[:number_of_buckets]
                stored_as_sub_directories sd[:stored_as_sub_directories] unless sd[:stored_as_sub_directories].nil?
                
                # Columns
                if sd[:columns]
                  sd[:columns].each do |column|
                    columns do
                      name column[:name]
                      type column[:type]
                      comment column[:comment] if column[:comment]
                      
                      if column[:parameters]&.any?
                        parameters do
                          column[:parameters].each do |k, v|
                            public_send(k, v)
                          end
                        end
                      end
                    end
                  end
                end
                
                # SerDe info
                if sd[:serde_info]
                  ser_de_info do
                    serde = sd[:serde_info]
                    name serde[:name] if serde[:name]
                    serialization_library serde[:serialization_library] if serde[:serialization_library]
                    
                    if serde[:parameters]&.any?
                      parameters do
                        serde[:parameters].each do |k, v|
                          public_send(k, v)
                        end
                      end
                    end
                  end
                end
                
                # Bucket columns
                if sd[:bucket_columns]&.any?
                  bucket_columns sd[:bucket_columns]
                end
                
                # Sort columns
                if sd[:sort_columns]&.any?
                  sd[:sort_columns].each do |sort_col|
                    sort_columns do
                      column sort_col[:column]
                      sort_order sort_col[:sort_order]
                    end
                  end
                end
              end
            end
            
            # Partition keys
            table_attrs.partition_keys.each do |partition_key|
              partition_keys do
                name partition_key[:name]
                type partition_key[:type]
                comment partition_key[:comment] if partition_key[:comment]
              end
            end
            
            # Retention
            retention table_attrs.retention if table_attrs.retention
            
            # View information
            view_original_text table_attrs.view_original_text if table_attrs.view_original_text
            view_expanded_text table_attrs.view_expanded_text if table_attrs.view_expanded_text
            
            # Target table
            if table_attrs.target_table.any?
              target_table do
                tt = table_attrs.target_table
                catalog_id tt[:catalog_id] if tt[:catalog_id]
                database_name tt[:database_name] if tt[:database_name]
                name tt[:name] if tt[:name]
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_glue_catalog_table',
          name: name,
          resource_attributes: table_attrs.to_h,
          outputs: {
            id: "${aws_glue_catalog_table.#{name}.id}",
            name: "${aws_glue_catalog_table.#{name}.name}",
            database_name: "${aws_glue_catalog_table.#{name}.database_name}",
            catalog_id: "${aws_glue_catalog_table.#{name}.catalog_id}",
            arn: "${aws_glue_catalog_table.#{name}.arn}"
          },
          computed_properties: {
            is_partitioned: table_attrs.is_partitioned?,
            is_external: table_attrs.is_external?,
            is_view: table_attrs.is_view?,
            table_format: table_attrs.table_format,
            compression_type: table_attrs.compression_type,
            estimated_size_gb: table_attrs.estimated_size_gb,
            column_summary: table_attrs.column_summary
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)