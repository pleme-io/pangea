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
      # Type-safe attributes for AWS Athena Database resources
      class AthenaDatabaseAttributes < Dry::Struct
        # Database name (required)
        attribute :name, Resources::Types::String
        
        # S3 bucket location for database storage
        attribute :bucket, Resources::Types::String
        
        # Comment/description for the database
        attribute :comment, Resources::Types::String.optional
        
        # Database properties
        attribute :properties, Resources::Types::Hash.map(Types::String, Types::String).default({}.freeze)
        
        # Encryption configuration
        attribute :encryption_configuration, Resources::Types::Hash.schema(
          encryption_option: Types::String.enum("SSE_S3", "SSE_KMS", "CSE_KMS"),
          kms_key?: Types::String.optional
        ).optional
        
        # Expected bucket owner for S3 access
        attribute :expected_bucket_owner, Resources::Types::String.optional
        
        # Force destroy database and tables when resource is destroyed
        attribute :force_destroy, Resources::Types::Bool.default(false)
        
        # ACL configuration for database
        attribute :acl_configuration, Resources::Types::Hash.schema(
          s3_acl_option: Types::String.enum("BUCKET_OWNER_FULL_CONTROL")
        ).optional
        
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
          if attrs.name.length > 255
            raise Dry::Struct::Error, "Database name must be 255 characters or less"
          end
          
          # Validate bucket name format
          unless attrs.bucket =~ /\A[a-z0-9][a-z0-9\-\.]*[a-z0-9]\z/
            raise Dry::Struct::Error, "Bucket name must be valid S3 bucket format"
          end
          
          # Validate KMS key if encryption is KMS
          if attrs.encryption_configuration
            if ["SSE_KMS", "CSE_KMS"].include?(attrs.encryption_configuration[:encryption_option]) && 
               attrs.encryption_configuration[:kms_key].nil?
              raise Dry::Struct::Error, "KMS key must be provided when using KMS encryption"
            end
          end

          attrs
        end

        # Check if database uses encryption
        def encrypted?
          !encryption_configuration.nil?
        end

        # Get encryption type
        def encryption_type
          return nil unless encrypted?
          encryption_configuration[:encryption_option]
        end

        # Check if using KMS encryption
        def uses_kms?
          encrypted? && ["SSE_KMS", "CSE_KMS"].include?(encryption_type)
        end

        # Generate S3 location URI
        def location_uri
          "s3://#{bucket}/#{name}/"
        end

        # Estimate storage requirements based on typical Athena patterns
        def estimated_monthly_storage_gb
          # Base estimate for metadata and common table patterns
          base_storage = 0.1 # 100MB base
          
          # Add estimates based on properties
          if properties["table_type"] == "EXTERNAL_TABLE"
            base_storage += 0.5
          end
          
          if properties["projection.enabled"] == "true"
            base_storage += 0.2
          end
          
          base_storage
        end

        # Generate default properties for common database types
        def self.default_properties_for_type(type)
          case type.to_s
          when "data_lake"
            {
              "classification" => "data_lake",
              "compression" => "snappy",
              "storage_format" => "parquet"
            }
          when "analytics"
            {
              "classification" => "analytics",
              "query_optimization" => "enabled",
              "result_compression" => "gzip"
            }
          when "logs"
            {
              "classification" => "log_analysis",
              "time_partitioning" => "daily",
              "retention_days" => "90"
            }
          when "streaming"
            {
              "classification" => "streaming",
              "partition_projection" => "enabled",
              "time_format" => "yyyy-MM-dd-HH"
            }
          else
            {}
          end
        end

        # Helper to generate partition projection properties
        def self.partition_projection_properties(type, options = {})
          base_props = {
            "projection.enabled" => "true"
          }
          
          case type.to_s
          when "date"
            base_props.merge({
              "projection.date.type" => "date",
              "projection.date.range" => options[:range] || "2020-01-01,NOW",
              "projection.date.format" => options[:format] || "yyyy-MM-dd",
              "projection.date.interval" => options[:interval] || "1",
              "projection.date.interval.unit" => options[:unit] || "DAYS"
            })
          when "integer"
            base_props.merge({
              "projection.id.type" => "integer",
              "projection.id.range" => options[:range] || "1,1000000",
              "projection.id.digits" => options[:digits] || "1"
            })
          when "enum"
            base_props.merge({
              "projection.type.type" => "enum",
              "projection.type.values" => options[:values]&.join(",") || ""
            })
          else
            base_props
          end
        end
      end
    end
      end
    end
  end
end