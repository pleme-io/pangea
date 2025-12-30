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

# Example usage of DynamoDB and EventBridge resources for event-driven architecture
require 'pangea/resources/aws_resources'
require_relative 'event_driven_example/dynamodb_tables'
require_relative 'event_driven_example/eventbridge_buses'
require_relative 'event_driven_example/eventbridge_rules'
require_relative 'event_driven_example/eventbridge_targets'

module Pangea
  module Resources
    module Examples
      # Complete event-driven e-commerce architecture example
      #
      # This class demonstrates how to create a complete event-driven architecture
      # using DynamoDB tables for data storage and EventBridge for event routing.
      #
      # Components:
      # - DynamoDB tables: users, orders, and global inventory
      # - EventBridge buses: user events, order events, inventory events
      # - EventBridge rules: user signup, order status, low stock alerts, daily reports
      # - EventBridge targets: email notifications, SQS queues, SNS topics, ECS tasks
      class EventDrivenEcommerce
        include AWS

        # Creates the complete event-driven e-commerce infrastructure
        #
        # @return [Hash] All created resources organized by type
        def self.create_infrastructure
          {
            tables: EventDrivenEcommerce::DynamoDBTables.create_all,
            buses: EventDrivenEcommerce::EventBridgeBuses.create_all,
            rules: EventDrivenEcommerce::EventBridgeRules.create_all,
            targets: EventDrivenEcommerce::EventBridgeTargets.create_all
          }
        end

        # Creates only the DynamoDB tables
        #
        # @return [Hash] Created DynamoDB table resources
        def self.create_tables
          EventDrivenEcommerce::DynamoDBTables.create_all
        end

        # Creates only the EventBridge buses
        #
        # @return [Hash] Created EventBridge bus resources
        def self.create_buses
          EventDrivenEcommerce::EventBridgeBuses.create_all
        end

        # Creates only the EventBridge rules
        #
        # @return [Hash] Created EventBridge rule resources
        def self.create_rules
          EventDrivenEcommerce::EventBridgeRules.create_all
        end

        # Creates only the EventBridge targets
        #
        # @return [Hash] Created EventBridge target resources
        def self.create_targets
          EventDrivenEcommerce::EventBridgeTargets.create_all
        end
      end
    end
  end
end
