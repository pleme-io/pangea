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
    module Examples
      module EventDrivenEcommerce
        # DynamoDB table definitions for event-driven e-commerce architecture
        module DynamoDBTables
          include AWS

          def self.create_users_table
            aws_dynamodb_table(:users, {
              name: "users",
              billing_mode: "PAY_PER_REQUEST",
              attribute: [
                { name: "user_id", type: "S" },
                { name: "email", type: "S" }
              ],
              hash_key: "user_id",
              global_secondary_index: [
                {
                  name: "EmailIndex",
                  hash_key: "email",
                  projection_type: "ALL"
                }
              ],
              stream_enabled: true,
              stream_view_type: "NEW_AND_OLD_IMAGES"
            })
          end

          def self.create_orders_table
            aws_dynamodb_table(:orders, {
              name: "orders",
              billing_mode: "PAY_PER_REQUEST",
              attribute: [
                { name: "order_id", type: "S" },
                { name: "user_id", type: "S" },
                { name: "order_date", type: "S" },
                { name: "status", type: "S" }
              ],
              hash_key: "order_id",
              global_secondary_index: [
                {
                  name: "UserOrdersIndex",
                  hash_key: "user_id",
                  range_key: "order_date",
                  projection_type: "ALL"
                },
                {
                  name: "StatusIndex",
                  hash_key: "status",
                  range_key: "order_date",
                  projection_type: "KEYS_ONLY"
                }
              ],
              stream_enabled: true,
              stream_view_type: "NEW_AND_OLD_IMAGES"
            })
          end

          def self.create_inventory_global_table
            aws_dynamodb_global_table(:inventory, {
              name: "global-inventory",
              billing_mode: "PAY_PER_REQUEST",
              server_side_encryption: { enabled: true },
              point_in_time_recovery: { enabled: true },
              stream_enabled: true,
              stream_view_type: "NEW_AND_OLD_IMAGES",
              replica: [
                { region_name: "us-east-1", table_class: "STANDARD" },
                { region_name: "us-west-2", table_class: "STANDARD" },
                { region_name: "eu-west-1", table_class: "STANDARD_INFREQUENT_ACCESS" }
              ]
            })
          end

          def self.create_all
            {
              users: create_users_table,
              orders: create_orders_table,
              inventory: create_inventory_global_table
            }
          end
        end
      end
    end
  end
end
