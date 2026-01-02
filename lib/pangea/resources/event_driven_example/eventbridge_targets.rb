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
        # EventBridge target definitions for event-driven e-commerce architecture
        module EventBridgeTargets
          include AWS

          def self.create_signup_email_target
            aws_eventbridge_target(:signup_email, {
              rule: "user-signup-processing",
              event_bus_name: "user-service-events",
              target_id: "send-welcome-email",
              arn: "arn:aws:lambda:us-east-1:123456789012:function:SendWelcomeEmail",
              input_transformer: {
                input_paths: {
                  "userId" => "$.detail.userId",
                  "email" => "$.detail.email",
                  "name" => "$.detail.name"
                },
                input_template: JSON.generate({
                  user_id: "<userId>",
                  email_address: "<email>",
                  user_name: "<name>",
                  template: "welcome_email",
                  source: "user_signup_event"
                })
              }
            })
          end

          def self.create_order_processing_target
            aws_eventbridge_target(:order_processing, {
              rule: "order-status-changes",
              event_bus_name: "order-service-events",
              target_id: "order-processing-queue",
              arn: "arn:aws:sqs:us-east-1:123456789012:order-processing-queue",
              retry_policy: {
                maximum_retry_attempts: 3,
                maximum_event_age_in_seconds: 1800
              },
              dead_letter_config: {
                arn: "arn:aws:sqs:us-east-1:123456789012:failed-orders-dlq"
              }
            })
          end

          def self.create_inventory_alert_target
            aws_eventbridge_target(:inventory_alerts, {
              rule: "inventory-low-stock",
              event_bus_name: "inventory-service-events",
              target_id: "inventory-alert-topic",
              arn: "arn:aws:sns:us-east-1:123456789012:inventory-alerts",
              role_arn: "arn:aws:iam::123456789012:role/EventBridgeSNSRole"
            })
          end

          def self.create_daily_report_target
            aws_eventbridge_target(:daily_reports, {
              rule: "daily-business-reports",
              target_id: "daily-report-task",
              arn: "arn:aws:ecs:us-east-1:123456789012:cluster/reporting-cluster",
              role_arn: "arn:aws:iam::123456789012:role/EventBridgeECSRole",
              ecs_parameters: {
                task_definition_arn: "arn:aws:ecs:us-east-1:123456789012:task-definition/daily-reports:1",
                launch_type: "FARGATE",
                task_count: 1,
                network_configuration: {
                  awsvpc_configuration: {
                    subnets: ["subnet-12345678", "subnet-87654321"],
                    security_groups: ["sg-reporting"],
                    assign_public_ip: "DISABLED"
                  }
                }
              }
            })
          end

          def self.create_analytics_target
            aws_eventbridge_target(:analytics_stream, {
              rule: "order-status-changes",
              event_bus_name: "order-service-events",
              target_id: "order-analytics-stream",
              arn: "arn:aws:kinesis:us-east-1:123456789012:stream/order-analytics",
              role_arn: "arn:aws:iam::123456789012:role/EventBridgeKinesisRole",
              kinesis_parameters: {
                partition_key_path: "$.detail.orderId"
              }
            })
          end

          def self.create_all
            {
              signup_email: create_signup_email_target,
              order_processing: create_order_processing_target,
              inventory_alerts: create_inventory_alert_target,
              daily_reports: create_daily_report_target,
              analytics: create_analytics_target
            }
          end
        end
      end
    end
  end
end
