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
      module DynamoDBTable
        # Builds DynamoDB table index configuration blocks
        module IndexBuilder
          module_function

          def build_indexes(context, attrs)
            build_global_secondary_indexes(context, attrs)
            build_local_secondary_indexes(context, attrs)
          end

          def build_global_secondary_indexes(context, attrs)
            attrs.global_secondary_index.each do |gsi|
              context.global_secondary_index do
                name gsi[:name]
                hash_key gsi[:hash_key]
                range_key gsi[:range_key] if gsi[:range_key]

                if attrs.is_provisioned?
                  read_capacity gsi[:read_capacity]
                  write_capacity gsi[:write_capacity]
                end

                projection_type gsi[:projection_type]
                non_key_attributes gsi[:non_key_attributes] if gsi[:non_key_attributes]
              end
            end
          end

          def build_local_secondary_indexes(context, attrs)
            attrs.local_secondary_index.each do |lsi|
              context.local_secondary_index do
                name lsi[:name]
                range_key lsi[:range_key]
                projection_type lsi[:projection_type]
                non_key_attributes lsi[:non_key_attributes] if lsi[:non_key_attributes]
              end
            end
          end
        end
      end
    end
  end
end
