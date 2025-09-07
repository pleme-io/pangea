# AWS CloudWatch Log Subscription Filter - Architecture Documentation

## Core Concepts

### Subscription Filter Design Philosophy

CloudWatch Log Subscription Filters implement real-time log streaming, enabling event-driven architectures and continuous data processing. This resource implements:

1. **Real-Time Streaming**: Near-instantaneous log delivery to destinations
2. **Selective Filtering**: Pattern-based log selection to reduce noise and costs
3. **Multi-Destination Support**: Flexible routing to various AWS services
4. **Scalable Distribution**: Configurable log distribution strategies

### Implementation Architecture

```
Log Subscription Filter
├── Source Configuration
│   ├── Log Group Selection
│   ├── Filter Pattern Engine
│   └── Distribution Strategy
├── Destination Routing
│   ├── Kinesis Streams
│   ├── Lambda Functions
│   ├── Kinesis Firehose
│   └── Cross-Account Destinations
└── Security Layer
    ├── IAM Role Management
    ├── Cross-Account Trust
    └── Resource Policies
```

## Type Safety Implementation

### Validation Layers

1. **ARN Validation**
   - Destination ARN format checking
   - Role ARN structure validation
   - Service-specific ARN patterns

2. **Filter Configuration**
   - Pattern syntax validation
   - Name format constraints
   - Distribution option validation

3. **Security Requirements**
   - Role requirement detection
   - Cross-account configuration validation
   - Service-specific permission checks

### Type Definitions

```ruby
# Intelligent role requirement detection
def requires_role?
  [:lambda, :kinesis_stream, :kinesis_firehose].include?(destination_service)
end

# Cross-account detection from ARNs
def is_cross_account?
  destination_account != role_account
end

# Service identification from ARN
def destination_service
  case destination_arn
  when /^arn:aws[a-z\-]*:lambda:/ then :lambda
  when /^arn:aws[a-z\-]*:kinesis:.*:stream\// then :kinesis_stream
  when /^arn:aws[a-z\-]*:firehose:/ then :kinesis_firehose
  end
end
```

## Advanced Patterns

### 1. Multi-Stage Processing Pipeline

Implement complex log processing pipelines:

```ruby
# Stage 1: Initial filtering and routing
initial_filter = aws_cloudwatch_log_subscription_filter(:stage1_filter, {
  name: "initial-log-router",
  log_group_name: raw_logs.name,
  destination_arn: routing_stream.arn,
  filter_pattern: '{ $.processing_required = true }',
  role_arn: routing_role.arn,
  distribution: "ByLogStream"
})

# Stage 2: Enrichment via Lambda
enrichment_lambda = aws_lambda_function(:log_enricher, {
  function_name: "log-enrichment-processor",
  runtime: "python3.9",
  environment: {
    variables: {
      ENRICHMENT_TABLE: enrichment_table.name
    }
  }
})

# Stage 3: Final destination routing
final_subscription = aws_cloudwatch_log_subscription_filter(:final_router, {
  name: "enriched-log-destination",
  log_group_name: enriched_logs.name,
  destination_arn: analytics_firehose.arn,
  filter_pattern: '{ $.enrichment_complete = true }',
  role_arn: firehose_role.arn
})
```

### 2. Intelligent Log Sampling

Implement cost-effective log sampling strategies:

```ruby
# Sample high-volume logs intelligently
sampling_rules = {
  debug: { rate: 0.01, pattern: '{ $.level = "DEBUG" }' },
  info: { rate: 0.1, pattern: '{ $.level = "INFO" }' },
  warning: { rate: 0.5, pattern: '{ $.level = "WARNING" }' },
  error: { rate: 1.0, pattern: '{ $.level = "ERROR" }' }
}

# Create sampling Lambda
sampler = aws_lambda_function(:log_sampler, {
  function_name: "intelligent-log-sampler",
  runtime: "nodejs18.x",
  environment: {
    variables: {
      SAMPLING_RULES: jsonencode(sampling_rules)
    }
  }
})

# Subscribe to sampler
sampling_subscription = aws_cloudwatch_log_subscription_filter(:sampler, {
  name: "intelligent-sampling",
  log_group_name: high_volume_logs.name,
  destination_arn: sampler.arn,
  role_arn: sampler_role.arn
})
```

### 3. Security Event Correlation

Build security event correlation systems:

```ruby
# Collect security events from multiple sources
security_sources = {
  cloudtrail: "/aws/cloudtrail/management",
  guardduty: "/aws/guardduty/findings",
  waf: "/aws/waf/alerts",
  vpc_flow: "/aws/vpc/flowlogs"
}

# Central correlation stream
correlation_stream = aws_kinesis_stream(:security_correlation, {
  name: "security-event-correlation",
  shard_count: 20,
  encryption_type: "KMS",
  kms_key_id: security_kms_key.id
})

# Subscribe each source with specific patterns
security_sources.each do |source, log_group|
  aws_cloudwatch_log_subscription_filter(:"security_#{source}", {
    name: "security-#{source}-events",
    log_group_name: log_group,
    destination_arn: correlation_stream.arn,
    filter_pattern: case source
    when :cloudtrail then '{ $.eventName = "*SecurityGroup*" || $.eventName = "*User*" }'
    when :guardduty then '{ $.severity >= 4 }'
    when :waf then '{ $.action = "BLOCK" }'
    when :vpc_flow then '{ $.dstport = 22 || $.dstport = 3389 }'
    end,
    role_arn: security_role.arn
  })
end
```

### 4. Real-Time Anomaly Detection

Stream logs for ML-based anomaly detection:

```ruby
# Stream to Kinesis for anomaly detection
anomaly_stream = aws_kinesis_stream(:anomaly_detection, {
  name: "anomaly-detection-stream",
  shard_count: 15
})

# Subscribe application logs
app_subscription = aws_cloudwatch_log_subscription_filter(:anomaly_feed, {
  name: "anomaly-detection-feed",
  log_group_name: app_logs.name,
  destination_arn: anomaly_stream.arn,
  filter_pattern: '{ $.metric_value = * }',  # Numeric metrics only
  role_arn: anomaly_role.arn
})

# Kinesis Analytics for real-time anomaly detection
anomaly_app = aws_kinesis_analytics_application(:detector, {
  name: "real-time-anomaly-detector",
  sql_code: <<~SQL
    CREATE STREAM anomaly_scores AS
    SELECT STREAM
      metric_name,
      metric_value,
      ANOMALY_SCORE(metric_value) OVER (
        PARTITION BY metric_name 
        RANGE INTERVAL '10' MINUTE PRECEDING
      ) AS anomaly_score
    FROM SOURCE_SQL_STREAM_001;
  SQL
})
```

## Distribution Strategies

### ByLogStream vs Random

```ruby
# ByLogStream - Maintains order within log streams
ordered_subscription = aws_cloudwatch_log_subscription_filter(:ordered, {
  name: "ordered-delivery",
  log_group_name: transaction_logs.name,
  destination_arn: audit_stream.arn,
  distribution: "ByLogStream",  # Preserves order per stream
  role_arn: audit_role.arn
})

# Random - Better load distribution
balanced_subscription = aws_cloudwatch_log_subscription_filter(:balanced, {
  name: "load-balanced-delivery",
  log_group_name: metrics_logs.name,
  destination_arn: metrics_stream.arn,
  distribution: "Random",  # Distributes across shards
  role_arn: metrics_role.arn
})
```

### Distribution Strategy Selection

1. **Use ByLogStream When**:
   - Log order is critical (audit trails)
   - Processing depends on sequence
   - Analyzing user sessions
   - Maintaining transaction integrity

2. **Use Random When**:
   - Maximizing throughput
   - Order independence
   - Load balancing is priority
   - Aggregating metrics

## Performance Optimization

### Destination Capacity Planning

```ruby
# Calculate required Kinesis shards
def calculate_kinesis_shards(logs_per_second, avg_log_size_kb)
  # Kinesis limits: 1MB/s or 1000 records/s per shard
  throughput_shards = (logs_per_second * avg_log_size_kb / 1024.0).ceil
  record_shards = (logs_per_second / 1000.0).ceil
  
  [throughput_shards, record_shards].max
end

# Create appropriately sized stream
log_stream = aws_kinesis_stream(:optimized, {
  name: "optimized-log-stream",
  shard_count: calculate_kinesis_shards(5000, 2),  # 5k logs/s, 2KB each
  retention_period: 24
})
```

### Filter Pattern Optimization

```ruby
# Inefficient - processes all logs
inefficient = aws_cloudwatch_log_subscription_filter(:all_logs, {
  name: "process-everything",
  log_group_name: logs.name,
  destination_arn: expensive_processor.arn,
  filter_pattern: "",  # Empty = all logs
  role_arn: role.arn
})

# Efficient - pre-filters at source
efficient = aws_cloudwatch_log_subscription_filter(:filtered, {
  name: "process-important-only",
  log_group_name: logs.name,
  destination_arn: processor.arn,
  filter_pattern: '{ $.importance = "HIGH" || $.level = "ERROR" }',
  role_arn: role.arn
})
```

