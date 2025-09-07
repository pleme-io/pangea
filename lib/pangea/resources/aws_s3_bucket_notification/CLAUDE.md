# AWS S3 Bucket Notification Configuration - Implementation Details

## Resource Overview

The `aws_s3_bucket_notification` resource enables comprehensive event-driven architecture patterns by configuring S3 bucket notifications to multiple AWS services simultaneously. This resource is essential for building reactive systems that respond to S3 object lifecycle events.

## Architecture Patterns

### Event-Driven Data Processing

This resource enables sophisticated data processing pipelines where different services handle different aspects of object processing:

```ruby
aws_s3_bucket_notification(:data_processing_hub, {
  bucket: "data-lake-raw",
  lambda_function: [{
    id: "metadata-extractor",
    lambda_function_arn: lambda_metadata_extractor.outputs[:arn],
    events: ["s3:ObjectCreated:Put"],
    filter_prefix: "incoming/",
    filter_suffix: ".json"
  }],
  queue: [{
    id: "batch-processor",
    queue_arn: sqs_batch_queue.outputs[:arn],
    events: ["s3:ObjectCreated:Put"],
    filter_prefix: "processed/"
  }],
  cloudwatch_configuration: [{
    id: "monitoring",
    topic_arn: sns_monitoring_topic.outputs[:arn],
    events: ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }],
  eventbridge: true
})
```

### Multi-Tenant Notification Routing

For multi-tenant applications, this resource can route events based on object prefixes:

```ruby
aws_s3_bucket_notification(:tenant_routing, {
  bucket: "multi-tenant-storage",
  lambda_function: [
    {
      id: "tenant-a-processor",
      lambda_function_arn: lambda_tenant_a.outputs[:arn],
      events: ["s3:ObjectCreated:*"],
      filter_prefix: "tenant-a/"
    },
    {
      id: "tenant-b-processor", 
      lambda_function_arn: lambda_tenant_b.outputs[:arn],
      events: ["s3:ObjectCreated:*"],
      filter_prefix: "tenant-b/"
    }
  ],
  # Global audit trail
  queue: [{
    id: "audit-trail",
    queue_arn: sqs_audit_queue.outputs[:arn],
    events: ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }]
})
```

## Integration Patterns

### Lambda Function Integration

When integrating with Lambda functions, ensure proper permissions are configured:

```ruby
# Lambda function
image_processor = aws_lambda_function(:image_processor, {
  function_name: "image-processor",
  runtime: "python3.9",
  handler: "app.handler",
  filename: "image_processor.zip",
  timeout: 300
})

# Lambda permission for S3 invocation
aws_lambda_permission(:s3_invoke_image_processor, {
  statement_id: "AllowS3Invocation",
  action: "lambda:InvokeFunction", 
  function_name: image_processor.outputs[:function_name],
  principal: "s3.amazonaws.com",
  source_arn: "${aws_s3_bucket.media_bucket.arn}/*"
})

# S3 notification configuration
aws_s3_bucket_notification(:image_processing_notifications, {
  bucket: media_bucket.outputs[:id],
  lambda_function: [{
    lambda_function_arn: image_processor.outputs[:arn],
    events: ["s3:ObjectCreated:Put", "s3:ObjectCreated:Post"],
    filter_prefix: "images/",
    filter_suffix: ".jpg"
  }]
})
```

### SQS Queue Integration

For reliable, scalable processing with SQS:

```ruby
# Dead letter queue for failed processing
dlq = aws_sqs_queue(:processing_dlq, {
  name: "s3-processing-dlq",
  message_retention_seconds: 1209600 # 14 days
})

# Main processing queue with DLQ
processing_queue = aws_sqs_queue(:processing_queue, {
  name: "s3-processing-queue",
  visibility_timeout_seconds: 300,
  redrive_policy: {
    dead_letter_target_arn: dlq.outputs[:arn],
    max_receive_count: 3
  }
})

# SQS queue policy allowing S3 to send messages
aws_sqs_queue_policy(:s3_send_policy, {
  queue_url: processing_queue.outputs[:id],
  policy: {
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Principal: { Service: "s3.amazonaws.com" },
      Action: "sqs:SendMessage",
      Resource: processing_queue.outputs[:arn],
      Condition: {
        ArnEquals: {
          "aws:SourceArn": "${aws_s3_bucket.data_bucket.arn}"
        }
      }
    }]
  }.to_json
})

# S3 notification to SQS
aws_s3_bucket_notification(:sqs_notifications, {
  bucket: data_bucket.outputs[:id],
  queue: [{
    queue_arn: processing_queue.outputs[:arn],
    events: ["s3:ObjectCreated:*"],
    filter_prefix: "data/"
  }]
})
```

### EventBridge Integration

EventBridge enables advanced event filtering and routing:

```ruby
# Enable EventBridge on the bucket
aws_s3_bucket_notification(:eventbridge_notifications, {
  bucket: "my-event-driven-bucket",
  eventbridge: true
})

# EventBridge rule for specific object patterns
aws_cloudwatch_event_rule(:image_uploaded_rule, {
  name: "s3-image-uploaded",
  event_pattern: {
    source: ["aws.s3"],
    detail_type: ["Object Created"],
    detail: {
      bucket: { name: ["my-event-driven-bucket"] },
      object: { 
        key: [{ prefix: "images/" }],
        size: [{ numeric: [">", 1024] }] # Objects larger than 1KB
      }
    }
  }.to_json
})

# EventBridge target - Lambda function
aws_cloudwatch_event_target(:image_processor_target, {
  rule: image_uploaded_rule.outputs[:name],
  arn: image_processor.outputs[:arn],
  target_id: "ImageProcessorTarget"
})
```

