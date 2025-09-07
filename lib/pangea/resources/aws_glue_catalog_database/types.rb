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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Glue Catalog Database resources
      class GlueCatalogDatabaseAttributes < Dry::Struct
        # Database name (required)
        attribute :name, Resources::Types::String
        
        # Catalog ID (optional, defaults to AWS account ID)
        attribute :catalog_id, Resources::Types::String.optional
        
        # Database description
        attribute :description, Resources::Types::String.optional
        
        # Location URI for external databases
        attribute :location_uri, Resources::Types::String.optional
        
        # Parameters for the database
        attribute :parameters, Resources::Types::Hash.map(Types::String, Types::String).default({}.freeze)
        
        # Database type
        attribute :database_input, Resources::Types::Hash.schema(
          description?: Types::String.optional,
          location_uri?: Types::String.optional,
          parameters?: Types::Hash.map(Types::String, Types::String).optional
        ).optional
        
        # Permissions and access control
        attribute :create_table_default_permission, Resources::Types::Array.of(
          Types::Hash.schema(
            permissions: Types::Array.of(Types::String.enum(
              "ALL", "SELECT", "INSERT", "DELETE", "UPDATE", "CREATE_TABLE", "DROP_TABLE", "ALTER"
            )),
            principal: Types::Hash.schema(
              data_lake_principal_identifier?: Types::String.optional,
              data_lake_principal?: Types::String.optional
            )
          )
        ).default([].freeze)
        
        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate database name format
          unless attrs.name =~ /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
            raise Dry::Struct::Error, "Database name must start with letter or underscore and contain only alphanumeric characters and underscores"
          end
          
          # Validate database name length
          if attrs.name.length > 128
            raise Dry::Struct::Error, "Database name must be 128 characters or less"
          end
          
          # Validate location URI format if provided
          if attrs.location_uri && !attrs.location_uri.match(/\A(s3|hdfs|file):\/\//)
            raise Dry::Struct::Error, "Location URI must start with s3://, hdfs://, or file://"
          end

          attrs
        end

        # Check if database is external
        def is_external?
          !location_uri.nil?
        end

        # Check if database has custom permissions
        def has_custom_permissions?
          create_table_default_permission.any?
        end

        # Get database type based on location
        def database_type
          return "glue" unless location_uri
          
          case location_uri
          when /\As3:\/\//
            "s3"
          when /\Ahdfs:\/\//
            "hdfs"
          when /\Afile:\/\//
            "file"
          else
            "external"
          end
        end

        # Helper method to generate S3 path
        def s3_path
          return nil unless location_uri && location_uri.start_with?("s3://")
          location_uri.sub("s3://", "").split("/").first
        end

        # Estimate storage requirements for catalog metadata
        def estimated_catalog_size_kb
          base_size = 1 # Base metadata
          base_size += (description&.length || 0) / 1024.0
          base_size += parameters.sum { |k, v| k.length + v.length } / 1024.0
          
          [base_size, 0.1].max.round(2)
        end

        # Generate default parameters for common database types
        def self.default_parameters_for_type(type)
          case type.to_s
          when "data_lake"
            {
              "classification" => "data_lake",
              "compressionType" => "gzip",
              "typeOfData" => "structured"
            }
          when "analytics"
            {
              "classification" => "analytics",
              "optimized_for" => "query_performance"
            }
          when "raw"
            {
              "classification" => "raw_data",
              "retention_policy" => "long_term"
            }
          else
            {}
          end
        end
      end
    end
      end
    end
  end
end