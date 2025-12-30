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

module Pangea
  module Resources
    module AWS
      module Types
        # Class method helpers for Glue Catalog Table format configurations
        module GlueCatalogTableFormatHelpers
          # Helper method to generate common SerDe configurations
          def serde_info_for_format(format)
            case format.to_s.downcase
            when "parquet"
              {
                serialization_library: "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe",
                parameters: { "serialization.format" => "1" }
              }
            when "orc"
              {
                serialization_library: "org.apache.hadoop.hive.ql.io.orc.OrcSerde",
                parameters: { "serialization.format" => "1" }
              }
            when "avro"
              { serialization_library: "org.apache.hadoop.hive.serde2.avro.AvroSerDe" }
            when "json"
              { serialization_library: "org.apache.hive.hcatalog.data.JsonSerDe" }
            when "csv"
              {
                serialization_library: "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
                parameters: { "field.delim" => ",", "serialization.format" => "," }
              }
            else
              {}
            end
          end

          # Helper to generate common input/output formats
          def input_output_format_for_type(format)
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
            when "json", "csv"
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
