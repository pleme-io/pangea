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
        class AthenaNamedQueryAttributes
          # Query template methods for Athena named queries
          module QueryTemplates
            # Common query templates
            def template_for_type(type, options = {})
              table = options[:table] || 'database.table'

              case type.to_s
              when 'daily_aggregation'
                daily_aggregation_template(table)
              when 'partition_check'
                partition_check_template(table)
              when 'table_stats'
                table_stats_template(table)
              when 'data_quality'
                data_quality_template(table)
              else
                "SELECT * FROM database.table LIMIT 10"
              end
            end

            private

            def daily_aggregation_template(table)
              <<~SQL
                SELECT
                  date_column,
                  COUNT(*) as record_count,
                  SUM(metric_column) as total_metric
                FROM #{table}
                WHERE date_column = '${date_param}'
                GROUP BY date_column
              SQL
            end

            def partition_check_template(table)
              <<~SQL
                SHOW PARTITIONS #{table}
              SQL
            end

            def table_stats_template(table)
              <<~SQL
                SELECT
                  COUNT(*) as total_rows,
                  COUNT(DISTINCT id_column) as unique_ids,
                  MIN(created_at) as earliest_record,
                  MAX(created_at) as latest_record
                FROM #{table}
              SQL
            end

            def data_quality_template(table)
              <<~SQL
                SELECT
                  SUM(CASE WHEN column1 IS NULL THEN 1 ELSE 0 END) as null_column1,
                  SUM(CASE WHEN column2 = '' THEN 1 ELSE 0 END) as empty_column2,
                  COUNT(*) as total_rows
                FROM #{table}
                WHERE date_column = '${date_param}'
              SQL
            end
          end
        end
      end
    end
  end
end
