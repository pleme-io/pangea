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
        # Instance helper methods for Glue Catalog Table attributes
        module GlueCatalogTableHelpers
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

            detect_format_from_serde(serde[:serialization_library])
          end

          # Get compression type
          def compression_type
            return nil unless storage_descriptor && storage_descriptor[:compressed]

            parameters.fetch("compression", "unknown")
          end

          # Estimate table size based on configuration
          def estimated_size_gb
            return 0.0 if is_view?

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

          private

          def detect_format_from_serde(serialization_library)
            case serialization_library
            when /parquet/i then "parquet"
            when /orc/i then "orc"
            when /avro/i then "avro"
            when /json/i then "json"
            when /csv/i, /text/i then "csv"
            else "custom"
            end
          end
        end
      end
    end
  end
end
