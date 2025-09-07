# Event-Driven Microservice Component

Event-driven microservice with event sourcing, CQRS pattern, saga orchestration, and event replay capabilities.

## Overview

The `event_driven_microservice` component creates a complete event-driven architecture implementing advanced patterns:

- **Event Sourcing**: Store all changes as immutable events
- **CQRS Pattern**: Separate command and query responsibilities
- **Saga Orchestration**: Manage distributed transactions
- **Event Replay**: Rebuild state from event history
- **Multiple Event Sources**: EventBridge, SQS, SNS, Kinesis, DynamoDB Streams
- **Dead Letter Queues**: Handle failed event processing
- **Comprehensive Monitoring**: CloudWatch dashboards and alarms

## Usage

### Basic Event-Driven Service

```ruby
# Create a simple event-driven microservice
order_service = event_driven_microservice(:order_service, {
  service_name: "order-service",
  service_description: "Order processing service",
  
  event_sources: [{
    type: "EventBridge",
    event_pattern: {
      source: ["ecommerce.orders"],
      "detail-type": ["Order Created", "Order Updated"]
    }
  }],
  
  command_handler: {
    runtime: "python3.9",
    handler: "handlers.command_handler",
    timeout: 60,
    memory_size: 512,
    environment_variables: {
      STAGE: "production"
    }
  },
  
  event_store: {
    table_name: "order-events",
    stream_enabled: true,
    encryption_type: "KMS",
    point_in_time_recovery: true
  }
})
```

### Event-Driven Service with CQRS

```ruby
# Create a service with command/query separation
inventory_service = event_driven_microservice(:inventory_service, {
  service_name: "inventory-service",
  
  event_sources: [
    {
      type: "SQS",
      source_ref: inventory_queue_ref,
      batch_size: 25,
      maximum_batching_window: 20
    },
    {
      type: "DynamoDB",
      source_ref: products_table_ref,
      starting_position: "LATEST",
      parallelization_factor: 10
    }
  ],
  
  command_handler: {
    runtime: "nodejs18.x",
    handler: "commands/index.handler",
    timeout: 30,
    memory_size: 1024,
    reserved_concurrent_executions: 100
  },
  
  query_handler: {
    runtime: "nodejs18.x",
    handler: "queries/index.handler",
    timeout: 10,
    memory_size: 512
  },
  
  event_store: {
    table_name: "inventory-events",
    stream_enabled: true,
    ttl_days: 90
  },
  
  cqrs: {
    enabled: true,
    command_table_name: "inventory-commands",
    query_table_name: "inventory-projections",
    projection_enabled: true,
    eventual_consistency_window: 500
  },
  
  monitoring: {
    dashboard_enabled: true,
    alarm_email: "ops@example.com",
    error_rate_threshold: 0.01
  }
})
```

### Payment Service with Saga Orchestration

```ruby
# Create a payment service with saga pattern for distributed transactions
payment_service = event_driven_microservice(:payment_service, {
  service_name: "payment-service",
  
  event_sources: [{
    type: "EventBridge",
    event_pattern: {
      source: ["ecommerce.checkout"],
      "detail-type": ["Payment Required"]
    }
  }],
  
  command_handler: {
    runtime: "python3.9",
    handler: "payment.process_payment",
    timeout: 120,
    memory_size: 1024,
    layers: [payment_sdk_layer_arn],
    environment_variables: {
      PAYMENT_GATEWAY: "stripe",
      WEBHOOK_SECRET: "${STRIPE_WEBHOOK_SECRET}"
    }
  },
  
  event_processor: {
    runtime: "python3.9",
    handler: "payment.process_events",
    timeout: 60,
    memory_size: 512
  },
  
  event_store: {
    table_name: "payment-events",
    stream_enabled: true,
    encryption_type: "KMS",
    kms_key_ref: payment_kms_key_ref,
    global_secondary_indexes: [{
      name: "customer-index",
      hash_key: "customer_id",
      range_key: "timestamp",
      projection_type: "ALL"
    }]
  },
  
  saga: {
    enabled: true,
    state_machine_ref: payment_saga_state_machine_ref,
    compensation_enabled: true,
    timeout_seconds: 600,
    retry_attempts: 3
  },
  
  event_replay: {
    enabled: true,
    snapshot_enabled: true,
    snapshot_frequency: 100,
    replay_dead_letter_queue_ref: replay_dlq_ref
  },
  
  vpc_ref: vpc_ref,
  subnet_refs: [private_subnet_a_ref, private_subnet_b_ref],
  security_group_refs: [lambda_sg_ref]
})
```

### Analytics Service with Multiple Event Sources