## Security Best Practices

### IAM Role Configuration

```ruby
# Minimal permissions role
subscription_role = aws_iam_role(:log_subscription, {
  name: "cloudwatch-logs-subscription",
  assume_role_policy: jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Principal: { 
        Service: "logs.amazonaws.com"
      },
      Action: "sts:AssumeRole",
      Condition: {
        StringLike: {
          "aws:SourceArn": "arn:aws:logs:${region}:${account_id}:*"
        }
      }
    }]
  })
})

# Destination-specific permissions
kinesis_policy = aws_iam_policy(:kinesis_put, {
  name: "logs-kinesis-put",
  policy: jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Action: [
        "kinesis:PutRecord",
        "kinesis:PutRecords"
      ],
      Resource: specific_stream.arn
    }]
  })
})
```

### Cross-Account Security

```ruby
# Secure cross-account setup
cross_account_subscription = aws_cloudwatch_log_subscription_filter(:cross_account, {
  name: "secure-cross-account",
  log_group_name: sensitive_logs.name,
  destination_arn: central_destination.arn,
  filter_pattern: '{ $.data_classification != "CONFIDENTIAL" }',
  # No role needed for CloudWatch Logs destinations
})

# Ensure destination policy allows access
destination_policy = aws_cloudwatch_log_destination_policy(:allow_source, {
  destination_name: central_destination.name,
  access_policy: jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Principal: { AWS: source_account_id },
      Action: "logs:PutSubscriptionFilter",
      Resource: central_destination.arn,
      Condition: {
        StringEquals: {
          "logs:DestinationArn": central_destination.arn
        }
      }
    }]
  })
})
```

## Monitoring and Alerting

### Subscription Health Monitoring

```ruby
# Monitor delivery errors
delivery_alarm = aws_cloudwatch_metric_alarm(:delivery_errors, {
  alarm_name: "subscription-delivery-errors",
  namespace: "AWS/Logs",
  metric_name: "DeliveryErrors",
  dimensions: {
    LogGroupName: log_group.name,
    DestinationType: "Kinesis"
  },
  statistic: "Sum",
  period: 300,
  evaluation_periods: 2,
  threshold: 10,
  comparison_operator: "GreaterThanThreshold"
})

# Monitor throttling
throttle_alarm = aws_cloudwatch_metric_alarm(:delivery_throttle, {
  alarm_name: "subscription-throttling",
  namespace: "AWS/Logs",
  metric_name: "DeliveryThrottling",
  dimensions: {
    LogGroupName: log_group.name
  },
  statistic: "Sum",
  period: 60,
  evaluation_periods: 3,
  threshold: 100,
  comparison_operator: "GreaterThanThreshold"
})
```

## Troubleshooting Guide

### Common Issues and Solutions

1. **No Logs Delivered**
   ```ruby
   # Checklist:
   # 1. Verify role trust policy
   # 2. Check destination permissions
   # 3. Test filter pattern
   # 4. Ensure log group has data
   ```

2. **Intermittent Delivery**
   ```ruby
   # Check metrics
   aws_cloudwatch_dashboard(:subscription_health, {
     dashboard_name: "subscription-health",
     dashboard_body: jsonencode({
       widgets: [{
         type: "metric",
         properties: {
           metrics: [
             ["AWS/Logs", "DeliveryErrors", "LogGroupName", log_group.name],
             [".", "DeliveryThrottling", ".", "."],
             ["AWS/Kinesis", "IncomingRecords", "StreamName", stream.name],
             [".", "WriteProvisionedThroughputExceeded", ".", "."]
           ]
         }
       }]
     })
   })
   ```

3. **Filter Pattern Issues**
   ```ruby
   # Test pattern in CloudWatch Logs Insights
   test_query = <<~QUERY
     fields @timestamp, @message
     | parse @message /#{filter_pattern}/
     | limit 20
   QUERY
   ```

## Future Enhancements

### Planned Features

1. **Multi-Destination Support**: Route to multiple destinations from single filter
2. **Transformation Support**: Built-in log transformation capabilities
3. **Sampling Configuration**: Native sampling support in filters
4. **Enhanced Patterns**: Richer pattern language with functions

### Extension Points

The current implementation provides extension points for:
- Custom destination validators
- Pattern optimization algorithms
- Distribution strategy plugins
- Monitoring integrations