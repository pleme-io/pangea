# AWS CloudWatch Event Target - Architecture Documentation

## Core Concepts

### Event Target Design Philosophy

CloudWatch Event Targets complete the event-driven architecture by defining where and how events are delivered. This resource implements:

1. **Multi-Service Integration**: Route events to 15+ AWS services
2. **Event Transformation**: Modify event structure before delivery
3. **Resilient Delivery**: Retry policies and dead letter queues
4. **Service-Specific Optimization**: Tailored configurations per target type

### Implementation Architecture

```
CloudWatch Event Target
├── Target Resolution
│   ├── Service Detection
│   ├── ARN Validation
│   └── Permission Requirements
├── Event Processing
│   ├── Input Selection
│   ├── Path Extraction
│   ├── Template Application
│   └── JSON Construction
├── Delivery Configuration
│   ├── Retry Logic
│   ├── Error Handling
│   ├── Dead Letter Queue
│   └── Timeout Management
└── Service Integration
    ├── Lambda Invocation
    ├── SNS Publishing
    ├── SQS Messaging
    ├── Kinesis Streaming
    └── ECS/Batch/StepFunctions
```

## Type Safety Implementation

### Validation Layers

1. **ARN Validation**
   - Service-specific ARN patterns
   - Cross-service compatibility
   - Resource existence verification

2. **Input Configuration**
   - Mutual exclusivity enforcement
   - JSONPath validation
   - Template syntax checking

3. **Service Configuration**
   - Required field validation
   - Service-specific constraints
   - Network configuration validation

### Type Definitions

```ruby
# Nested type structures for complex configurations
class InputTransformer < Dry::Struct
  attribute :input_paths_map, Resources::Types::Hash
  attribute :input_template, Resources::Types::String
end

class RetryPolicy < Dry::Struct
  attribute :maximum_event_age_in_seconds, Resources::Types::Integer.optional
  attribute :maximum_retry_attempts, Resources::Types::Integer.optional
end

# Service detection from ARN
def target_service
  case arn
  when /^arn:aws[a-z\-]*:lambda:/ then :lambda
  when /^arn:aws[a-z\-]*:states:/ then :step_functions
  when /^arn:aws[a-z\-]*:ecs:/ then :ecs
  # ... more services
  end
end
```

## Advanced Patterns

### 1. Event Enrichment Pipeline

Transform and enrich events before delivery:

```ruby
# Multi-stage enrichment
enrichment_rule = aws_cloudwatch_event_rule(:enrichment_trigger, {
  name: "event-enrichment",
  event_pattern: jsonencode({
    source: ["myapp.events"],
    "detail-type": ["Customer Action"]
  })
})

# Stage 1: Add customer data
customer_enricher = aws_cloudwatch_event_target(:enrich_customer, {
  rule: enrichment_rule.name,
  target_id: "customer-enrichment",
  arn: customer_enrichment_lambda.arn,
  input_transformer: {
    input_paths_map: {
      customer_id: "$.detail.customerId",
      action: "$.detail.action",
      timestamp: "$.time"
    },
    input_template: jsonencode({
      customerId: "<customer_id>",
      action: "<action>",
      eventTime: "<timestamp>",
      enrichmentStage: "customer"
    })
  }
})

# Stage 2: Add product data (chained from Stage 1)
product_enricher = aws_cloudwatch_event_target(:enrich_product, {
  rule: product_enrichment_rule.name,
  target_id: "product-enrichment",
  arn: product_enrichment_lambda.arn,
  input_transformer: {
    input_paths_map: {
      customer_data: "$.detail.customerData",
      product_id: "$.detail.productId",
      action: "$.detail.action"
    },
    input_template: jsonencode({
      customer: JSON.parse("<customer_data>"),
      productId: "<product_id>",
      action: "<action>",
      enrichmentStage: "product"
    })
  }
})

# Stage 3: Final processing with all enriched data
final_processor = aws_cloudwatch_event_target(:final_processing, {
  rule: final_processing_rule.name,
  target_id: "final-processor",
  arn: analytics_stream.arn,
  role_arn: kinesis_role.arn,
  kinesis_target: {
    partition_key_path: "$.detail.customerId"
  },
  retry_policy: {
    maximum_retry_attempts: 3,
    maximum_event_age_in_seconds: 7200  # 2 hours
  }
})
```

