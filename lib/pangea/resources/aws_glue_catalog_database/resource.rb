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
require 'pangea/resources/aws_glue_catalog_database/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Glue Catalog Database with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Glue Catalog Database attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_glue_catalog_database(name, attributes = {})
        # Validate attributes using dry-struct
        database_attrs = Types::GlueCatalogDatabaseAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_glue_catalog_database, name) do
          # Required attributes
          database_name = database_attrs.name
          
          # Catalog ID
          catalog_id database_attrs.catalog_id if database_attrs.catalog_id
          
          # Database input block
          database_input do
            name database_name
            description database_attrs.description if database_attrs.description
            location_uri database_attrs.location_uri if database_attrs.location_uri
            
            # Parameters
            if database_attrs.parameters.any?
              parameters do
                database_attrs.parameters.each do |key, value|
                  public_send(key, value)
                end
              end
            end
          end
          
          # Create table default permissions
          database_attrs.create_table_default_permission.each do |permission|
            create_table_default_permission do
              permissions permission[:permissions]
              
              principal do
                if permission[:principal][:data_lake_principal_identifier]
                  data_lake_principal_identifier permission[:principal][:data_lake_principal_identifier]
                elsif permission[:principal][:data_lake_principal]
                  data_lake_principal permission[:principal][:data_lake_principal]
                end
              end
            end
          end
          
          # Apply tags if present
          if database_attrs.tags.any?
            tags do
              database_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_glue_catalog_database',
          name: name,
          resource_attributes: database_attrs.to_h,
          outputs: {
            id: "${aws_glue_catalog_database.#{name}.id}",
            name: "${aws_glue_catalog_database.#{name}.name}",
            catalog_id: "${aws_glue_catalog_database.#{name}.catalog_id}",
            arn: "${aws_glue_catalog_database.#{name}.arn}"
          },
          computed_properties: {
            is_external: database_attrs.is_external?,
            has_custom_permissions: database_attrs.has_custom_permissions?,
            database_type: database_attrs.database_type,
            s3_path: database_attrs.s3_path,
            estimated_catalog_size_kb: database_attrs.estimated_catalog_size_kb
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)