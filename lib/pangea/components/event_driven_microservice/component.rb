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


require 'pangea/components/base'
require 'pangea/components/event_driven_microservice/types'
require 'pangea/resources/aws'
require 'json'

module Pangea
  module Components
    # Event-driven microservice with event sourcing, CQRS, and saga orchestration patterns
    # Creates a complete event-driven architecture with Lambda functions, DynamoDB, and EventBridge
    def event_driven_microservice(name, attributes = {})
      include Base
      include Resources::AWS
      
      # Validate and set defaults
      component_attrs = EventDrivenMicroservice::EventDrivenMicroserviceAttributes.new(attributes)
      component_attrs.validate!
      
      # Generate component-specific tags
      component_tag_set = component_tags('EventDrivenMicroservice', name, component_attrs.tags)
      
      resources = {}
      
      # Create IAM role for Lambda functions
      lambda_role_ref = aws_iam_role(component_resource_name(name, :lambda_role), {
        name: "#{name}-lambda-role",
        assume_role_policy: JSON.generate({
          Version: "2012-10-17",
          Statement: [{
            Action: "sts:AssumeRole",
            Effect: "Allow",
            Principal: {
              Service: "lambda.amazonaws.com"
            }
          }]
        }),
        tags: component_tag_set
      })
      resources[:lambda_role] = lambda_role_ref
      
      # Attach basic Lambda execution policy
      lambda_basic_policy_attachment = aws_iam_role_policy_attachment(
        component_resource_name(name, :lambda_basic_policy),
        {
          role: lambda_role_ref.name,
          policy_arn: "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        }
      )
      resources[:lambda_basic_policy] = lambda_basic_policy_attachment
      
      # Attach VPC execution policy if VPC is configured
      if component_attrs.vpc_ref
        vpc_policy_attachment = aws_iam_role_policy_attachment(
          component_resource_name(name, :lambda_vpc_policy),
          {
            role: lambda_role_ref.name,
            policy_arn: "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
          }
        )
        resources[:lambda_vpc_policy] = vpc_policy_attachment
      end
      
      # Create event store DynamoDB table
      event_store_ref = aws_dynamodb_table(component_resource_name(name, :event_store), {
        name: component_attrs.event_store.table_name,
        billing_mode: "PAY_PER_REQUEST",
        hash_key: "aggregate_id",
        range_key: "sequence_number",
        
        attribute: [
          { name: "aggregate_id", type: "S" },
          { name: "sequence_number", type: "N" },
          { name: "event_type", type: "S" },
          { name: "timestamp", type: "S" }
        ],
        
        global_secondary_index: [
          {
            name: "event-type-index",
            hash_key: "event_type",
            range_key: "timestamp",
            projection_type: "ALL"
          }
        ] + component_attrs.event_store.global_secondary_indexes,
        
        stream_enabled: component_attrs.event_store.stream_enabled,
        stream_view_type: component_attrs.event_store.stream_enabled ? "NEW_AND_OLD_IMAGES" : nil,
        
        ttl: component_attrs.event_store.ttl_days ? {
          attribute_name: "ttl",
          enabled: true
        } : nil,
        
        server_side_encryption: component_attrs.event_store.encryption_type == "KMS" ? {
          enabled: true,
          kms_key_arn: component_attrs.event_store.kms_key_ref&.arn
        } : nil,
        
        point_in_time_recovery: {
          enabled: component_attrs.event_store.point_in_time_recovery
        },
        
        tags: component_tag_set
      }.compact)
      resources[:event_store] = event_store_ref
      
      # Create CQRS tables if enabled
      if component_attrs.cqrs&.enabled
        # Command table for write operations
        command_table_ref = aws_dynamodb_table(component_resource_name(name, :command_table), {
          name: component_attrs.cqrs.command_table_name,
          billing_mode: "PAY_PER_REQUEST",
          hash_key: "command_id",
          range_key: "timestamp",
          
          attribute: [
            { name: "command_id", type: "S" },
            { name: "timestamp", type: "S" },
            { name: "aggregate_id", type: "S" },
            { name: "status", type: "S" }
          ],
          
          global_secondary_index: [
            {
              name: "aggregate-index",
              hash_key: "aggregate_id",
              range_key: "timestamp",
              projection_type: "ALL"
            },
            {
              name: "status-index", 
              hash_key: "status",
              range_key: "timestamp",
              projection_type: "ALL"
            }
          ],
          
          server_side_encryption: {
            enabled: true
          },
          
          tags: component_tag_set
        })
        resources[:command_table] = command_table_ref
        
        # Query table for read operations
        query_table_ref = aws_dynamodb_table(component_resource_name(name, :query_table), {
          name: component_attrs.cqrs.query_table_name,
          billing_mode: "PAY_PER_REQUEST",
          hash_key: "id",
          
          attribute: [
            { name: "id", type: "S" },
            { name: "type", type: "S" },
            { name: "updated_at", type: "S" }
          ],
          
          global_secondary_index: [
            {
              name: "type-index",
              hash_key: "type",
              range_key: "updated_at",
              projection_type: "ALL"
            }
          ],
          
          server_side_encryption: {
            enabled: true
          },
          
          tags: component_tag_set
        })
        resources[:query_table] = query_table_ref
      end
      
      # Create dead letter queue if enabled
      if component_attrs.dead_letter_queue_enabled
        dlq_ref = aws_sqs_queue(component_resource_name(name, :dlq), {
          name: "#{name}-dlq",
          message_retention_seconds: 1209600, # 14 days
          kms_master_key_id: "alias/aws/sqs",
          tags: component_tag_set
        })
        resources[:dead_letter_queue] = dlq_ref
      end
      
      # Create command handler Lambda function
      command_handler_ref = create_lambda_function(
        component_resource_name(name, :command_handler),
        "#{name}-command-handler",
        component_attrs.command_handler,
        lambda_role_ref,
        component_attrs,
        component_tag_set
      )
      resources[:command_handler] = command_handler_ref
      
      # Create query handler Lambda function if CQRS is enabled
      if component_attrs.query_handler
        query_handler_ref = create_lambda_function(
          component_resource_name(name, :query_handler),
          "#{name}-query-handler",
          component_attrs.query_handler,
          lambda_role_ref,
          component_attrs,
          component_tag_set
        )
        resources[:query_handler] = query_handler_ref
      end
      
      # Create event processor Lambda function if configured
      if component_attrs.event_processor
        event_processor_ref = create_lambda_function(
          component_resource_name(name, :event_processor),
          "#{name}-event-processor",
          component_attrs.event_processor,
          lambda_role_ref,
          component_attrs,
          component_tag_set
        )
        resources[:event_processor] = event_processor_ref
      end
      
      # Create IAM policy for Lambda functions to access resources
      lambda_policy_ref = aws_iam_role_policy(component_resource_name(name, :lambda_policy), {
        name: "#{name}-lambda-policy",
        role: lambda_role_ref.id,
        policy: JSON.generate({
          Version: "2012-10-17",
          Statement: [
            {
              Effect: "Allow",
              Action: [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:BatchGetItem",
                "dynamodb:BatchWriteItem",
                "dynamodb:DescribeStream",
                "dynamodb:GetRecords",
                "dynamodb:GetShardIterator",
                "dynamodb:ListStreams"
              ],
              Resource: [
                event_store_ref.arn,
                "#{event_store_ref.arn}/index/*",
                "#{event_store_ref.arn}/stream/*"
              ] + (component_attrs.cqrs&.enabled ? [
                resources[:command_table].arn,
                "#{resources[:command_table].arn}/index/*",
                resources[:query_table].arn,
                "#{resources[:query_table].arn}/index/*"
              ] : [])
            },
            {
              Effect: "Allow",
              Action: [
                "events:PutEvents"
              ],
              Resource: "*"
            },
            {
              Effect: "Allow",
              Action: [
                "sqs:SendMessage",
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage",
                "sqs:GetQueueAttributes"
              ],
              Resource: component_attrs.dead_letter_queue_enabled ? [dlq_ref.arn] : []
            },
            {
              Effect: "Allow",
              Action: [
                "xray:PutTraceSegments",
                "xray:PutTelemetryRecords"
              ],
              Resource: "*"
            }
          ]
        })
      })
      resources[:lambda_policy] = lambda_policy_ref
      
      # Create event source mappings
      event_source_mappings = {}
      component_attrs.event_sources.each_with_index do |source, index|
        case source.type
        when 'EventBridge'
          # Create EventBridge rule
          rule_ref = aws_eventbridge_rule(
            component_resource_name(name, :event_rule, "source#{index}".to_sym),
            {
              name: "#{name}-event-rule-#{index}",
              description: "Event rule for #{component_attrs.service_name}",
              event_pattern: JSON.generate(source.event_pattern),
              state: "ENABLED",
              tags: component_tag_set
            }
          )
          
          # Create permission for EventBridge to invoke Lambda
          permission_ref = aws_lambda_permission(
            component_resource_name(name, :event_permission, "source#{index}".to_sym),
            {
              statement_id: "AllowEventBridge#{index}",
              action: "lambda:InvokeFunction",
              function_name: command_handler_ref.function_name,
              principal: "events.amazonaws.com",
              source_arn: rule_ref.arn
            }
          )
          
          # Create target
          target_ref = aws_eventbridge_target(
            component_resource_name(name, :event_target, "source#{index}".to_sym),
            {
              rule: rule_ref.name,
              target_id: "Lambda#{index}",
              arn: command_handler_ref.arn,
              retry_policy: {
                maximum_retry_attempts: source.maximum_retry_attempts,
                maximum_event_age_in_seconds: 3600
              },
              dead_letter_config: source.on_failure_destination_arn ? {
                arn: source.on_failure_destination_arn
              } : nil
            }.compact
          )
          
          event_source_mappings["eventbridge#{index}".to_sym] = {
            rule: rule_ref,
            permission: permission_ref,
            target: target_ref
          }
          
        when 'SQS'
          # Create SQS event source mapping
          mapping_ref = aws_lambda_event_source_mapping(
            component_resource_name(name, :sqs_mapping, "source#{index}".to_sym),
            {
              event_source_arn: source.source_arn || source.source_ref.arn,
              function_name: command_handler_ref.function_name,
              batch_size: source.batch_size,
              maximum_batching_window_in_seconds: source.maximum_batching_window,
              function_response_types: ["ReportBatchItemFailures"]
            }
          )
          event_source_mappings["sqs#{index}".to_sym] = mapping_ref
          
        when 'Kinesis', 'DynamoDB'
          # Create stream event source mapping
          mapping_ref = aws_lambda_event_source_mapping(
            component_resource_name(name, :stream_mapping, "source#{index}".to_sym),
            {
              event_source_arn: source.source_arn || source.source_ref.arn,
              function_name: event_processor_ref ? event_processor_ref.function_name : command_handler_ref.function_name,
              batch_size: source.batch_size,
              maximum_batching_window_in_seconds: source.maximum_batching_window,
              starting_position: source.starting_position,
              parallelization_factor: source.parallelization_factor,
              maximum_retry_attempts: source.maximum_retry_attempts,
              on_failure: source.on_failure_destination_arn ? {
                destination_arn: source.on_failure_destination_arn
              } : nil
            }.compact
          )
          event_source_mappings["stream#{index}".to_sym] = mapping_ref
        end
      end
      resources[:event_source_mappings] = event_source_mappings
      
      # Create API Gateway integration if enabled
      if component_attrs.api_gateway_enabled && component_attrs.api_gateway_ref
        # Permission for API Gateway to invoke Lambda
        api_permission_ref = aws_lambda_permission(
          component_resource_name(name, :api_permission),
          {
            statement_id: "AllowAPIGateway",
            action: "lambda:InvokeFunction",
            function_name: command_handler_ref.function_name,
            principal: "apigateway.amazonaws.com",
            source_arn: "#{component_attrs.api_gateway_ref.execution_arn}/*/*"
          }
        )
        resources[:api_permission] = api_permission_ref
      end
      
      # Create CloudWatch Dashboard if monitoring is enabled
      if component_attrs.monitoring.dashboard_enabled
        dashboard_ref = aws_cloudwatch_dashboard(
          component_resource_name(name, :dashboard),
          {
            dashboard_name: "#{name}-event-driven-dashboard",
            dashboard_body: JSON.generate({
              widgets: [
                {
                  type: "metric",
                  properties: {
                    metrics: [
                      ["AWS/Lambda", "Invocations", { stat: "Sum" }],
                      [".", "Errors", { stat: "Sum" }],
                      [".", "Duration", { stat: "Average" }],
                      [".", "ConcurrentExecutions", { stat: "Maximum" }]
                    ],
                    period: 300,
                    stat: "Average",
                    region: "${AWS::Region}",
                    title: "Lambda Metrics"
                  }
                },
                {
                  type: "metric",
                  properties: {
                    metrics: [
                      ["AWS/DynamoDB", "UserErrors", { stat: "Sum" }],
                      [".", "SystemErrors", { stat: "Sum" }],
                      [".", "ConsumedReadCapacityUnits", { stat: "Sum" }],
                      [".", "ConsumedWriteCapacityUnits", { stat: "Sum" }]
                    ],
                    period: 300,
                    stat: "Sum",
                    region: "${AWS::Region}",
                    title: "DynamoDB Metrics"
                  }
                }
              ]
            })
          }
        )
        resources[:dashboard] = dashboard_ref
      end
      
      # Create CloudWatch alarms
      alarms = {}
      
      # Lambda error rate alarm
      error_alarm_ref = aws_cloudwatch_metric_alarm(
        component_resource_name(name, :error_alarm),
        {
          alarm_name: "#{name}-lambda-error-rate",
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: "2",
          metric_name: "Errors",
          namespace: "AWS/Lambda",
          period: "300",
          statistic: "Average",
          threshold: (component_attrs.monitoring.error_rate_threshold * 100).to_s,
          alarm_description: "Lambda error rate is too high",
          dimensions: {
            FunctionName: command_handler_ref.function_name
          },
          tags: component_tag_set
        }
      )
      alarms[:error_rate] = error_alarm_ref
      
      # Event processing latency alarm
      latency_alarm_ref = aws_cloudwatch_metric_alarm(
        component_resource_name(name, :latency_alarm),
        {
          alarm_name: "#{name}-event-processing-latency",
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: "3",
          metric_name: "Duration",
          namespace: "AWS/Lambda",
          period: "300",
          statistic: "Average",
          threshold: component_attrs.monitoring.event_processing_threshold.to_s,
          alarm_description: "Event processing is taking too long",
          dimensions: {
            FunctionName: command_handler_ref.function_name
          },
          tags: component_tag_set
        }
      )
      alarms[:latency] = latency_alarm_ref
      
      # Dead letter queue alarm if enabled
      if component_attrs.dead_letter_queue_enabled
        dlq_alarm_ref = aws_cloudwatch_metric_alarm(
          component_resource_name(name, :dlq_alarm),
          {
            alarm_name: "#{name}-dlq-messages",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: "1",
            metric_name: "ApproximateNumberOfMessagesVisible",
            namespace: "AWS/SQS",
            period: "300",
            statistic: "Maximum",
            threshold: component_attrs.monitoring.dead_letter_threshold.to_s,
            alarm_description: "Dead letter queue has too many messages",
            dimensions: {
              QueueName: dlq_ref.name
            },
            tags: component_tag_set
          }
        )
        alarms[:dlq] = dlq_alarm_ref
      end
      
      resources[:alarms] = alarms
      
      # Create SNS topic for alarm notifications if email is configured
      if component_attrs.monitoring.alarm_email
        alarm_topic_ref = aws_sns_topic(
          component_resource_name(name, :alarm_topic),
          {
            name: "#{name}-alarms",
            display_name: "#{component_attrs.service_name} Alarms",
            tags: component_tag_set
          }
        )
        resources[:alarm_topic] = alarm_topic_ref
        
        # Subscribe email to topic
        email_subscription_ref = aws_sns_topic_subscription(
          component_resource_name(name, :alarm_subscription),
          {
            topic_arn: alarm_topic_ref.arn,
            protocol: "email",
            endpoint: component_attrs.monitoring.alarm_email
          }
        )
        resources[:alarm_subscription] = email_subscription_ref
        
        # Update alarms to send to SNS
        alarms.each do |alarm_name, alarm_ref|
          alarm_action_ref = aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_action, alarm_name),
            {
              alarm_name: alarm_ref.alarm_name,
              alarm_actions: [alarm_topic_ref.arn],
              insufficient_data_actions: [alarm_topic_ref.arn]
            }
          )
        end
      end
      
      # Calculate outputs
      outputs = {
        service_name: component_attrs.service_name,
        command_handler_arn: command_handler_ref.arn,
        query_handler_arn: component_attrs.query_handler ? resources[:query_handler].arn : nil,
        event_processor_arn: component_attrs.event_processor ? resources[:event_processor].arn : nil,
        event_store_name: event_store_ref.name,
        event_store_stream_arn: event_store_ref.stream_arn,
        
        event_sources: component_attrs.event_sources.map.with_index do |source, index|
          {
            type: source.type,
            mapping: event_source_mappings.values[index]
          }
        end,
        
        patterns_enabled: [
          "Event Sourcing",
          ("CQRS" if component_attrs.cqrs&.enabled),
          ("Saga Orchestration" if component_attrs.saga&.enabled),
          ("Event Replay" if component_attrs.event_replay.enabled),
          ("Dead Letter Queue" if component_attrs.dead_letter_queue_enabled)
        ].compact,
        
        monitoring_features: [
          ("CloudWatch Dashboard" if component_attrs.monitoring.dashboard_enabled),
          "CloudWatch Alarms",
          ("Email Notifications" if component_attrs.monitoring.alarm_email),
          "X-Ray Tracing"
        ].compact,
        
        estimated_monthly_cost: estimate_event_driven_cost(component_attrs)
      }
      
      create_component_reference(
        'event_driven_microservice',
        name,
        component_attrs.to_h,
        resources,
        outputs
      )
    end
    
    private
    
    def create_lambda_function(name, function_name, config, role_ref, component_attrs, tags)
      vpc_config = if component_attrs.vpc_ref
        {
          subnet_ids: component_attrs.subnet_refs.map(&:id),
          security_group_ids: component_attrs.security_group_refs.map(&:id)
        }
      else
        nil
      end
      
      aws_lambda_function(name, {
        function_name: function_name,
        role: role_ref.arn,
        handler: config.handler,
        runtime: config.runtime,
        timeout: config.timeout,
        memory_size: config.memory_size,
        environment: {
          variables: config.environment_variables.merge({
            SERVICE_NAME: component_attrs.service_name,
            EVENT_STORE_TABLE: component_attrs.event_store.table_name
          })
        },
        layers: config.layers,
        reserved_concurrent_executions: config.reserved_concurrent_executions,
        dead_letter_config: config.dead_letter_config_arn ? {
          target_arn: config.dead_letter_config_arn
        } : nil,
        vpc_config: vpc_config,
        tracing_config: {
          mode: "Active"
        },
        tags: tags
      }.compact)
    end
    
    def estimate_event_driven_cost(attrs)
      cost = 0.0
      
      # Lambda costs (estimated 1M requests per month)
      requests_per_month = 1_000_000
      lambda_request_cost = (requests_per_month / 1_000_000) * 0.20
      lambda_compute_cost = (requests_per_month * 0.5 * attrs.command_handler.memory_size / 1024) * 0.0000166667
      cost += lambda_request_cost + lambda_compute_cost
      
      # DynamoDB costs (on-demand pricing, estimated)
      cost += 25.0  # Base estimate for event store
      cost += 20.0 if attrs.cqrs&.enabled  # Additional tables
      
      # EventBridge costs (if used)
      eventbridge_sources = attrs.event_sources.count { |s| s.type == 'EventBridge' }
      cost += eventbridge_sources * 1.0  # $1 per million events
      
      # SQS costs (if DLQ enabled)
      cost += 0.50 if attrs.dead_letter_queue_enabled
      
      # CloudWatch costs
      cost += 5.0  # Logs and metrics
      cost += 3.0 if attrs.monitoring.dashboard_enabled
      
      cost.round(2)
    end
  end
end