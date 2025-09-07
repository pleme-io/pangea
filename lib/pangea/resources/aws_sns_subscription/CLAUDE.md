# AWS SNS Subscription Implementation

## Overview

The `aws_sns_subscription` resource provides a type-safe implementation for subscribing various endpoints to SNS topics, with comprehensive protocol validation, message filtering, and delivery configuration.

## Implementation Details

### Type System (types.rb)

The `SNSSubscriptionAttributes` class implements extensive validations:

1. **Protocol Validation**:
   - Enum constraint for 9 supported protocols
   - Each protocol has specific endpoint format validation
   - Protocol-specific feature support

2. **Endpoint Format Validation**:
   - **Email**: RFC-compliant email regex
   - **SMS**: E.164 phone number format
   - **HTTP/HTTPS**: URL prefix validation
   - **SQS**: ARN format for queues
   - **Lambda**: ARN format for functions
   - **Firehose**: ARN format for delivery streams

3. **JSON Policy Validations**:
   - `filter_policy` - Must be valid JSON object
   - `redrive_policy` - Must contain deadLetterTargetArn
   - `delivery_policy` - Valid JSON (HTTP/S only)

4. **Protocol-Specific Feature Validation**:
   - Raw message delivery only for certain protocols
   - Filter policy scope restrictions
   - Delivery policy only for HTTP/S
   - Role ARN required for Firehose

### Resource Function (resource.rb)

The `aws_sns_subscription` function:

1. **Protocol-Aware**: Conditionally adds attributes based on protocol
2. **Validation First**: Uses dry-struct for comprehensive validation
3. **Smart Defaults**: Only overrides non-default values
4. **Rich Outputs**: Provides subscription state information

### Helper Methods

Extensive helper methods for subscription analysis:
- `requires_confirmation?` - Email and HTTP/S need confirmation
- `supports_filter_policy?` - Not all protocols support filtering
- `supports_raw_delivery?` - JSON envelope removal capability
- `supports_dlq?` - Dead letter queue support
- `filter_policy_attributes` - Extract filter keys
- `has_numeric_filters?` - Detect numeric conditions

## Design Decisions

### 1. Endpoint Validation Depth
We validate endpoint formats to catch errors early:
- Prevents runtime subscription failures
- Provides clear error messages
- Ensures ARN formats are correct

### 2. Filter Policy as JSON
Accept filter policies as JSON strings to:
- Match AWS API expectations
- Support complex filter expressions
- Allow policy generators/builders

### 3. Protocol-Specific Features
Features are validated against protocol capabilities:
- Prevents invalid configurations
- Guides users to correct usage
- Matches AWS service limitations

### 4. Confirmation Handling
Email and HTTP/S subscriptions require confirmation:
- `endpoint_auto_confirms` for trusted endpoints
- `confirmation_timeout_in_minutes` for control
- Output includes `pending_confirmation` status

### 5. Computed Properties
Rich computed properties enable:
- Conditional infrastructure logic
- Subscription type detection
- Feature availability checks

## Testing Considerations

When testing subscriptions:

1. **Endpoint Validation**:
   ```ruby
   # Invalid email format
   expect {
     aws_sns_subscription(:test, {
       topic_arn: topic.arn,
       protocol: "email",
       endpoint: "not-an-email"
     })
   }.to raise_error(Dry::Struct::Error, /valid email/)
   
   # Invalid SQS ARN
   expect {
     aws_sns_subscription(:test, {
       topic_arn: topic.arn,
       protocol: "sqs",
       endpoint: "not-an-arn"
     })
   }.to raise_error(Dry::Struct::Error, /valid SQS queue ARN/)
   ```

2. **Protocol Features**:
   ```ruby
   # Raw delivery not supported for email
   expect {
     aws_sns_subscription(:test, {
       topic_arn: topic.arn,
       protocol: "email",
       endpoint: "test@example.com",
       raw_message_delivery: true
     })
   }.to raise_error(Dry::Struct::Error, /only valid for/)
   ```

