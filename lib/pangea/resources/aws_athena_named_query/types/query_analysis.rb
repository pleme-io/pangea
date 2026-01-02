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
          # Query analysis methods for Athena named queries
          module QueryAnalysis
            # Check if query is a SELECT statement
            def is_select_query?
              query.match?(/\A\s*(WITH.*)?SELECT/i)
            end

            # Check if query is a DDL statement
            def is_ddl_query?
              query.match?(/\A\s*(CREATE|ALTER|DROP)/i)
            end

            # Check if query is an INSERT statement
            def is_insert_query?
              query.match?(/\A\s*INSERT/i)
            end

            # Check if query is a maintenance statement
            def is_maintenance_query?
              query.match?(/\A\s*(MSCK|REFRESH|SHOW|DESCRIBE)/i)
            end

            # Get query type
            def query_type
              case query
              when /\A\s*(WITH.*)?SELECT/i then 'SELECT'
              when /\A\s*INSERT/i then 'INSERT'
              when /\A\s*CREATE\s+TABLE/i then 'CREATE_TABLE'
              when /\A\s*CREATE\s+VIEW/i then 'CREATE_VIEW'
              when /\A\s*CREATE\s+DATABASE/i then 'CREATE_DATABASE'
              when /\A\s*ALTER/i then 'ALTER'
              when /\A\s*DROP/i then 'DROP'
              when /\A\s*MSCK\s+REPAIR/i then 'MSCK_REPAIR'
              when /\A\s*SHOW/i then 'SHOW'
              when /\A\s*DESCRIBE/i then 'DESCRIBE'
              else 'OTHER'
              end
            end

            # Extract table references from query
            def referenced_tables
              tables = []

              # Extract FROM clause tables
              query.scan(/FROM\s+([`"]?)(\w+)\.(\w+)\1/i) do |_, db, table|
                tables << "#{db}.#{table}"
              end

              # Extract JOIN clause tables
              query.scan(/JOIN\s+([`"]?)(\w+)\.(\w+)\1/i) do |_, db, table|
                tables << "#{db}.#{table}"
              end

              # Extract simple table references (same database)
              query.scan(/(?:FROM|JOIN)\s+([`"]?)(\w+)\1(?:\s|,|$)/i) do |_, table|
                tables << "#{database}.#{table}" unless table.match?(/\A(SELECT|WITH)/i)
              end

              tables.uniq
            end

            # Check if query uses partitions
            def uses_partitions?
              query.match?(/WHERE.*(?:year|month|day|date|dt|partition)\s*=|PARTITION\s*\(/i)
            end

            # Check if query uses aggregations
            def uses_aggregations?
              query.match?(/\b(?:COUNT|SUM|AVG|MIN|MAX|GROUP\s+BY|HAVING)\b/i)
            end

            # Check if query uses window functions
            def uses_window_functions?
              query.match?(/\b(?:ROW_NUMBER|RANK|DENSE_RANK|LAG|LEAD|OVER)\s*\(/i)
            end

            # Estimate query complexity for cost estimation
            def query_complexity_score
              score = 1.0

              score *= 1.5 if uses_aggregations?
              score *= 2.0 if uses_window_functions?
              score *= 1.2 if query.match?(/\bJOIN\b/i)
              score *= 1.1 * query.scan(/\bJOIN\b/i).count
              score *= 1.3 if query.match?(/\bDISTINCT\b/i)
              score *= 1.4 if query.match?(/\bORDER\s+BY\b/i)
              score *= 0.7 if uses_partitions?

              score.round(2)
            end

            # Generate parameterized version of query
            def parameterized_query
              parameterized = query.dup

              parameterized.gsub!(/'\d{4}-\d{2}-\d{2}'/, "'${date_param}'")
              parameterized.gsub!(/WHERE\s+\w+\s*=\s*(\d+)/, 'WHERE \1 = ${id_param}')
              parameterized.gsub!(/WHERE\s+\w+\s*=\s*'([^']+)'/, "WHERE \\1 = '${string_param}'")

              parameterized
            end

            # Generate query documentation
            def generate_documentation
              doc = []
              doc << "Query: #{name}"
              doc << "Type: #{query_type}"
              doc << "Database: #{database}"
              doc << "Description: #{description}" if description
              doc << ''
              doc << 'Characteristics:'
              doc << "- Uses partitions: #{uses_partitions? ? 'Yes' : 'No'}"
              doc << "- Uses aggregations: #{uses_aggregations? ? 'Yes' : 'No'}"
              doc << "- Uses window functions: #{uses_window_functions? ? 'Yes' : 'No'}"
              doc << "- Complexity score: #{query_complexity_score}"
              doc << ''
              doc << 'Referenced tables:'
              referenced_tables.each { |table| doc << "- #{table}" }

              doc.join("\n")
            end
          end
        end
      end
    end
  end
end
