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
        # Validation methods for Glue Catalog Table attributes
        module GlueCatalogTableValidators
          NAME_PATTERN = /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
          MAX_NAME_LENGTH = 255
          VALID_LOCATION_PREFIXES = /\A(s3|hdfs|file):\/\//

          def validate_attributes(attrs)
            validate_name(attrs.name)
            validate_database_name(attrs.database_name)
            validate_view_attributes(attrs)
            validate_external_table_location(attrs)
          end

          private

          def validate_name(name)
            unless name =~ NAME_PATTERN
              raise Dry::Struct::Error,
                    "Table name must start with letter or underscore and contain only alphanumeric characters and underscores"
            end

            if name.length > MAX_NAME_LENGTH
              raise Dry::Struct::Error, "Table name must be #{MAX_NAME_LENGTH} characters or less"
            end
          end

          def validate_database_name(database_name)
            return if database_name =~ NAME_PATTERN

            raise Dry::Struct::Error,
                  "Database name must start with letter or underscore and contain only alphanumeric characters and underscores"
          end

          def validate_view_attributes(attrs)
            return unless attrs.table_type == "VIRTUAL_VIEW"
            return if attrs.view_original_text || attrs.view_expanded_text

            raise Dry::Struct::Error, "VIRTUAL_VIEW tables must have view_original_text or view_expanded_text"
          end

          def validate_external_table_location(attrs)
            return unless attrs.table_type == "EXTERNAL_TABLE" && attrs.storage_descriptor

            location = attrs.storage_descriptor[:location]
            return unless location && !location.match(VALID_LOCATION_PREFIXES)

            raise Dry::Struct::Error, "External table location must start with s3://, hdfs://, or file://"
          end
        end
      end
    end
  end
end
