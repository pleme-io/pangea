#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/pangea'
require 'pangea/resources/aws_sqs_queue/resource'
require 'pangea/resources/aws_sqs_queue_policy/resource'
require 'pangea/resources/aws_sns_topic/resource'
require 'pangea/resources/aws_sns_subscription/resource'

# Example: Event-driven messaging architecture
template :messaging_infrastructure do
  include Pangea::Resources::AWS

  # Create a FIFO SNS topic for ordered events
  order_topic = aws_sns_topic(:order_events, {
    name: "order-events.fifo",
    fifo_topic: true,
    content_based_deduplication: true,
    kms_master_key_id: "alias/aws/sns",
    tags: {
      Application: "OrderProcessing",
      Environment: "production"
    }
  })

  # Create SQS queues for different services
  
  # Order processing queue with DLQ
  order_dlq = aws_sqs_queue(:order_dlq, {
    name: "order-processing-dlq",
    message_retention_seconds: 1209600  # 14 days
  })

  order_queue = aws_sqs_queue(:order_processor, {
    name: "order-processing-queue",
    visibility_timeout_seconds: 300,  # 5 minutes
    receive_wait_time_seconds: 20,    # Long polling
    kms_master_key_id: "alias/aws/sqs",
    redrive_policy: {
      deadLetterTargetArn: order_dlq.arn,
      maxReceiveCount: 3
    },
    tags: {
      Service: "OrderProcessor"
    }
  })

  # Inventory update queue
  inventory_queue = aws_sqs_queue(:inventory_updates, {
    name: "inventory-update-queue",
    visibility_timeout_seconds: 60,
    receive_wait_time_seconds: 10
  })

  # Analytics FIFO queue
  analytics_queue = aws_sqs_queue(:analytics_events, {
    name: "analytics-events.fifo",
    fifo_queue: true,
    content_based_deduplication: true,
    message_retention_seconds: 604800  # 7 days
  })

  # Queue policies to allow SNS to send messages
  order_queue_policy = aws_sqs_queue_policy(:order_queue_policy, {
    queue_url: order_queue.url,
    policy: JSON.generate({
      Version: "2012-10-17",
      Statement: [{
        Effect: "Allow",
        Principal: { Service: "sns.amazonaws.com" },
        Action: "sqs:SendMessage",
        Resource: "*",
        Condition: {
          ArnEquals: { "aws:SourceArn": order_topic.arn }
        }
      }]
    })
  })

  # Subscribe queues to topic with filters
  
  # Order processing subscription
  order_subscription = aws_sns_subscription(:order_queue_sub, {
    topic_arn: order_topic.arn,
    protocol: "sqs",
    endpoint: order_queue.arn,
    raw_message_delivery: true,
    filter_policy: JSON.generate({
      event_type: ["order_created", "order_updated"],
      priority: ["high", "medium"]
    })
  })

  # Inventory subscription - only for created orders
  inventory_subscription = aws_sns_subscription(:inventory_sub, {
    topic_arn: order_topic.arn,
    protocol: "sqs",
    endpoint: inventory_queue.arn,
    filter_policy: JSON.generate({
      event_type: ["order_created"],
      contains_physical_items: [true]
    })
  })

  # Analytics subscription - all events
  analytics_subscription = aws_sns_subscription(:analytics_sub, {
    topic_arn: order_topic.arn,
    protocol: "sqs",
    endpoint: analytics_queue.arn,
    raw_message_delivery: true
  })

  # Email subscription for critical alerts
  email_subscription = aws_sns_subscription(:critical_alerts, {
    topic_arn: order_topic.arn,
    protocol: "email",
    endpoint: "ops-team@example.com",
    filter_policy: JSON.generate({
      alert_level: ["critical"],
      event_type: ["order_failed", "payment_failed"]
    })
  })

  # Outputs
  output :order_topic_arn do
    value order_topic.arn
    description "ARN of the order events topic"
  end

  output :order_queue_url do
    value order_queue.url
    description "URL of the order processing queue"
  end

  output :dlq_arn do
    value order_dlq.arn
    description "ARN of the dead letter queue"
  end

  output :messaging_info do
    value {
      topic_type: order_topic.computed.topic_type,
      queues: {
        order_queue: {
          type: order_queue.computed.queue_type,
          encrypted: order_queue.computed.is_encrypted,
          has_dlq: order_queue.computed.has_dlq
        },
        analytics_queue: {
          type: analytics_queue.computed.queue_type,
          is_fifo: analytics_queue.computed.is_fifo
        }
      },
      subscriptions: {
        order: {
          requires_confirmation: order_subscription.computed.requires_confirmation,
          supports_filtering: order_subscription.computed.supports_filter_policy
        },
        email: {
          requires_confirmation: email_subscription.computed.requires_confirmation
        }
      }
    }
    description "Messaging infrastructure configuration summary"
  end
end

# Example usage
puts "Messaging infrastructure template created successfully!"
puts "This example demonstrates:"
puts "- SNS FIFO topic with encryption"
puts "- Multiple SQS queues with different configurations"
puts "- Dead letter queue setup"
puts "- Subscription filtering"
puts "- Cross-service integration patterns"