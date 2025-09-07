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
      # Type-safe attributes for AWS Athena Named Query resources
      class AthenaNamedQueryAttributes < Dry::Struct
        # Query name (required)
        attribute :name, Resources::Types::String
        
        # Database name
        attribute :database, Resources::Types::String
        
        # Query string (SQL)
        attribute :query, Resources::Types::String
        
        # Query description
        attribute :description, Resources::Types::String.optional
        
        # Workgroup where query will be saved
        attribute :workgroup, Resources::Types::String.default("primary")

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate query name length
          if attrs.name.length > 128
            raise Dry::Struct::Error, "Query name must be 128 characters or less"
          end
          
          # Validate query is not empty
          if attrs.query.strip.empty?
            raise Dry::Struct::Error, "Query cannot be empty"
          end
          
          # Validate query size (Athena limit)
          if attrs.query.bytesize > 262_144 # 256KB
            raise Dry::Struct::Error, "Query must be less than 256KB"
          end
          
          # Basic SQL validation
          unless attrs.query.match?(/\A\s*(SELECT|WITH|INSERT|CREATE|ALTER|DROP|SHOW|DESCRIBE|MSCK|REFRESH)/i)
            raise Dry::Struct::Error, "Query must start with a valid SQL statement"
          end

          attrs
        end

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
          when /\A\s*(WITH.*)?SELECT/i
            "SELECT"
          when /\A\s*INSERT/i
            "INSERT"
          when /\A\s*CREATE\s+TABLE/i
            "CREATE_TABLE"
          when /\A\s*CREATE\s+VIEW/i
            "CREATE_VIEW"
          when /\A\s*CREATE\s+DATABASE/i
            "CREATE_DATABASE"
          when /\A\s*ALTER/i
            "ALTER"
          when /\A\s*DROP/i
            "DROP"
          when /\A\s*MSCK\s+REPAIR/i
            "MSCK_REPAIR"
          when /\A\s*SHOW/i
            "SHOW"
          when /\A\s*DESCRIBE/i
            "DESCRIBE"
          else
            "OTHER"
          end
        end

        # Extract table references from query
        def referenced_tables
          tables = []
          
          # Extract FROM clause tables
          query.scan(/FROM\s+([`"]?)(\w+)\.(\w+)\1/i) do |_, database, table|
            tables << "#{database}.#{table}"
          end
          
          # Extract JOIN clause tables
          query.scan(/JOIN\s+([`"]?)(\w+)\.(\w+)\1/i) do |_, database, table|
            tables << "#{database}.#{table}"
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
          
          # Increase score based on operations
          score *= 1.5 if uses_aggregations?
          score *= 2.0 if uses_window_functions?
          score *= 1.2 if query.match?(/\bJOIN\b/i)
          score *= 1.1 * query.scan(/\bJOIN\b/i).count
          score *= 1.3 if query.match?(/\bDISTINCT\b/i)
          score *= 1.4 if query.match?(/\bORDER\s+BY\b/i)
          score *= 0.7 if uses_partitions? # Partitions reduce cost
          
          score.round(2)
        end

        # Generate parameterized version of query
        def parameterized_query
          parameterized = query.dup
          
          # Replace date literals with parameters
          parameterized.gsub!(/'\d{4}-\d{2}-\d{2}'/, "'${date_param}'")
          
          # Replace numeric literals in WHERE clauses
          parameterized.gsub!(/WHERE\s+\w+\s*=\s*(\d+)/, 'WHERE \1 = ${id_param}')
          
          # Replace string literals in WHERE clauses
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
          doc << ""
          doc << "Characteristics:"
          doc << "- Uses partitions: #{uses_partitions? ? 'Yes' : 'No'}"
          doc << "- Uses aggregations: #{uses_aggregations? ? 'Yes' : 'No'}"
          doc << "- Uses window functions: #{uses_window_functions? ? 'Yes' : 'No'}"
          doc << "- Complexity score: #{query_complexity_score}"
          doc << ""
          doc << "Referenced tables:"
          referenced_tables.each { |table| doc << "- #{table}" }
          
          doc.join("\n")
        end

        # Common query templates
        def self.template_for_type(type, options = {})
          case type.to_s
          when "daily_aggregation"
            <<~SQL
              SELECT 
                date_column,
                COUNT(*) as record_count,
                SUM(metric_column) as total_metric
              FROM #{options[:table] || "database.table"}
              WHERE date_column = '${date_param}'
              GROUP BY date_column
            SQL
          when "partition_check"
            <<~SQL
              SHOW PARTITIONS #{options[:table] || "database.table"}
            SQL
          when "table_stats"
            <<~SQL
              SELECT 
                COUNT(*) as total_rows,
                COUNT(DISTINCT id_column) as unique_ids,
                MIN(created_at) as earliest_record,
                MAX(created_at) as latest_record
              FROM #{options[:table] || "database.table"}
            SQL
          when "data_quality"
            <<~SQL
              SELECT 
                SUM(CASE WHEN column1 IS NULL THEN 1 ELSE 0 END) as null_column1,
                SUM(CASE WHEN column2 = '' THEN 1 ELSE 0 END) as empty_column2,
                COUNT(*) as total_rows
              FROM #{options[:table] || "database.table"}
              WHERE date_column = '${date_param}'
            SQL
          else
            "SELECT * FROM database.table LIMIT 10"
          end
        end
      end
    end
      end
    end
  end
end