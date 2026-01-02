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
        # Storage descriptor type definitions for Glue Catalog Table
        module GlueCatalogTableStorageDescriptor
          # Column schema type
          ColumnSchema = Resources::Types::Hash.schema(
            name: Types::String,
            type: Types::String,
            comment?: Types::String.optional,
            parameters?: Types::Hash.map(Types::String, Types::String).optional
          )

          # SerDe info schema type
          SerdeInfoSchema = Resources::Types::Hash.schema(
            name?: Types::String.optional,
            serialization_library?: Types::String.optional,
            parameters?: Types::Hash.map(Types::String, Types::String).optional
          )

          # Sort column schema type
          SortColumnSchema = Resources::Types::Hash.schema(
            column: Types::String,
            sort_order: Types::Integer.constrained(included_in: [0, 1])
          )

          # Full storage descriptor schema
          StorageDescriptorSchema = Resources::Types::Hash.schema(
            columns?: Types::Array.of(ColumnSchema).optional,
            location?: Types::String.optional,
            input_format?: Types::String.optional,
            output_format?: Types::String.optional,
            compressed?: Types::Bool.optional,
            number_of_buckets?: Types::Integer.optional,
            serde_info?: SerdeInfoSchema.optional,
            bucket_columns?: Types::Array.of(Types::String).optional,
            sort_columns?: Types::Array.of(SortColumnSchema).optional,
            stored_as_sub_directories?: Types::Bool.optional
          )
        end
      end
    end
  end
end
