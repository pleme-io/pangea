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
        # EventBridge bus definitions for event-driven e-commerce architecture
        module EventBridgeBuses
          include AWS

          def self.create_user_events_bus
            aws_eventbridge_bus(:user_events, {
              name: "user-service-events",
              tags: {
                Service: "user-service",
                Domain: "UserManagement"
              }
            })
          end

          def self.create_order_events_bus
            aws_eventbridge_bus(:order_events, {
              name: "order-service-events",
              kms_key_id: "alias/order-processing-encryption",
              tags: {
                Service: "order-service",
                Domain: "OrderProcessing",
                Encryption: "enabled"
              }
            })
          end

          def self.create_inventory_events_bus
            aws_eventbridge_bus(:inventory_events, {
              name: "inventory-service-events",
              tags: {
                Service: "inventory-service",
                Domain: "InventoryManagement"
              }
            })
          end

          def self.create_all
            {
              user_events: create_user_events_bus,
              order_events: create_order_events_bus,
              inventory_events: create_inventory_events_bus
            }
          end
        end
      end
    end
  end
end
