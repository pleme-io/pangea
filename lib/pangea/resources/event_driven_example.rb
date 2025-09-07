# frozen_string_literal: true

# Example usage of DynamoDB and EventBridge resources for event-driven architecture
require 'pangea/resources/aws_resources'

module Pangea
  module Resources
    module Examples
      # Complete event-driven e-commerce architecture example
      class EventDrivenEcommerce
        include AWS

        def self.create_infrastructure
          # 1. Create DynamoDB tables for different domains
          
          # User data table
          users_table = aws_dynamodb_table(:users, {
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

          # Orders table with complex indexing
          orders_table = aws_dynamodb_table(:orders, {
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

          # Global inventory table for multi-region access
          inventory_global = aws_dynamodb_global_table(:inventory, {
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

          # 2. Create EventBridge buses for different domains
          
          # User service events
          user_bus = aws_eventbridge_bus(:user_events, {
            name: "user-service-events",
            tags: {
              Service: "user-service",
              Domain: "UserManagement"
            }
          })

          # Order processing events
          order_bus = aws_eventbridge_bus(:order_events, {
            name: "order-service-events",
            kms_key_id: "alias/order-processing-encryption",
            tags: {
              Service: "order-service",
              Domain: "OrderProcessing",
              Encryption: "enabled"
            }
          })

          # Inventory management events
          inventory_bus = aws_eventbridge_bus(:inventory_events, {
            name: "inventory-service-events",
            tags: {
              Service: "inventory-service",
              Domain: "InventoryManagement"
            }
          })

          # 3. Create EventBridge rules for event processing
          
          # User signup processing rule
          user_signup_rule = aws_eventbridge_rule(:user_signup, {
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

          # Order status change rule
          order_status_rule = aws_eventbridge_rule(:order_status, {
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

          # Inventory low stock alert rule
          low_stock_rule = aws_eventbridge_rule(:low_stock, {
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

          # Scheduled daily reporting rule
          daily_reports_rule = aws_eventbridge_rule(:daily_reports, {
            name: "daily-business-reports",
            description: "Generate daily business reports",
            schedule_expression: "cron(0 6 * * ? *)",  # 6 AM daily
            state: "ENABLED"
          })

          # 4. Create EventBridge targets for event processing
          
          # User signup email notification target
          signup_email_target = aws_eventbridge_target(:signup_email, {
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

          # Order processing SQS target with DLQ
          order_processing_target = aws_eventbridge_target(:order_processing, {
            rule: "order-status-changes",
            event_bus_name: "order-service-events",
            target_id: "order-processing-queue",
            arn: "arn:aws:sqs:us-east-1:123456789012:order-processing-queue",
            retry_policy: {
              maximum_retry_attempts: 3,
              maximum_event_age_in_seconds: 1800  # 30 minutes
            },
            dead_letter_config: {
              arn: "arn:aws:sqs:us-east-1:123456789012:failed-orders-dlq"
            }
          })

          # Inventory alert SNS target
          inventory_alert_target = aws_eventbridge_target(:inventory_alerts, {
            rule: "inventory-low-stock",
            event_bus_name: "inventory-service-events", 
            target_id: "inventory-alert-topic",
            arn: "arn:aws:sns:us-east-1:123456789012:inventory-alerts",
            role_arn: "arn:aws:iam::123456789012:role/EventBridgeSNSRole"
          })

          # Daily report ECS task target
          daily_report_target = aws_eventbridge_target(:daily_reports, {
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

          # Kinesis analytics target for real-time insights
          analytics_target = aws_eventbridge_target(:analytics_stream, {
            rule: "order-status-changes",
            event_bus_name: "order-service-events",
            target_id: "order-analytics-stream",
            arn: "arn:aws:kinesis:us-east-1:123456789012:stream/order-analytics",
            role_arn: "arn:aws:iam::123456789012:role/EventBridgeKinesisRole",
            kinesis_parameters: {
              partition_key_path: "$.detail.orderId"
            }
          })

          # Return all created resources for reference
          {
            tables: {
              users: users_table,
              orders: orders_table,
              inventory: inventory_global
            },
            buses: {
              user_events: user_bus,
              order_events: order_bus,
              inventory_events: inventory_bus
            },
            rules: {
              user_signup: user_signup_rule,
              order_status: order_status_rule,
              low_stock: low_stock_rule,
              daily_reports: daily_reports_rule
            },
            targets: {
              signup_email: signup_email_target,
              order_processing: order_processing_target,
              inventory_alerts: inventory_alert_target,
              daily_reports: daily_report_target,
              analytics: analytics_target
            }
          }
        end
      end
    end
  end
end