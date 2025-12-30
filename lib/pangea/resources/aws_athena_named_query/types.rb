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

require_relative 'types/query_analysis'
require_relative 'types/query_templates'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Athena Named Query resources
        class AthenaNamedQueryAttributes < Dry::Struct
          include QueryAnalysis
          extend QueryTemplates

          # Query name (required)
          attribute :name, Resources::Types::String

          # Database name
          attribute :database, Resources::Types::String

          # Query string (SQL)
          attribute :query, Resources::Types::String

          # Query description
          attribute :description, Resources::Types::String.optional

          # Workgroup where query will be saved
          attribute :workgroup, Resources::Types::String.default('primary')

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            validate_query_name(attrs.name)
            validate_query_content(attrs.query)

            attrs
          end

          def self.validate_query_name(name)
            return unless name.length > 128

            raise Dry::Struct::Error, 'Query name must be 128 characters or less'
          end

          def self.validate_query_content(query_text)
            if query_text.strip.empty?
              raise Dry::Struct::Error, 'Query cannot be empty'
            end

            if query_text.bytesize > 262_144 # 256KB
              raise Dry::Struct::Error, 'Query must be less than 256KB'
            end

            valid_sql_start = /\A\s*(SELECT|WITH|INSERT|CREATE|ALTER|DROP|SHOW|DESCRIBE|MSCK|REFRESH)/i
            return if query_text.match?(valid_sql_start)

            raise Dry::Struct::Error, 'Query must start with a valid SQL statement'
          end
        end
      end
    end
  end
end
