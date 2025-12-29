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
    module SpotInstanceCarbonOptimizer
      # DynamoDB table creation methods
      module Tables
        def create_fleet_state_table(input)
          aws_dynamodb_table(:"#{input.name}-fleet-state", {
            billing_mode: "PAY_PER_REQUEST",
            hash_key: "fleet_id",
            range_key: "region",
            attribute: [
              { name: "fleet_id", type: "S" },
              { name: "region", type: "S" },
              { name: "carbon_intensity", type: "N" },
              { name: "last_migration", type: "N" }
            ],
            global_secondary_index: [
              {
                name: "carbon-intensity-index",
                hash_key: "region",
                range_key: "carbon_intensity",
                projection_type: "ALL"
              }
            ],
            stream_specification: {
              stream_enabled: true,
              stream_view_type: "NEW_AND_OLD_IMAGES"
            },
            tags: input.tags.merge(
              "Component" => "spot-carbon-optimizer",
              "Purpose" => "fleet-state"
            )
          })
        end

        def create_carbon_data_table(input)
          aws_dynamodb_table(:"#{input.name}-carbon-data", {
            billing_mode: "PAY_PER_REQUEST",
            hash_key: "region",
            range_key: "timestamp",
            attribute: [
              { name: "region", type: "S" },
              { name: "timestamp", type: "N" }
            ],
            ttl: {
              enabled: true,
              attribute_name: "expiration"
            },
            tags: input.tags.merge(
              "Component" => "spot-carbon-optimizer",
              "Purpose" => "carbon-data"
            )
          })
        end

        def create_migration_history_table(input)
          aws_dynamodb_table(:"#{input.name}-migration-history", {
            billing_mode: "PAY_PER_REQUEST",
            hash_key: "migration_id",
            range_key: "timestamp",
            attribute: [
              { name: "migration_id", type: "S" },
              { name: "timestamp", type: "N" },
              { name: "source_region", type: "S" },
              { name: "target_region", type: "S" }
            ],
            global_secondary_index: [
              {
                name: "region-time-index",
                hash_key: "source_region",
                range_key: "timestamp",
                projection_type: "ALL"
              }
            ],
            tags: input.tags.merge(
              "Component" => "spot-carbon-optimizer",
              "Purpose" => "migration-history"
            )
          })
        end
      end
    end
  end
end
