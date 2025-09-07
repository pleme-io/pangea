# AWS SQS Queue Implementation

## Overview

The `aws_sqs_queue` resource provides a type-safe implementation for AWS Simple Queue Service (SQS) queues, supporting both Standard and FIFO queue types with comprehensive configuration options for message processing, encryption, and fault tolerance.

## Implementation Details

### Type System (types.rb)

The `SQSQueueAttributes` class uses dry-struct for runtime validation with the following key validations:

1. **Queue Naming Validation**:
   - FIFO queues must end with `.fifo` suffix
   - Standard queues cannot end with `.fifo` suffix
   - Enforced through custom validation in `self.new`

2. **Constraint Validations**:
   - `visibility_timeout_seconds`: 0-43200 (12 hours)
   - `message_retention_seconds`: 60-1209600 (14 days)
   - `max_message_size`: 1024-262144 bytes (256KB)
   - `delay_seconds`: 0-900 (15 minutes)
   - `receive_wait_time_seconds`: 0-20 (long polling)
   - `kms_data_key_reuse_period_seconds`: 60-86400 (1 day)

3. **FIFO-Specific Validations**:
   - `content_based_deduplication` only valid for FIFO queues
   - `deduplication_scope` only valid for FIFO queues
   - `fifo_throughput_limit` only valid for FIFO queues

4. **Policy Validations**:
   - `redrive_allow_policy` requires `sourceQueueArns` when `redrivePermission` is "byQueue"
   - Cannot enable both KMS and SQS-managed encryption simultaneously

### Resource Function (resource.rb)

The `aws_sqs_queue` function:

1. **Validates Input**: Uses `SQSQueueAttributes` for type safety
2. **Generates Terraform**: Creates `aws_sqs_queue` resource block
3. **Handles JSON Policies**: Converts Ruby hashes to JSON for policies
4. **Returns Reference**: Provides typed reference with outputs

Key implementation details:
- Conditionally adds FIFO-specific attributes only for FIFO queues
- Serializes `redrive_policy` and `redrive_allow_policy` to JSON
- Handles mutually exclusive encryption options
- Provides computed properties for queue analysis

### Helper Methods

The type class provides several helper methods:
- `is_fifo?` - Check if FIFO queue
- `is_encrypted?` - Check if any encryption is enabled
- `has_dlq?` - Check if dead letter queue is configured
- `long_polling_enabled?` - Check if long polling is active
- `is_delay_queue?` - Check if delay is configured
- `allows_all_sources?` - Check DLQ source permissions
- `queue_type` - Return "Standard" or "FIFO"
- `encryption_type` - Return "KMS", "SQS-SSE", or "None"

## Design Decisions

### 1. Queue Name Validation
We enforce the `.fifo` suffix convention at the type level rather than auto-appending it. This makes the queue type explicit and prevents confusion.

### 2. JSON Policy Handling
Policies are serialized to JSON within the resource function rather than expecting pre-serialized strings. This allows for better validation and type safety.

### 3. Encryption Options
KMS and SQS-managed encryption are mutually exclusive by AWS design. We validate this at the type level to catch configuration errors early.

### 4. Default Values
Conservative defaults are chosen:
- 30 seconds visibility timeout (enough for simple tasks)
- 4 days message retention (balanced between storage and recovery)
- Long polling disabled by default (opt-in for optimization)

### 5. Computed Properties
Rich computed properties enable infrastructure analysis and conditional logic in templates without manual computation.

## Testing Considerations

When testing SQS queue configurations:

1. **Queue Type Tests**:
   ```ruby
   # Standard queue
   expect { aws_sqs_queue(:test, { name: "test.fifo", fifo_queue: false }) }
     .to raise_error(Dry::Struct::Error)
   
   # FIFO queue
   expect { aws_sqs_queue(:test, { name: "test", fifo_queue: true }) }
     .to raise_error(Dry::Struct::Error)
   ```

2. **Encryption Tests**:
   ```ruby
   # Mutual exclusion
   expect { 
     aws_sqs_queue(:test, { 
       name: "test",
       kms_master_key_id: "key",
       sqs_managed_sse_enabled: true 
     }) 
   }.to raise_error(Dry::Struct::Error)
   ```

3. **DLQ Configuration Tests**:
   ```ruby
   # Valid DLQ setup
   dlq = aws_sqs_queue(:dlq, { name: "dlq" })
   main = aws_sqs_queue(:main, {
     name: "main",
     redrive_policy: {
       deadLetterTargetArn: dlq.arn,
       maxReceiveCount: 3
     }
   })
   ```

## Integration Patterns

### With Lambda Functions
```ruby
queue = aws_sqs_queue(:events, { name: "events" })

aws_lambda_event_source_mapping(:queue_processor, {
  event_source_arn: queue.arn,
  function_name: lambda_function.name
})
```

### With SNS Topics
```ruby
topic = aws_sns_topic(:alerts, { name: "alerts" })
queue = aws_sqs_queue(:alert_queue, { name: "alert-queue" })

aws_sns_subscription(:queue_sub, {
  topic_arn: topic.arn,
  protocol: "sqs",
  endpoint: queue.arn
})
```

### With IAM Policies
```ruby
queue = aws_sqs_queue(:app_queue, { name: "app-queue" })

policy_document = {
  Version: "2012-10-17",
  Statement: [{
    Effect: "Allow",
    Action: ["sqs:SendMessage", "sqs:ReceiveMessage"],
    Resource: queue.arn
  }]
}
```

## Performance Considerations

1. **Long Polling**: Enable `receive_wait_time_seconds` to reduce API calls and costs
2. **Batch Operations**: Design consumers to use batch receive/delete operations
3. **Message Size**: Keep messages small; use S3 for large payloads
4. **FIFO Throughput**: Use `perQueue` limit for higher throughput when ordering isn't critical per message group

## Security Best Practices

1. **Always Enable Encryption**: Use KMS for sensitive data, SQS-SSE for general use
2. **Implement DLQ**: Prevent message loss and enable debugging
3. **Use Least Privilege**: Queue policies should grant minimal required permissions
4. **Separate DLQ Access**: Use `redrive_allow_policy` to restrict DLQ access
5. **Tag Resources**: Enable cost tracking and compliance scanning

## Monitoring Integration

The resource outputs enable CloudWatch alarm creation:
```ruby
queue = aws_sqs_queue(:critical, { name: "critical-queue" })

aws_cloudwatch_metric_alarm(:queue_depth, {
  alarm_name: "#{queue.name}-depth",
  metric_name: "ApproximateNumberOfMessagesVisible",
  namespace: "AWS/SQS",
  dimensions: {
    QueueName: queue.name
  },
  threshold: 1000
})
```