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
  module Components
    module MultiRegionActiveActive
      # DynamoDB global table resources
      module DynamoDB
        def create_dynamodb_global_table(name, attrs, tags)
          table_ref = aws_dynamodb_table(
            component_resource_name(name, :global_table),
            build_dynamodb_table_config(name, attrs, tags)
          )

          table_ref
        end

        private

        def build_dynamodb_table_config(name, attrs, tags)
          config = {
            name: "#{name}-global-table",
            billing_mode: 'PAY_PER_REQUEST',
            hash_key: 'id',
            range_key: 'sort_key',
            attribute: [
              { name: 'id', type: 'S' },
              { name: 'sort_key', type: 'S' }
            ],
            stream_enabled: true,
            stream_view_type: 'NEW_AND_OLD_IMAGES',
            replica: build_dynamodb_replicas(attrs),
            tags: tags
          }

          config[:server_side_encryption] = build_encryption_config(attrs) if attrs.global_database.storage_encrypted

          config.compact
        end

        def build_dynamodb_replicas(attrs)
          attrs.regions.map do |region|
            {
              region_name: region.region,
              kms_key_arn: attrs.global_database.kms_key_ref&.arn,
              propagate_tags: true,
              global_secondary_indexes: [{
                index_name: 'gsi1',
                projection_type: 'ALL',
                non_key_attributes: []
              }]
            }
          end
        end

        def build_encryption_config(attrs)
          {
            enabled: true,
            kms_key_arn: attrs.global_database.kms_key_ref&.arn
          }
        end
      end
    end
  end
end
