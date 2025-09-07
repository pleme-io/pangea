# AWS SQS Queue Policy Implementation

## Overview

The `aws_sqs_queue_policy` resource provides a type-safe implementation for managing SQS queue access policies using IAM policy documents. It includes validation, security analysis, and action tracking capabilities.

## Implementation Details

### Type System (types.rb)

The `SQSQueuePolicyAttributes` class validates:

1. **JSON Validation**:
   - Policy must be valid JSON
   - Automatic parsing to validate structure
   - Detailed error messages for JSON parsing failures

2. **Policy Structure Validation**:
   - Must have a `Statement` array
   - Each statement must have `Effect` and `Action`
   - Effect must be "Allow" or "Deny"

3. **Security Analysis**:
   - Detects cross-account access patterns
   - Identifies public access risks
   - Tracks allowed and denied actions

### Resource Function (resource.rb)

The `aws_sqs_queue_policy` function:

1. **Simple Implementation**: Maps directly to Terraform resource
2. **Computed Properties**: Provides security insights
3. **Action Analysis**: Extracts and categorizes actions

### Helper Methods

- `policy_document` - Parsed policy as Ruby hash
- `statement_count` - Number of policy statements
- `allows_cross_account?` - Detects cross-account principals
- `allows_public_access?` - Detects wildcard principals
- `allowed_actions` - Lists all allowed actions
- `denied_actions` - Lists all denied actions

## Design Decisions

### 1. Policy as JSON String
We accept the policy as a JSON string rather than a Ruby hash to:
- Match Terraform's expected format
- Allow direct use of AWS policy generators
- Maintain consistency with other AWS resources

### 2. Validation Depth
We validate policy structure but not:
- Action validity (AWS validates this)
- Resource ARN formats (context-dependent)
- Principal formats (too varied)

This balances early error detection with flexibility.

### 3. Security Analysis
The security helper methods enable:
- Automated security reviews
- Policy compliance checks
- Access pattern documentation

### 4. Cross-Account Detection
We detect cross-account access by looking for:
- ARNs with `:root` suffix
- Different account IDs
- Non-wildcard principals

## Testing Considerations

When testing queue policies:

1. **JSON Validation**:
   ```ruby
   # Invalid JSON
   expect { 
     aws_sqs_queue_policy(:test, {
       queue_url: "https://sqs.region.amazonaws.com/account/queue",
       policy: "invalid json"
     })
   }.to raise_error(Dry::Struct::Error, /valid JSON/)
   ```

2. **Policy Structure**:
   ```ruby
   # Missing required fields
   invalid_policy = {
     Version: "2012-10-17",
     Statement: [{ Action: "sqs:*" }]  # Missing Effect
   }
   
   expect {
     aws_sqs_queue_policy(:test, {
       queue_url: queue.url,
       policy: JSON.generate(invalid_policy)
     })
   }.to raise_error(Dry::Struct::Error, /must have Effect/)
   ```

3. **Security Analysis**:
   ```ruby
   # Cross-account detection
   policy = aws_sqs_queue_policy(:test, {
     queue_url: queue.url,
     policy: JSON.generate({
       Version: "2012-10-17",
       Statement: [{
         Effect: "Allow",
         Principal: { AWS: "arn:aws:iam::123456789012:root" },
         Action: "sqs:*",
         Resource: "*"
       }]
     })
   })
   
   expect(policy.computed.allows_cross_account).to be true
   ```

## Integration Patterns

### With SNS Subscriptions
```ruby
# Create topic and queue
topic = aws_sns_topic(:events, { name: "events" })
queue = aws_sqs_queue(:subscriber, { name: "event-subscriber" })

# Allow SNS to deliver messages
policy = aws_sqs_queue_policy(:sns_delivery, {
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

# Create subscription
aws_sns_subscription(:queue_sub, {
  topic_arn: topic.arn,
  protocol: "sqs",
  endpoint: queue.arn
})
```

### With S3 Events
```ruby
bucket = aws_s3_bucket(:data, { name: "data-bucket" })
queue = aws_sqs_queue(:processor, { name: "s3-event-processor" })

# Allow S3 to send events
aws_sqs_queue_policy(:s3_events, {
  queue_url: queue.url,
  policy: JSON.generate({
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Principal: { Service: "s3.amazonaws.com" },
      Action: "sqs:SendMessage",
      Resource: "*",
      Condition: {
        ArnLike: {
          "aws:SourceArn": bucket.arn
        }
      }
    }]
  })
})
```

## Security Best Practices

1. **Principle of Least Privilege**:
   - Grant only required actions
   - Use specific principals, not wildcards
   - Add conditions when possible

2. **Deny Statements**:
   - Use deny to enforce security boundaries
   - Deny takes precedence over allow
   - Useful for preventing accidental exposure

3. **Condition Keys**:
   - Use `aws:SourceArn` for service principals
   - Use `aws:SecureTransport` to require HTTPS
   - Use `aws:SourceIp` for IP restrictions

4. **Regular Reviews**:
   - Use computed properties for auditing
   - Check for public access
   - Verify cross-account permissions

## Common Pitfalls

1. **Resource Field**: Always use "*" for queue policies
2. **Service Principals**: Must include conditions for security
3. **Policy Size**: Maximum 8KB for queue policies
4. **Principal Formats**: Can be string, array, or object

## Monitoring Integration

Use computed properties for monitoring:
```ruby
policy = aws_sqs_queue_policy(:queue_policy, {
  queue_url: queue.url,
  policy: policy_json
})

# Create alarms based on policy analysis
if policy.computed.allows_public_access
  # Alert on public access
end

if policy.computed.allows_cross_account
  # Log cross-account access
end
```