### 2. Conditional Target Routing

Route to different targets based on event content:

```ruby
# High-priority processing
high_priority_target = aws_cloudwatch_event_target(:high_priority, {
  rule: order_rule.name,
  target_id: "high-priority-processor",
  arn: express_processor.arn,
  input_transformer: {
    input_paths_map: {
      order: "$.detail",
      account: "$.account"
    },
    input_template: jsonencode({
      order: JSON.parse("<order>"),
      priority: "EXPRESS",
      account: "<account>",
      sla: "1hour"
    })
  }
})

# Batch processing for normal orders
batch_target = aws_cloudwatch_event_target(:batch_processor, {
  rule: order_rule.name,
  target_id: "batch-processor",
  arn: batch_queue.arn,
  role_arn: batch_role.arn,
  batch_target: {
    job_definition: "order-processing-batch",
    job_name: "order-batch-${timestamp}",
    array_size: 100,
    job_attempts: 2
  },
  input_transformer: {
    input_paths_map: {
      orders: "$.detail.orders",
      batch_id: "$.id"
    },
    input_template: jsonencode({
      batchId: "<batch_id>",
      orders: JSON.parse("<orders>"),
      priority: "STANDARD"
    })
  }
})

# Archive all orders
archive_target = aws_cloudwatch_event_target(:archiver, {
  rule: order_rule.name,
  target_id: "order-archive",
  arn: archive_firehose.arn,
  role_arn: firehose_role.arn
})
```

### 3. Resilient Event Processing

Implement fault-tolerant event processing:

```ruby
# Primary processor with aggressive retry
primary_target = aws_cloudwatch_event_target(:primary, {
  rule: critical_rule.name,
  target_id: "primary-processor",
  arn: primary_processor.arn,
  retry_policy: {
    maximum_retry_attempts: 5,
    maximum_event_age_in_seconds: 3600  # 1 hour
  },
  dead_letter_config: {
    arn: primary_dlq.arn
  }
})

# Backup processor for DLQ events
dlq_processor = aws_cloudwatch_event_target(:dlq_handler, {
  rule: dlq_rule.name,
  arn: backup_processor.arn,
  input_transformer: {
    input_paths_map: {
      original_event: "$.detail.event",
      error_details: "$.detail.errorMessage",
      retry_count: "$.detail.retryCount"
    },
    input_template: jsonencode({
      event: JSON.parse("<original_event>"),
      processingMetadata: {
        error: "<error_details>",
        retries: "<retry_count>",
        fallbackProcessor: true
      }
    })
  }
})

# Circuit breaker pattern
circuit_breaker = aws_cloudwatch_event_target(:circuit_breaker, {
  rule: monitoring_rule.name,
  arn: circuit_breaker_lambda.arn,
  input_transformer: {
    input_paths_map: {
      failure_rate: "$.detail.metrics.failureRate",
      service: "$.detail.service"
    },
    input_template: jsonencode({
      action: "EVALUATE_CIRCUIT",
      service: "<service>",
      currentFailureRate: parseFloat("<failure_rate>"),
      threshold: 0.5
    })
  }
})
```

### 4. Complex ECS Task Orchestration

Advanced ECS task configurations:

```ruby
# Blue-green deployment trigger
blue_green_target = aws_cloudwatch_event_target(:blue_green_deploy, {
  rule: deployment_rule.name,
  arn: ecs_cluster.arn,
  role_arn: ecs_deploy_role.arn,
  ecs_target: {
    task_definition_arn: "${data.aws_ssm_parameter.current_task_def.value}",
    task_count: 3,
    launch_type: "FARGATE",
    platform_version: "1.4.0",
    group: "deployment:blue-green",
    
    network_configuration: {
      awsvpc_configuration: {
        subnets: data.aws_subnets.private.ids,
        security_groups: [
          app_security_group.id,
          deployment_security_group.id
        ],
        assign_public_ip: "DISABLED"
      }
    },
    
    placement_constraints: [
      {
        type: "memberOf",
        expression: "attribute:deployment.stage == blue"
      }
    ],
    
    placement_strategy: [
      {
        type: "spread",
        field: "attribute:ecs.availability-zone"
      },
      {
        type: "binpack",
        field: "memory"
      }
    ],
    
    capacity_provider_strategy: [
      {
        capacity_provider: "FARGATE_SPOT",
        weight: 2,
        base: 0
      },
      {
        capacity_provider: "FARGATE",
        weight: 1,
        base: 1
      }
    ],
    
    tags: {
      Deployment: "blue-green",
      Version: "${var.app_version}",
      Environment: "${var.environment}"
    }
  }
})
```

## Input Transformation Deep Dive

### Advanced JSONPath Expressions

```ruby
# Complex path extraction
complex_paths = aws_cloudwatch_event_target(:complex_extraction, {
  rule: event_rule.name,
  arn: processor.arn,
  input_transformer: {
    input_paths_map: {
      # Array element access
      first_item: "$.detail.items[0]",
      
      # Nested object navigation
      customer_email: "$.detail.customer.contact.email",
      
      # Multiple array levels
      first_tag: "$.detail.resources[0].tags[0]",
      
      # Entire arrays/objects
      all_items: "$.detail.items",
      metadata: "$.detail.metadata",
      
      # Special characters handling
      special_field: "$.detail['field-with-dash']",
      
      # Root level fields
      account: "$.account",
      region: "$.region",
      time: "$.time"
    },
    input_template: jsonencode({
      processedEvent: {
        primaryItem: JSON.parse("<first_item>"),
        customerEmail: "<customer_email>",
        items: JSON.parse("<all_items>"),
        eventMetadata: {
          account: "<account>",
          region: "<region>",
          timestamp: "<time>",
          customData: JSON.parse("<metadata>")
        }
      }
    })
  }
})
```

### Dynamic Template Construction

```ruby
# Conditional content in templates
conditional_transform = aws_cloudwatch_event_target(:conditional, {
  rule: event_rule.name,
  arn: processor.arn,
  input_transformer: {
    input_paths_map: {
      event_type: "$.detail-type",
      customer_tier: "$.detail.customer.tier",
      order_value: "$.detail.order.value"
    },
    input_template: <<~TEMPLATE
      {
        "routing": {
          "priority": <customer_tier> == "PREMIUM" ? "HIGH" : "NORMAL",
          "processor": <order_value> > 1000 ? "express" : "standard",
          "sla": <customer_tier> == "PREMIUM" ? "2h" : "24h"
        },
        "event": {
          "type": "<event_type>",
          "requiresApproval": <order_value> > 5000
        }
      }
    TEMPLATE
  }
})
```

## Performance Optimization

### Batch Processing Strategies

```ruby
# Aggregate events for batch processing
batch_aggregator = aws_cloudwatch_event_target(:batch_aggregate, {
  rule: high_volume_rule.name,
  arn: batch_aggregator_lambda.arn,
  input_transformer: {
    input_paths_map: {
      event_id: "$.id",
      event_type: "$.detail-type",
      payload: "$.detail"
    },
    input_template: jsonencode({
      batchKey: "<event_type>",
      event: {
        id: "<event_id>",
        data: JSON.parse("<payload>")
      },
      instructions: {
        maxBatchSize: 1000,
        maxWaitTime: 60
      }
    })
  }
})

# Process batches efficiently
batch_processor = aws_cloudwatch_event_target(:batch_process, {
  rule: batch_timer_rule.name,
  arn: "arn:aws:batch:${region}:${account}:job-queue/${batch_queue}",
  role_arn: batch_role.arn,
  batch_target: {
    job_definition: "event-batch-processor",
    job_name: "event-batch-${timestamp}",
    array_size: 10,  # Process in parallel
    job_attempts: 3,
    environment: [
      { name: "BATCH_SIZE", value: "1000" },
      { name: "PARALLEL_WORKERS", value: "4" }
    ]
  }
})
```

### Target Optimization

