# AWS Lambda Event Source Mapping Resource Implementation

## Overview

The `aws_lambda_event_source_mapping` resource implements a type-safe wrapper around Terraform's AWS Lambda event source mapping resource, enabling Lambda functions to process events from streams (Kinesis, DynamoDB) and queues (SQS, Kafka, RabbitMQ).

## Implementation Details

### Type System (types.rb)

The `LambdaEventSourceMappingAttributes` class enforces:

1. **Source type detection**: Automatically identifies event source type from ARN
2. **Batch size validation**: Source-specific limits (1-10000 for most sources)
3. **Starting position requirements**: Required for streams, invalid for queues
4. **Feature availability**: Validates features based on source type
5. **Configuration consistency**: Ensures options match the event source

### Resource Synthesis (resource.rb)

The resource function:
1. Validates inputs using dry-struct with source-specific rules
2. Conditionally generates configuration based on source type
3. Handles complex nested configurations (filters, destinations)
4. Returns ResourceReference with source-specific computed properties

### Key Features

#### Event Source Types
- **Streams**: Kinesis, DynamoDB - ordered event processing
- **Queues**: SQS, RabbitMQ - message queue processing
- **Kafka**: MSK, self-managed - topic-based streaming

#### Processing Features
- **Batching**: Configurable batch sizes and windows
- **Parallelization**: Concurrent processing for Kinesis
- **Error Handling**: Retry, bisect, and dead letter configurations
- **Filtering**: Event pattern matching to reduce processing

## Validation Rules

### Source Type Detection

```ruby
# Kinesis stream
event_source_arn: "arn:aws:kinesis:us-east-1:123456789012:stream/my-stream"

# DynamoDB stream  
event_source_arn: "arn:aws:dynamodb:us-east-1:123456789012:table/Users/stream/..."

# SQS queue
event_source_arn: "arn:aws:sqs:us-east-1:123456789012:my-queue"

# MSK cluster
event_source_arn: "arn:aws:kafka:us-east-1:123456789012:cluster/my-cluster/..."

# Amazon MQ (RabbitMQ)
event_source_arn: "arn:aws:mq:us-east-1:123456789012:broker:my-broker:..."
```

### Batch Size Limits by Source

| Source Type | Min | Max | Default |
|-------------|-----|-----|---------|
| Kinesis | 1 | 10,000 | 100 |
| DynamoDB | 1 | 10,000 | 100 |
| SQS | 1 | 10,000 | 10 |
| MSK | 1 | 10,000 | 100 |
| RabbitMQ | 1 | 10,000 | 100 |

### Feature Availability Matrix

| Feature | Kinesis | DynamoDB | SQS | Kafka | RabbitMQ |
|---------|---------|----------|-----|-------|----------|
| Starting Position | ✓ | ✓ | ✗ | ✓ | ✗ |
| Parallelization | ✓ | ✗ | ✗ | ✗ | ✗ |
| Tumbling Window | ✓ | ✓ | ✗ | ✗ | ✗ |
| Batching Window | ✓ | ✓ | ✓ | ✓ | ✓ |
| Error Destinations | ✓ | ✓ | ✓ | ✗ | ✗ |
| Filter Criteria | ✓ | ✓ | ✓ | ✓ | ✓ |
| Scaling Config | ✓ | ✓ | ✓ | ✓ | ✓ |

## Common Patterns

### Stream Processing Pattern
```ruby
aws_lambda_event_source_mapping(:stream_trigger, {
  event_source_arn: kinesis_stream.arn,
  function_name: processor.function_name,
  starting_position: "LATEST",
  batch_size: 100,
  parallelization_factor: 10,
  maximum_retry_attempts: 3,
  destination_config: {
    on_failure: { destination: dlq.arn }
  }
})
```

### Queue Processing Pattern
```ruby
aws_lambda_event_source_mapping(:queue_trigger, {
  event_source_arn: sqs_queue.arn,
  function_name: handler.function_name,
  batch_size: 25,
  maximum_batching_window_in_seconds: 20,
  scaling_config: {
    maximum_concurrency: 100
  }
})
```

### Filtered Events Pattern
```ruby
aws_lambda_event_source_mapping(:filtered_trigger, {
  event_source_arn: dynamodb_table.stream_arn,
  function_name: processor.function_name,
  starting_position: "TRIM_HORIZON",
  filter_criteria: {
    filters: [{
      pattern: JSON.generate({
        eventName: ["INSERT", "MODIFY"],
        dynamodb: {
          NewImage: {
            status: { S: ["active"] }
          }
        }
      })
    }]
  }
})
```

