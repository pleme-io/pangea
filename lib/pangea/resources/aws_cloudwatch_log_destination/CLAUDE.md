# AWS CloudWatch Log Destination - Architecture Documentation

## Core Concepts

### Log Destination Design Philosophy

CloudWatch Log Destinations enable a powerful pattern for centralized logging across AWS accounts and regions. This resource implements:

1. **Cross-Account Log Streaming**: Secure log aggregation across organizational boundaries
2. **Real-Time Processing**: Stream logs to Kinesis for immediate processing
3. **Compliance Architecture**: Centralized audit logging for regulatory requirements
4. **Multi-Region Aggregation**: Consolidate logs from global infrastructure

### Implementation Architecture

```
Log Destination
├── Access Control
│   ├── IAM Role (Trust Policy)
│   ├── Destination Policy
│   └── Cross-Account Permissions
├── Target Integration
│   ├── Kinesis Data Streams
│   ├── Kinesis Data Firehose
│   └── AWS Lambda (indirect)
└── Subscription Management
    ├── Log Group Filters
    ├── Pattern Matching
    └── Delivery Configuration
```

## Type Safety Implementation

### Validation Layers

1. **ARN Format Validation**
   - IAM role ARN structure validation
   - Target resource ARN validation
   - Region and account extraction

2. **Name Validation**
   - Alphanumeric with hyphens, underscores, periods
   - Uniqueness within region (AWS enforced)
   - Length constraints

3. **Service Integration Validation**
   - Supported target service verification
   - Cross-service compatibility checks

### Type Definitions

```ruby
# Core attribute types with validation
attribute :name, Resources::Types::String
attribute :role_arn, Resources::Types::String
attribute :target_arn, Resources::Types::String

# Computed properties for integration
def target_service
  # Extract service from ARN
end

def region
  # Extract region from ARN
end
```

## Advanced Patterns

### 1. Organization-Wide Logging

Implement centralized logging for AWS Organizations:

```ruby
# Master account log destination
master_destination = aws_cloudwatch_log_destination(:org_master, {
  name: "organization-master-logs",
  role_arn: org_log_role.arn,
  target_arn: master_kinesis_stream.arn
})

# Policy allowing all organization accounts
org_policy = aws_cloudwatch_log_destination_policy(:org_access, {
  destination_name: master_destination.name,
  access_policy: jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Principal: "*",
      Action: "logs:PutSubscriptionFilter",
      Resource: master_destination.arn,
      Condition: {
        StringEquals: {
          "aws:PrincipalOrgID": organization.id
        }
      }
    }]
  })
})
```

### 2. Regional Log Aggregation

Aggregate logs from multiple regions:

```ruby
regions = ['us-east-1', 'eu-west-1', 'ap-southeast-1']

# Central aggregation point
central_stream = aws_kinesis_stream(:global_logs, {
  name: "global-log-aggregation",
  shard_count: 50  # High capacity for global logs
})

# Create destination in primary region
global_destination = aws_cloudwatch_log_destination(:global, {
  name: "global-log-destination",
  role_arn: global_log_role.arn,
  target_arn: central_stream.arn
})

# In each region, create subscription filters pointing to destination
```

### 3. Compliance and Audit Logging

Implement tamper-proof audit logging:

```ruby
# Encrypted Kinesis stream for compliance
audit_stream = aws_kinesis_stream(:audit_logs, {
  name: "compliance-audit-stream",
  encryption_type: "KMS",
  kms_key_id: audit_kms_key.id,
  shard_count: 20
})

# Restricted role for audit logs
audit_role = aws_iam_role(:audit_destination, {
  name: "audit-log-destination-role",
  assume_role_policy: jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Principal: { Service: "logs.amazonaws.com" },
      Action: "sts:AssumeRole",
      Condition: {
        StringEquals: {
          "sts:ExternalId": secure_external_id
        }
      }
    }]
  })
})

# Audit log destination
audit_destination = aws_cloudwatch_log_destination(:audit, {
  name: "compliance-audit-destination",
  role_arn: audit_role.arn,
  target_arn: audit_stream.arn,
  tags: {
    Compliance: "SOC2",
    DataRetention: "7years",
    Encryption: "required"
  }
})
```

### 4. Real-Time Security Monitoring

Stream security logs for immediate analysis:

```ruby
# High-throughput stream for security events
security_stream = aws_kinesis_stream(:security_events, {
  name: "real-time-security-stream",
  shard_count: 30,
  retention_period: 24  # Short retention for hot data
})

# Security log destination
security_destination = aws_cloudwatch_log_destination(:security, {
  name: "security-event-destination",
  role_arn: security_role.arn,
  target_arn: security_stream.arn
})

# Lambda for real-time processing
aws_lambda_event_source_mapping(:security_processor, {
  function_name: security_analyzer.function_name,
  event_source_arn: security_stream.arn,
  starting_position: "LATEST",
  parallelization_factor: 10
})
```