```ruby
# Optimize for high throughput
high_throughput = aws_cloudwatch_event_target(:optimized, {
  rule: streaming_rule.name,
  arn: kinesis_stream.arn,
  role_arn: kinesis_role.arn,
  kinesis_target: {
    partition_key_path: "$.detail.partitionKey"  # Even distribution
  },
  # Minimal transformation for performance
  input_path: "$.detail",
  # Aggressive retry for transient failures
  retry_policy: {
    maximum_retry_attempts: 10,
    maximum_event_age_in_seconds: 300  # 5 minutes
  }
})
```

## Monitoring and Observability

### Target Health Monitoring

```ruby
# Create CloudWatch dashboard for targets
target_dashboard = aws_cloudwatch_dashboard(:event_targets, {
  dashboard_name: "event-target-health",
  dashboard_body: jsonencode({
    widgets: [
      {
        type: "metric",
        properties: {
          title: "Target Invocations",
          metrics: [
            ["AWS/Events", "InvocationAttempts", "Rule", rule.name],
            [".", "SuccessfulRuleMatches", ".", "."],
            [".", "FailedInvocations", ".", "."]
          ]
        }
      },
      {
        type: "metric",
        properties: {
          title: "Target Latency",
          metrics: [
            ["AWS/Events", "IngestionToInvocationStartLatency", "Rule", rule.name, { stat: "Average" }],
            [".", ".", ".", ".", { stat: "p99" }]
          ]
        }
      }
    ]
  })
})

# Alert on target failures
target_alarm = aws_cloudwatch_metric_alarm(:target_failures, {
  alarm_name: "event-target-failures-${target.id}",
  namespace: "AWS/Events",
  metric_name: "FailedInvocations",
  dimensions: {
    Rule: rule.name,
    Target: target.target_id
  },
  statistic: "Sum",
  period: 300,
  evaluation_periods: 2,
  threshold: 10,
  comparison_operator: "GreaterThanThreshold",
  alarm_actions: [ops_topic.arn]
})
```

## Security Best Practices

### Least Privilege Targets

```ruby
# Minimal Lambda permissions
lambda_target = aws_cloudwatch_event_target(:secure_lambda, {
  rule: secure_rule.name,
  arn: secure_lambda.arn
})

# Lambda resource policy
aws_lambda_permission(:minimal_eventbridge, {
  function_name: secure_lambda.function_name,
  action: "lambda:InvokeFunction",
  principal: "events.amazonaws.com",
  source_arn: secure_rule.arn,  # Restrict to specific rule
  source_account: data.aws_caller_identity.current.account_id
})

# Minimal execution role for other targets
minimal_role = aws_iam_role(:target_execution, {
  name: "eventbridge-target-minimal",
  assume_role_policy: jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Principal: { Service: "events.amazonaws.com" },
      Action: "sts:AssumeRole",
      Condition: {
        StringEquals: {
          "aws:SourceAccount": data.aws_caller_identity.current.account_id
        },
        ArnLike: {
          "aws:SourceArn": "arn:aws:events:*:*:rule/*"
        }
      }
    }]
  })
})
```

### Data Privacy in Transformations

```ruby
# Redact sensitive data
privacy_transform = aws_cloudwatch_event_target(:privacy_conscious, {
  rule: event_rule.name,
  arn: processor.arn,
  input_transformer: {
    input_paths_map: {
      user_id: "$.detail.userId",
      action: "$.detail.action",
      timestamp: "$.time"
    },
    input_template: jsonencode({
      userId: "<user_id>",
      action: "<action>",
      timestamp: "<timestamp>",
      # Don't include PII fields like email, SSN, etc.
      metadata: {
        source: "eventbridge",
        processed: true
      }
    })
  }
})
```

## Future Enhancements

### Planned Features

1. **Content-Based Routing**: Native support for routing rules in targets
2. **Schema Validation**: Validate transformed output against schemas
3. **Compression Support**: Compress large payloads automatically
4. **Cross-Region Targets**: Native cross-region target support

### Extension Points

The current implementation provides extension points for:
- Custom target validators
- Transformation optimizers
- Service-specific helpers
- Monitoring integrations