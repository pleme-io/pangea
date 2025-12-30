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

require_relative 'index_builder'
require_relative 'config_builder'

module Pangea
  module Resources
    module AWS
      module DynamoDBTable
        # Builds DynamoDB table configuration blocks
        module TableBuilder
          module_function

          def build_table(context, attrs)
            build_basic_settings(context, attrs)
            IndexBuilder.build_indexes(context, attrs)
            ConfigBuilder.build_optional_features(context, attrs)
            ConfigBuilder.build_restore_config(context, attrs)
            ConfigBuilder.build_import_config(context, attrs)
            ConfigBuilder.build_replicas(context, attrs)
            ConfigBuilder.build_tags(context, attrs)
          end

          def build_basic_settings(context, attrs)
            context.instance_eval do
              table_name attrs.name
              billing_mode attrs.billing_mode
              hash_key attrs.hash_key
              range_key attrs.range_key if attrs.range_key

              attrs.attribute.each do |attr_def|
                attribute do
                  name attr_def[:name]
                  type attr_def[:type]
                end
              end

              if attrs.is_provisioned?
                read_capacity attrs.read_capacity
                write_capacity attrs.write_capacity
              end
            end
          end
        end
      end
    end
  end
end
