# AWS SNS Topic Implementation

## Overview

The `aws_sns_topic` resource provides a type-safe implementation for AWS Simple Notification Service (SNS) topics, supporting both Standard and FIFO topic types with comprehensive configuration for messaging, encryption, delivery feedback, and data protection.

## Implementation Details

### Type System (types.rb)

The `SNSTopicAttributes` class uses dry-struct for runtime validation with extensive validations:

1. **Topic Naming Validation**:
   - FIFO topics must end with `.fifo` suffix
   - Standard topics cannot end with `.fifo` suffix
   - Names are optional (AWS can auto-generate)

2. **JSON Policy Validations**:
   - `delivery_policy` - Must be valid JSON
   - `policy` - Must be valid JSON (IAM policy)
   - `message_data_protection_policy` - Must be valid JSON

3. **FIFO-Specific Validations**:
   - `content_based_deduplication` only valid for FIFO topics
   - Enforces FIFO naming convention

4. **Feedback Configuration Validations**:
   - Sample rates require corresponding role ARNs
   - Sample rates constrained to 0-100
   - Separate configuration per protocol

### Resource Function (resource.rb)

The `aws_sns_topic` function:

1. **Validates Input**: Uses `SNSTopicAttributes` for comprehensive validation
2. **Generates Terraform**: Creates `aws_sns_topic` resource block
3. **Conditional Attributes**: Only adds non-nil optional attributes
4. **Returns Reference**: Provides typed reference with extensive outputs

Key implementation details:
- Handles 15+ feedback configuration attributes
- Supports all SNS protocols for feedback
- Manages FIFO-specific features conditionally
- Provides rich computed properties

### Helper Methods

The type class provides numerous helper methods:
- `is_fifo?` - Check if FIFO topic
- `is_encrypted?` - Check if KMS encryption is enabled
- `has_delivery_policy?` - Check for retry configuration
- `has_access_policy?` - Check for access control
- `has_data_protection?` - Check for PII protection
- `has_feedback_enabled?` - Check any feedback configuration
- `feedback_protocols` - List protocols with feedback
- `topic_type` - Return "Standard" or "FIFO"
- `tracing_enabled?` - Check if X-Ray is active

## Design Decisions

### 1. Optional Topic Names
We allow topics without names, letting AWS auto-generate them. This supports dynamic topic creation patterns.

### 2. Comprehensive Feedback Support
All five SNS delivery protocols have individual feedback configuration:
- Application (mobile push)
- HTTP/HTTPS endpoints
- Lambda functions
- SQS queues
- Kinesis Data Firehose

Each protocol has success/failure role ARNs and success sample rates.

### 3. Policy Handling
Three separate policies are supported:
- `policy` - IAM resource policy for access control
- `delivery_policy` - Retry and throttling configuration
- `message_data_protection_policy` - PII/sensitive data protection

All are validated as JSON but not deeply parsed to maintain flexibility.

### 4. Tracing Configuration
X-Ray tracing uses an enum to ensure valid values:
- "Active" - Generate trace segments
- "PassThrough" - Honor upstream trace headers

### 5. Computed Properties
Rich computed properties enable:
- Infrastructure analysis
- Security auditing
- Cost optimization
- Monitoring setup

## Testing Considerations

When testing SNS topics:

1. **Topic Type Tests**:
   ```ruby
   # FIFO naming validation
   expect { 
     aws_sns_topic(:test, { 
       name: "test", 
       fifo_topic: true 
     }) 
   }.to raise_error(Dry::Struct::Error, /must end with '.fifo'/)
   ```

2. **Feedback Configuration Tests**:
   ```ruby
   # Sample rate requires role ARN
   expect {
     aws_sns_topic(:test, {
       name: "test",
       http_success_feedback_sample_rate: 100
       # Missing http_success_feedback_role_arn
     })
   }.to raise_error(Dry::Struct::Error, /requires.*role_arn/)
   ```

3. **Policy Validation Tests**:
   ```ruby
   # Invalid JSON policy
   expect {
     aws_sns_topic(:test, {
       name: "test",
       policy: "invalid json"
     })
   }.to raise_error(Dry::Struct::Error, /valid JSON/)
   ```

## Integration Patterns

### With SQS Queues (Fan-out)
```ruby
topic = aws_sns_topic(:events, { name: "events" })

# Create multiple queues
queues = ["orders", "inventory", "shipping"].map do |service|
  queue = aws_sqs_queue(:"#{service}_queue", {
    name: "#{service}-queue"
  })
  
  # Subscribe queue to topic
  aws_sns_subscription(:"#{service}_sub", {
    topic_arn: topic.arn,
    protocol: "sqs",
    endpoint: queue.arn
  })
  
  queue
end
```

### With Lambda Functions
```ruby
topic = aws_sns_topic(:triggers, { name: "lambda-triggers" })

aws_lambda_permission(:sns_invoke, {
  function_name: lambda_function.name,
  principal: "sns.amazonaws.com",
  source_arn: topic.arn
})

aws_sns_subscription(:lambda_sub, {
  topic_arn: topic.arn,
  protocol: "lambda",
  endpoint: lambda_function.arn
})
```

### With CloudWatch Logs
```ruby
# Topic with delivery feedback
topic = aws_sns_topic(:monitored, {
  name: "monitored-topic",
  http_failure_feedback_role_arn: feedback_role.arn,
  lambda_failure_feedback_role_arn: feedback_role.arn
})

# Logs will be created in CloudWatch Logs groups:
# - sns/us-east-1/123456789012/monitored-topic/http/failure
# - sns/us-east-1/123456789012/monitored-topic/lambda/failure
```

## Performance Considerations

1. **FIFO vs Standard**: 
   - Standard topics: Higher throughput, at-least-once delivery
   - FIFO topics: Exactly-once, ordered delivery, lower throughput

2. **Content-Based Deduplication**:
   - Reduces duplicate messages in FIFO topics
   - Adds processing overhead
   - 5-minute deduplication window

3. **Feedback Sampling**:
   - 100% sampling for critical applications
   - Lower rates for high-volume topics
   - Balance between visibility and cost

4. **Message Size**:
   - 256KB maximum per message
   - Use S3 for larger payloads with SNS notifications

## Security Best Practices

1. **Always Enable Encryption**: Use KMS for sensitive data
2. **Implement Access Policies**: Restrict publish/subscribe permissions
3. **Use Data Protection**: Block PII/sensitive data patterns
4. **Enable Feedback**: Monitor delivery failures
5. **Tag Resources**: Enable compliance and cost tracking
6. **Validate Publishers**: Use conditions in policies

## Monitoring Integration

The resource enables comprehensive monitoring:
```ruby
topic = aws_sns_topic(:critical, {
  name: "critical-events",
  lambda_failure_feedback_role_arn: role.arn
})

# CloudWatch alarm on publish failures
aws_cloudwatch_metric_alarm(:publish_failures, {
  alarm_name: "#{topic.name}-publish-failures",
  metric_name: "NumberOfMessagesFailed",
  namespace: "AWS/SNS",
  dimensions: {
    TopicName: topic.name
  },
  threshold: 5
})
```

## Data Protection Patterns

Message data protection policies can:
- Block credit card numbers
- Redact social security numbers
- Audit sensitive data usage
- Deny messages with PII

Example identifiers:
- `arn:aws:dataprotection::aws:data-identifier/CreditCardNumber`
- `arn:aws:dataprotection::aws:data-identifier/SocialSecurityNumber`
- `arn:aws:dataprotection::aws:data-identifier/EmailAddress`
- `arn:aws:dataprotection::aws:data-identifier/PhoneNumber`