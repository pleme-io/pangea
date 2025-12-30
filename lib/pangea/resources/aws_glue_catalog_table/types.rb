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
require_relative 'types/storage_descriptor'
require_relative 'types/validators'
require_relative 'types/table_helpers'
require_relative 'types/format_helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Glue Catalog Table resources
        class GlueCatalogTableAttributes < Dry::Struct
          extend GlueCatalogTableFormatHelpers
          extend GlueCatalogTableValidators
          include GlueCatalogTableHelpers

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
          attribute :storage_descriptor, GlueCatalogTableStorageDescriptor::StorageDescriptorSchema.optional

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
            validate_attributes(attrs)
            attrs
          end
        end
      end
    end
  end
end