3. **Filter Policy**:
   ```ruby
   # Valid filter policy
   sub = aws_sns_subscription(:test, {
     topic_arn: topic.arn,
     protocol: "sqs",
     endpoint: queue.arn,
     filter_policy: JSON.generate({
       store: ["example"],
       price: [{ numeric: [">=", 100] }]
     })
   })
   
   expect(sub.computed.filter_policy_attributes).to eq(["store", "price"])
   expect(sub.computed.has_numeric_filters).to be true
   ```

## Integration Patterns

### SQS Fan-out Pattern
```ruby
# Create topic
topic = aws_sns_topic(:events, { name: "events" })

# Create multiple queues with subscriptions
services = {
  orders: { filter: { event_type: ["order_*"] } },
  inventory: { filter: { event_type: ["inventory_*"] } },
  shipping: { filter: { event_type: ["shipping_*"] } }
}

services.each do |service, config|
  # Create queue
  queue = aws_sqs_queue(:"#{service}_queue", {
    name: "#{service}-events"
  })
  
  # Queue policy
  aws_sqs_queue_policy(:"#{service}_policy", {
    queue_url: queue.url,
    policy: JSON.generate({
      Version: "2012-10-17",
      Statement: [{
        Effect: "Allow",
        Principal: { Service: "sns.amazonaws.com" },
        Action: "sqs:SendMessage",
        Resource: "*",
        Condition: {
          ArnEquals: { "aws:SourceArn": topic.arn }
        }
      }]
    })
  })
  
  # Filtered subscription
  aws_sns_subscription(:"#{service}_sub", {
    topic_arn: topic.arn,
    protocol: "sqs",
    endpoint: queue.arn,
    filter_policy: JSON.generate(config[:filter])
  })
end
```

### Multi-Channel Alerting
```ruby
# Critical alerts to multiple channels
critical_topic = aws_sns_topic(:critical, {
  name: "critical-alerts"
})

# Email for humans
aws_sns_subscription(:email_alert, {
  topic_arn: critical_topic.arn,
  protocol: "email",
  endpoint: "oncall@company.com"
})

# SMS for urgent
aws_sns_subscription(:sms_alert, {
  topic_arn: critical_topic.arn,
  protocol: "sms",
  endpoint: "+12025551234"
})

# Webhook for automation
aws_sns_subscription(:webhook_alert, {
  topic_arn: critical_topic.arn,
  protocol: "https",
  endpoint: "https://alerts.company.com/sns",
  raw_message_delivery: true
})

# Lambda for remediation
aws_sns_subscription(:lambda_alert, {
  topic_arn: critical_topic.arn,
  protocol: "lambda",
  endpoint: remediation_lambda.arn
})
```

## Filter Policy Best Practices

1. **Attribute Filters**:
   - More efficient than body filters
   - Work with all supporting protocols
   - Better for structured data

2. **Body Filters**:
   - Only for SQS, Lambda, Firehose
   - Useful for third-party messages
   - JSON path expressions

3. **Filter Complexity**:
   - Keep filters simple for performance
   - Test filters thoroughly
   - Monitor filter metrics

4. **Numeric Filters**:
   ```json
   {
     "price": [{ "numeric": [">=", 100, "<=", 200] }],
     "quantity": [{ "numeric": [">", 0] }]
   }
   ```

5. **String Operators**:
   ```json
   {
     "eventType": [{ "prefix": "order-" }],
     "region": [{ "anything-but": ["test"] }],
     "customerId": [{ "exists": true }]
   }
   ```

## Security Considerations

1. **Endpoint Validation**: Always validate HTTPS endpoints
2. **Confirmation**: Implement confirmation for email/HTTP
3. **Access Control**: Use subscription policies where needed
4. **Encryption**: Enable encryption on topics
5. **DLQ Usage**: Configure DLQ for critical subscriptions

## Monitoring Integration

Use outputs and computed properties:
```ruby
sub = aws_sns_subscription(:monitored, {
  topic_arn: topic.arn,
  protocol: "https",
  endpoint: "https://api.example.com/events"
})

# Monitor pending confirmations
aws_cloudwatch_metric_alarm(:pending_confirm, {
  alarm_name: "subscription-pending-confirmation",
  metric_name: "NumberOfNotificationsFailed",
  namespace: "AWS/SNS",
  dimensions: {
    TopicName: topic.name,
    SubscriptionArn: sub.arn
  }
})
```