## Integration Patterns

### Kinesis Data Streams Integration

```ruby
# Standard integration pattern
stream = aws_kinesis_stream(:logs, {
  name: "application-logs",
  shard_count: calculate_shards(expected_log_volume)
})

destination = aws_cloudwatch_log_destination(:app_logs, {
  name: "application-log-destination",
  role_arn: kinesis_writer_role.arn,
  target_arn: stream.arn
})
```

### Kinesis Data Firehose Integration

```ruby
# For S3 archival
firehose = aws_kinesis_firehose_delivery_stream(:archive, {
  name: "log-archive-stream",
  destination: "extended_s3",
  extended_s3_configuration: {
    bucket_arn: archive_bucket.arn,
    prefix: "logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/",
    error_output_prefix: "error-logs/",
    compression_format: "GZIP"
  }
})

archive_destination = aws_cloudwatch_log_destination(:archive, {
  name: "log-archive-destination",
  role_arn: firehose_role.arn,
  target_arn: firehose.arn
})
```

## Performance Optimization

### Capacity Planning

1. **Kinesis Shard Calculation**
   ```ruby
   def calculate_shards(logs_per_second)
     # Each shard: 1MB/sec or 1000 records/sec
     bytes_per_log = 1024  # 1KB average
     throughput_mb = (logs_per_second * bytes_per_log) / (1024 * 1024)
     
     [
       (throughput_mb / 1).ceil,  # MB limit
       (logs_per_second / 1000).ceil  # Record limit
     ].max
   end
   ```

2. **Destination Limits**
   - 10 destinations per region
   - 2 subscription filters per log group
   - Plan destination strategy accordingly

### Cost Optimization

1. **Log Filtering**: Use subscription filter patterns to reduce data transfer
2. **Compression**: Enable compression in Kinesis/Firehose
3. **Retention Policies**: Set appropriate retention on streams
4. **Regional Strategy**: Consider data transfer costs for cross-region

## Security Best Practices

### IAM Role Configuration

```ruby
# Minimal permissions for log destination
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kinesis:PutRecord",
        "kinesis:PutRecords"
      ],
      "Resource": "arn:aws:kinesis:*:*:stream/specific-stream-name"
    }
  ]
}
```

### Encryption Strategy

1. **In-Transit**: TLS encryption for all API calls
2. **At-Rest**: KMS encryption on Kinesis streams
3. **Key Rotation**: Automated KMS key rotation
4. **Access Logging**: CloudTrail for destination access

## Monitoring and Alerting

### Key Metrics

```ruby
# Monitor destination health
destination_alarm = aws_cloudwatch_metric_alarm(:destination_errors, {
  alarm_name: "log-destination-delivery-errors",
  namespace: "AWS/Logs",
  metric_name: "DeliveryErrors",
  dimensions: {
    DestinationName: destination.name
  },
  statistic: "Sum",
  period: 300,
  evaluation_periods: 2,
  threshold: 10,
  comparison_operator: "GreaterThanThreshold"
})
```

### Dashboard Creation

```ruby
# Comprehensive monitoring dashboard
aws_cloudwatch_dashboard(:log_destination_monitor, {
  dashboard_name: "log-destinations-health",
  dashboard_body: jsonencode({
    widgets: [
      {
        type: "metric",
        properties: {
          metrics: [
            ["AWS/Logs", "DeliveryErrors", "DestinationName", destination.name],
            [".", "DeliveryThrottling", ".", "."]
          ],
          period: 300,
          stat: "Sum",
          region: "us-east-1",
          title: "Destination Delivery Health"
        }
      }
    ]
  })
})
```

## Troubleshooting Guide

### Common Issues and Solutions

1. **Destination Not Receiving Logs**
   - Verify subscription filter is active
   - Check IAM role trust relationship
   - Validate Kinesis stream is active
   - Review CloudWatch Logs metrics

2. **Intermittent Delivery Failures**
   - Check Kinesis throttling metrics
   - Verify shard capacity
   - Review concurrent Lambda executions
   - Check for regional service issues

3. **Cross-Account Access Denied**
   - Validate destination policy
   - Check account ID in policy
   - Verify no SCPs blocking access
   - Review cross-account role assumptions

### Debug Checklist

- [ ] IAM role can be assumed by logs.amazonaws.com
- [ ] Role has permissions to write to target
- [ ] Destination policy allows source account
- [ ] Subscription filter pattern matches logs
- [ ] Target service (Kinesis) is healthy
- [ ] No service limits exceeded

## Future Enhancements

### Planned Features

1. **Multi-Target Destinations**: Support for multiple targets per destination
2. **Built-in Transformations**: Log format transformation at destination
3. **Conditional Routing**: Route based on log content
4. **Native S3 Integration**: Direct S3 destination support

### Extension Points

The current implementation provides extension points for:
- Custom validation rules
- Target service expansion
- Policy generation helpers
- Metric aggregation utilities