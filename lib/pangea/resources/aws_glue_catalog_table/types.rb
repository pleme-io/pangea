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
      # Type-safe attributes for AWS Glue Catalog Table resources
      class GlueCatalogTableAttributes < Dry::Struct
        # Table name (required)
        attribute :name, Resources::Types::String
        
        # Database name (required)
        attribute :database_name, Resources::Types::String
        
        # Catalog ID (optional, defaults to AWS account ID)
        attribute :catalog_id, Resources::Types::String.optional
        
        # Table owner
        attribute :owner, Resources::Types::String.optional
        
        # Table description
        attribute :description, Resources::Types::String.optional
        
        # Table type
        attribute :table_type, Resources::Types::String.enum(
          "EXTERNAL_TABLE", "MANAGED_TABLE", "VIRTUAL_VIEW"
        ).optional
        
        # Parameters for the table
        attribute :parameters, Resources::Types::Hash.map(Types::String, Types::String).default({}.freeze)
        
        # Storage descriptor
        attribute :storage_descriptor, Resources::Types::Hash.schema(
          columns?: Types::Array.of(
            Types::Hash.schema(
              name: Types::String,
              type: Types::String,
              comment?: Types::String.optional,
              parameters?: Types::Hash.map(Types::String, Types::String).optional
            )
          ).optional,
          location?: Types::String.optional,
          input_format?: Types::String.optional,
          output_format?: Types::String.optional,
          compressed?: Types::Bool.optional,
          number_of_buckets?: Types::Integer.optional,
          serde_info?: Types::Hash.schema(
            name?: Types::String.optional,
            serialization_library?: Types::String.optional,
            parameters?: Types::Hash.map(Types::String, Types::String).optional
          ).optional,
          bucket_columns?: Types::Array.of(Types::String).optional,
          sort_columns?: Types::Array.of(
            Types::Hash.schema(
              column: Types::String,
              sort_order: Types::Integer.constrained(included_in: [0, 1])
            )
          ).optional,
          stored_as_sub_directories?: Types::Bool.optional
        ).optional
        
        # Partition keys
        attribute :partition_keys, Resources::Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            type: Types::String,
            comment?: Types::String.optional
          )
        ).default([].freeze)
        
        # Retention period in days
        attribute :retention, Resources::Types::Integer.optional
        
        # View information for VIRTUAL_VIEW tables
        attribute :view_original_text, Resources::Types::String.optional
        attribute :view_expanded_text, Resources::Types::String.optional
        
        # Targeted column information
        attribute :target_table, Resources::Types::Hash.schema(
          catalog_id?: Types::String.optional,
          database_name?: Types::String.optional,
          name?: Types::String.optional
        ).default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate table name format
          unless attrs.name =~ /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
            raise Dry::Struct::Error, "Table name must start with letter or underscore and contain only alphanumeric characters and underscores"
          end
          
          # Validate table name length
          if attrs.name.length > 255
            raise Dry::Struct::Error, "Table name must be 255 characters or less"
          end
          
          # Validate database name format
          unless attrs.database_name =~ /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
            raise Dry::Struct::Error, "Database name must start with letter or underscore and contain only alphanumeric characters and underscores"
          end
          
          # Validate view-specific attributes
          if attrs.table_type == "VIRTUAL_VIEW"
            unless attrs.view_original_text || attrs.view_expanded_text
              raise Dry::Struct::Error, "VIRTUAL_VIEW tables must have view_original_text or view_expanded_text"
            end
          end
          
          # Validate storage descriptor location for external tables
          if attrs.table_type == "EXTERNAL_TABLE" && attrs.storage_descriptor
            location = attrs.storage_descriptor[:location]
            if location && !location.match(/\A(s3|hdfs|file):\/\//)
              raise Dry::Struct::Error, "External table location must start with s3://, hdfs://, or file://"
            end
          end

          attrs
        end

        # Check if table is partitioned
        def is_partitioned?
          partition_keys.any?
        end

        # Check if table is external
        def is_external?
          table_type == "EXTERNAL_TABLE"
        end

        # Check if table is a view
        def is_view?
          table_type == "VIRTUAL_VIEW"
        end

        # Get table format based on storage descriptor
        def table_format
          return "view" if is_view?
          return "managed" unless storage_descriptor
          
          serde = storage_descriptor[:serde_info]
          return "unknown" unless serde
          
          case serde[:serialization_library]
          when /parquet/i
            "parquet"
          when /orc/i
            "orc"
          when /avro/i
            "avro"
          when /json/i
            "json"
          when /csv/i, /text/i
            "csv"
          else
            "custom"
          end
        end

        # Get compression type
        def compression_type
          return nil unless storage_descriptor && storage_descriptor[:compressed]
          
          parameters.fetch("compression", "unknown")
        end

        # Estimate table size based on configuration
        def estimated_size_gb
          return 0.0 if is_view?
          
          # Basic estimation based on column count and types
          base_size = storage_descriptor&.dig(:columns)&.size || 1
          partition_multiplier = is_partitioned? ? partition_keys.size * 10 : 1
          
          (base_size * partition_multiplier * 0.1).round(2)
        end

        # Generate column schema summary
        def column_summary
          return {} unless storage_descriptor&.dig(:columns)
          
          columns = storage_descriptor[:columns]
          {
            total_columns: columns.size,
            string_columns: columns.count { |c| c[:type].downcase.include?('string') },
            numeric_columns: columns.count { |c| c[:type].downcase.match?(/(int|double|float|decimal|bigint)/) },
            date_columns: columns.count { |c| c[:type].downcase.match?(/(date|timestamp)/) },
            complex_columns: columns.count { |c| c[:type].downcase.match?(/(array|map|struct)/) }
          }
        end

        # Helper method to generate common SerDe configurations
        def self.serde_info_for_format(format)
          case format.to_s.downcase
          when "parquet"
            {
              serialization_library: "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe",
              parameters: {
                "serialization.format" => "1"
              }
            }
          when "orc"
            {
              serialization_library: "org.apache.hadoop.hive.ql.io.orc.OrcSerde",
              parameters: {
                "serialization.format" => "1"
              }
            }
          when "avro"
            {
              serialization_library: "org.apache.hadoop.hive.serde2.avro.AvroSerDe"
            }
          when "json"
            {
              serialization_library: "org.apache.hive.hcatalog.data.JsonSerDe"
            }
          when "csv"
            {
              serialization_library: "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
              parameters: {
                "field.delim" => ",",
                "serialization.format" => ","
              }
            }
          else
            {}
          end
        end
        
        # Helper to generate common input/output formats
        def self.input_output_format_for_type(format)
          case format.to_s.downcase
          when "parquet"
            {
              input_format: "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
              output_format: "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
            }
          when "orc"
            {
              input_format: "org.apache.hadoop.hive.ql.io.orc.OrcInputFormat", 
              output_format: "org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat"
            }
          when "avro"
            {
              input_format: "org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat",
              output_format: "org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat"
            }
          when "json"
            {
              input_format: "org.apache.hadoop.mapred.TextInputFormat",
              output_format: "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
            }
          when "csv"
            {
              input_format: "org.apache.hadoop.mapred.TextInputFormat",
              output_format: "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
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