```ruby
# Create an analytics service processing events from multiple sources
analytics_service = event_driven_microservice(:analytics_service, {
  service_name: "analytics-service",
  
  event_sources: [
    {
      type: "Kinesis",
      source_ref: clickstream_kinesis_ref,
      starting_position: "TRIM_HORIZON",
      batch_size: 100,
      parallelization_factor: 10,
      maximum_batching_window: 5
    },
    {
      type: "EventBridge",
      event_pattern: {
        source: ["ecommerce.orders", "ecommerce.users"],
        "detail-type": ["Order Completed", "User Registered"]
      }
    },
    {
      type: "SQS",
      source_ref: analytics_queue_ref,
      batch_size: 50,
      on_failure_destination_arn: analytics_dlq_ref.arn
    }
  ],
  
  command_handler: {
    runtime: "python3.9",
    handler: "analytics.aggregate_events",
    timeout: 300,
    memory_size: 3008,
    environment_variables: {
      AGGREGATION_WINDOW: "300",
      OUTPUT_BUCKET: analytics_bucket_ref.id
    }
  },
  
  event_store: {
    table_name: "analytics-events",
    stream_enabled: false,  # No need for streams in analytics
    ttl_days: 30,  # Keep events for 30 days
    encryption_type: "DEFAULT"
  },
  
  dead_letter_queue_enabled: true,
  dead_letter_max_receive_count: 5,
  
  api_gateway_enabled: true,
  api_gateway_ref: analytics_api_ref,
  
  monitoring: {
    dashboard_enabled: true,
    event_processing_threshold: 5000,  # 5 seconds
    error_rate_threshold: 0.05,  # 5% error rate
    dead_letter_threshold: 100
  }
})
```

## Inputs

### Required Inputs

- `service_name`: Name of the microservice
- `event_sources`: Array of event source configurations
- `command_handler`: Lambda function configuration for command processing
- `event_store`: DynamoDB table configuration for event storage

### Event Source Configuration

```ruby
{
  type: "EventBridge",  # EventBridge, SQS, SNS, Kinesis, DynamoDB
  source_arn: "arn:aws:...",  # Direct ARN
  source_ref: resource_ref,    # Or resource reference
  event_pattern: {},           # For EventBridge
  batch_size: 10,
  starting_position: "LATEST", # For streams
  maximum_retry_attempts: 3
}
```

### Optional Inputs

- `service_description`: Description of the service
- `query_handler`: Lambda configuration for query operations (CQRS)
- `event_processor`: Lambda configuration for event processing
- `cqrs`: CQRS pattern configuration
- `saga`: Saga orchestration configuration
- `event_replay`: Event replay configuration
- `vpc_ref`: VPC for Lambda functions
- `subnet_refs`: Subnets for Lambda functions
- `security_group_refs`: Security groups for Lambda
- `dead_letter_queue_enabled`: Enable DLQ (default: true)
- `api_gateway_enabled`: Enable API Gateway integration
- `monitoring`: Monitoring configuration

## Outputs

The component returns a `ComponentReference` with:

- `service_name`: Name of the microservice
- `command_handler_arn`: ARN of command handler Lambda
- `query_handler_arn`: ARN of query handler Lambda (if enabled)
- `event_processor_arn`: ARN of event processor Lambda (if enabled)
- `event_store_name`: Name of the event store table
- `event_store_stream_arn`: ARN of DynamoDB stream
- `event_sources`: List of configured event sources
- `patterns_enabled`: List of enabled patterns (Event Sourcing, CQRS, etc.)
- `monitoring_features`: List of monitoring features
- `estimated_monthly_cost`: Estimated AWS costs

## Resources Created

- `aws_lambda_function`: Command handler, query handler, event processor
- `aws_iam_role`: Lambda execution role
- `aws_iam_role_policy`: Permissions for Lambda functions
- `aws_dynamodb_table`: Event store and CQRS tables
- `aws_sqs_queue`: Dead letter queue (optional)
- `aws_eventbridge_rule`: EventBridge rules for event sources
- `aws_lambda_event_source_mapping`: Mappings for SQS, Kinesis, DynamoDB
- `aws_cloudwatch_dashboard`: Monitoring dashboard (optional)
- `aws_cloudwatch_metric_alarm`: Performance and error alarms
- `aws_sns_topic`: Alarm notifications (optional)

## Best Practices

1. **Event Design**
   - Use meaningful event names and types
   - Include correlation IDs for tracing
   - Keep events immutable
   - Version events for backward compatibility

2. **CQRS Implementation**
   - Separate read and write models completely
   - Use projections for complex queries
   - Handle eventual consistency gracefully
   - Implement idempotent command handlers

3. **Error Handling**
   - Configure appropriate retry policies
   - Use dead letter queues for failed events
   - Implement compensating transactions in sagas
   - Monitor error rates and set alerts

4. **Performance**
   - Batch events when possible
   - Use parallelization for stream processing
   - Configure appropriate Lambda memory
   - Enable Lambda reserved concurrency for critical services

5. **Security**
   - Encrypt event stores with KMS
   - Use VPC endpoints for private communication
   - Implement least-privilege IAM policies
   - Audit event access and modifications