### Kafka Integration Pattern
```ruby
aws_lambda_event_source_mapping(:kafka_trigger, {
  event_source_arn: msk_cluster.arn,
  function_name: kafka_processor.function_name,
  topics: ["orders", "payments"],
  starting_position: "LATEST",
  amazon_managed_kafka_event_source_config: {
    consumer_group_id: "lambda-consumers"
  },
  source_access_configuration: [
    { type: "VPC_SUBNET", uri: subnet_a.id },
    { type: "VPC_SUBNET", uri: subnet_b.id },
    { type: "VPC_SECURITY_GROUP", uri: kafka_sg.id }
  ]
})
```

## Error Handling Strategies

### Retry Configuration
```ruby
# Basic retry
maximum_retry_attempts: 3

# With age limit
maximum_record_age_in_seconds: 3600  # 1 hour

# Bisect on error (splits batch)
bisect_batch_on_function_error: true
```

### Dead Letter Configuration
```ruby
destination_config: {
  on_failure: {
    destination: "arn:aws:sqs:us-east-1:123456789012:dlq"
  }
}
```

## Performance Optimization

### Batch Processing
- Larger batches = fewer Lambda invocations
- Balance between latency and efficiency
- Use batching window for aggregation

### Parallelization (Kinesis)
```ruby
parallelization_factor: 10  # Process 10 batches concurrently
```

### Scaling Configuration
```ruby
scaling_config: {
  maximum_concurrency: 500  # Limit concurrent executions
}
```

## Filter Criteria Examples

### DynamoDB Filter
```ruby
filter_criteria: {
  filters: [{
    pattern: JSON.generate({
      eventName: ["INSERT"],
      dynamodb: {
        NewImage: {
          type: { S: ["ORDER"] },
          amount: { N: [{ numeric: [">", 100] }] }
        }
      }
    })
  }]
}
```

### Kinesis Filter
```ruby
filter_criteria: {
  filters: [{
    pattern: JSON.generate({
      data: {
        eventType: ["user.created", "user.updated"],
        attributes: {
          country: ["US", "CA"]
        }
      }
    })
  }]
}
```

### SQS Filter
```ruby
filter_criteria: {
  filters: [{
    pattern: JSON.generate({
      body: {
        MessageType: ["Order"],
        Priority: ["High"]
      }
    })
  }]
}
```

## Source Access Configuration

### VPC Configuration (Kafka)
```ruby
source_access_configuration: [
  { type: "VPC_SUBNET", uri: "subnet-12345" },
  { type: "VPC_SECURITY_GROUP", uri: "sg-67890" }
]
```

### Authentication (Self-Managed)
```ruby
source_access_configuration: [
  { type: "BASIC_AUTH", uri: secret_arn },
  { type: "SASL_SCRAM_512_AUTH", uri: secret_arn }
]
```

## Troubleshooting

### Common Issues

1. **Function Not Triggering**
   - Check IAM permissions
   - Verify event source state
   - Review filter criteria

2. **High Error Rate**
   - Check batch size
   - Review timeout settings
   - Enable bisect on error

3. **Processing Lag**
   - Increase parallelization
   - Optimize batch size
   - Scale Lambda concurrency

### Monitoring Metrics
- Iterator age (stream lag)
- Error count and success rate
- Concurrent executions
- Duration and throttles

## Migration Guide

### From Manual Polling
```ruby
# Before: Lambda polling SQS manually
aws_lambda_function(:poller, {
  handler: "poll_sqs.handler",
  # Runs on schedule to poll SQS
})

# After: Event source mapping
aws_lambda_event_source_mapping(:sqs_trigger, {
  event_source_arn: queue.arn,
  function_name: processor.function_name,
  batch_size: 25
})
```

### Adding Error Handling
```ruby
# Add comprehensive error handling
aws_lambda_event_source_mapping(:enhanced_trigger, {
  # ... existing config ...
  maximum_retry_attempts: 3,
  maximum_record_age_in_seconds: 7200,
  bisect_batch_on_function_error: true,
  destination_config: {
    on_failure: { destination: dlq.arn }
  }
})
```