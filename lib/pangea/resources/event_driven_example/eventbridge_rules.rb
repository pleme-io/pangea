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

require 'json'

module Pangea
  module Resources
    module Examples
      module EventDrivenEcommerce
        # EventBridge rule definitions for event-driven e-commerce architecture
        module EventBridgeRules
          include AWS

          def self.create_user_signup_rule
            aws_eventbridge_rule(:user_signup, {
              name: "user-signup-processing",
              event_bus_name: "user-service-events",
              description: "Process new user signups",
              event_pattern: JSON.generate({
                source: ["user.service"],
                "detail-type": ["User Created"],
                detail: {
                  status: ["active"]
                }
              }),
              state: "ENABLED"
            })
          end

          def self.create_order_status_rule
            aws_eventbridge_rule(:order_status, {
              name: "order-status-changes",
              event_bus_name: "order-service-events",
              description: "Track order status changes",
              event_pattern: JSON.generate({
                source: ["order.service"],
                "detail-type": ["Order Status Changed"],
                detail: {
                  newStatus: ["confirmed", "shipped", "delivered", "cancelled"]
                }
              })
            })
          end

          def self.create_low_stock_rule
            aws_eventbridge_rule(:low_stock, {
              name: "inventory-low-stock",
              event_bus_name: "inventory-service-events",
              description: "Alert when inventory is low",
              event_pattern: JSON.generate({
                source: ["inventory.service"],
                "detail-type": ["Stock Level Changed"],
                detail: {
                  stockLevel: [{ numeric: ["<", 10] }]
                }
              })
            })
          end

          def self.create_daily_reports_rule
            aws_eventbridge_rule(:daily_reports, {
              name: "daily-business-reports",
              description: "Generate daily business reports",
              schedule_expression: "cron(0 6 * * ? *)",
              state: "ENABLED"
            })
          end

          def self.create_all
            {
              user_signup: create_user_signup_rule,
              order_status: create_order_status_rule,
              low_stock: create_low_stock_rule,
              daily_reports: create_daily_reports_rule
            }
          end
        end
      end
    end
  end
end