## Advanced Use Cases

### Compliance and Audit Logging

```ruby
aws_s3_bucket_notification(:compliance_notifications, {
  bucket: "compliance-documents",
  cloudwatch_configuration: [{
    id: "compliance-audit",
    topic_arn: sns_compliance_topic.outputs[:arn],
    events: [
      "s3:ObjectCreated:*",
      "s3:ObjectRemoved:Delete",
      "s3:ObjectRemoved:DeleteMarkerCreated"
    ]
  }],
  lambda_function: [{
    id: "document-classifier",
    lambda_function_arn: lambda_document_classifier.outputs[:arn],
    events: ["s3:ObjectCreated:*"],
    filter_prefix: "incoming/"
  }],
  # Enable EventBridge for advanced compliance routing
  eventbridge: true
})
```

### Cross-Region Replication Monitoring

```ruby
aws_s3_bucket_notification(:replication_monitoring, {
  bucket: "primary-data-bucket",
  cloudwatch_configuration: [{
    id: "replication-alerts",
    topic_arn: sns_ops_alerts.outputs[:arn],
    events: [
      "s3:Replication:OperationFailedReplication",
      "s3:Replication:OperationMissedThreshold"
    ]
  }],
  lambda_function: [{
    id: "replication-metrics",
    lambda_function_arn: lambda_replication_metrics.outputs[:arn],
    events: ["s3:Replication:*"]
  }]
})
```

## Performance Considerations

### Event Volume Management

For high-frequency buckets, consider:

1. **Specific Event Types**: Use specific events instead of wildcards
2. **Prefix Filtering**: Narrow down notifications with prefixes
3. **Batch Processing**: Use SQS for batching events to Lambda
4. **Rate Limiting**: Implement backpressure mechanisms

```ruby
# High-frequency bucket with optimized notifications
aws_s3_bucket_notification(:high_frequency_notifications, {
  bucket: "high-frequency-uploads",
  # Use SQS for batching instead of direct Lambda invocation
  queue: [{
    queue_arn: batch_processing_queue.outputs[:arn],
    events: ["s3:ObjectCreated:Put"], # Specific event only
    filter_prefix: "processed/" # Only for processed objects
  }],
  # Critical alerts only
  cloudwatch_configuration: [{
    topic_arn: critical_alerts_topic.outputs[:arn],
    events: ["s3:ObjectRemoved:Delete"] # Only deletions
  }]
})
```

## Cost Optimization

### Notification Cost Management

```ruby
# Cost-optimized notification strategy
aws_s3_bucket_notification(:cost_optimized_notifications, {
  bucket: "cost-sensitive-bucket",
  # Use EventBridge for complex routing (single notification stream)
  eventbridge: true,
  # Direct Lambda only for critical real-time processing
  lambda_function: [{
    lambda_function_arn: critical_processor.outputs[:arn],
    events: ["s3:ObjectCreated:Put"],
    filter_prefix: "critical/",
    filter_suffix: ".urgent"
  }]
  # Avoid multiple SNS/SQS notifications for same events
})
```

## Security Considerations

### Principle of Least Privilege

Ensure notification targets have minimal required permissions:

```ruby
# Lambda execution role with minimal S3 permissions
lambda_execution_role = aws_iam_role(:s3_processor_role, {
  name: "s3-processor-execution-role",
  assume_role_policy: {
    Version: "2012-10-17",
    Statement: [{
      Action: "sts:AssumeRole",
      Effect: "Allow",
      Principal: { Service: "lambda.amazonaws.com" }
    }]
  }.to_json
})

# Policy allowing only necessary S3 actions
aws_iam_role_policy_attachment(:s3_processor_policy, {
  role: lambda_execution_role.outputs[:name],
  policy_arn: "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
})

aws_iam_policy(:s3_read_policy, {
  name: "s3-processor-read-policy",
  policy: {
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Action: ["s3:GetObject"],
      Resource: "arn:aws:s3:::my-bucket/*"
    }]
  }.to_json
})
```

## Monitoring and Debugging

### CloudWatch Metrics Integration

The resource automatically provides metrics through computed properties:

```ruby
notification_config = aws_s3_bucket_notification(:monitored_notifications, {
  bucket: "monitored-bucket",
  lambda_function: [{ /* config */ }],
  queue: [{ /* config */ }]
})

# Create CloudWatch dashboard using computed properties
aws_cloudwatch_dashboard(:s3_notification_dashboard, {
  dashboard_name: "S3NotificationMetrics",
  dashboard_body: {
    widgets: [{
      type: "metric",
      properties: {
        metrics: [
          ["AWS/S3", "NumberOfObjects", "BucketName", "monitored-bucket"]
        ],
        title: "S3 Object Count - #{notification_config.computed[:total_notification_destinations]} destinations configured"
      }
    }]
  }.to_json
})
```

This resource is fundamental for building event-driven architectures with S3 as the central event source, providing type safety, comprehensive validation, and extensive integration capabilities.