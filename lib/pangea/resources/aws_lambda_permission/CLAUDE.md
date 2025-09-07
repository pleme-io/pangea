# AWS Lambda Permission Resource Implementation

## Overview

The `aws_lambda_permission` resource implements a type-safe wrapper around Terraform's AWS Lambda permission resource, managing who can invoke Lambda functions and under what conditions.

## Implementation Details

### Type System (types.rb)

The `LambdaPermissionAttributes` class enforces:

1. **Action validation**: Enum of valid Lambda actions
2. **Principal validation**: Service principals, account IDs, or IAM ARNs
3. **Statement ID format**: Alphanumeric with hyphens and underscores
4. **Source ARN format**: Valid AWS ARN when provided
5. **Service principal validation**: Known AWS services only
6. **Function URL auth type**: Only with ALB principal

### Resource Synthesis (resource.rb)

The resource function:
1. Validates all inputs using dry-struct
2. Generates unique statement IDs if not provided
3. Conditionally includes optional attributes
4. Returns ResourceReference with computed properties

### Key Features

#### Principal Types
- **Service Principals**: apigateway.amazonaws.com, s3.amazonaws.com, etc.
- **Account IDs**: 12-digit AWS account numbers
- **IAM ARNs**: Specific roles or users in other accounts

#### Security Controls
- **Source ARN**: Restricts invocation to specific resources
- **Source Account**: Additional security for S3 triggers
- **Qualifier**: Version or alias-specific permissions

## Validation Rules

### Principal Validation

```ruby
# Service principal
principal: "apigateway.amazonaws.com"

# AWS account ID
principal: "123456789012"

# IAM role ARN
principal: "arn:aws:iam::123456789012:role/MyRole"
```

### Valid Service Principals
- apigateway.amazonaws.com
- events.amazonaws.com (EventBridge)
- s3.amazonaws.com
- sns.amazonaws.com
- sqs.amazonaws.com
- logs.amazonaws.com
- cognito-idp.amazonaws.com
- elasticloadbalancing.amazonaws.com
- iot.amazonaws.com
- lex.amazonaws.com
- states.amazonaws.com (Step Functions)
- kafka.amazonaws.com
- config.amazonaws.com
- backup.amazonaws.com
- datasync.amazonaws.com
- mediaconvert.amazonaws.com

## Common Patterns

### API Gateway Pattern
```ruby
aws_lambda_permission(:api_invoke, {
  action: "lambda:InvokeFunction",
  function_name: lambda_function.function_name,
  principal: "apigateway.amazonaws.com",
  source_arn: "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
})
```

### S3 Trigger Pattern
```ruby
aws_lambda_permission(:s3_invoke, {
  action: "lambda:InvokeFunction",
  function_name: lambda_function.arn,
  principal: "s3.amazonaws.com",
  source_arn: bucket.arn,
  source_account: "123456789012"
})
```

### EventBridge Rule Pattern
```ruby
aws_lambda_permission(:event_invoke, {
  action: "lambda:InvokeFunction",
  function_name: lambda_function.function_name,
  principal: "events.amazonaws.com",
  source_arn: event_rule.arn
})
```

### Cross-Account Pattern
```ruby
aws_lambda_permission(:cross_account, {
  action: "lambda:InvokeFunction",
  function_name: lambda_function.function_name,
  principal: "987654321098",
  statement_id: "AllowPartnerAccount"
})
```

## Security Considerations

### Confused Deputy Prevention
Always specify `source_arn` when granting permissions to AWS services:

```ruby
# Good - Restricted to specific resource
aws_lambda_permission(:s3_secure, {
  action: "lambda:InvokeFunction",
  function_name: function.arn,
  principal: "s3.amazonaws.com",
  source_arn: "arn:aws:s3:::my-bucket"
})

# Bad - Any S3 bucket can invoke
aws_lambda_permission(:s3_insecure, {
  action: "lambda:InvokeFunction",
  function_name: function.arn,
  principal: "s3.amazonaws.com"
  # Missing source_arn!
})
```

### Least Privilege Actions
Use specific actions instead of wildcards:

```ruby
# Good - Specific action
action: "lambda:InvokeFunction"

# Bad - Too permissive
action: "lambda:*"
```

### Source Account for S3
S3 requires both source_arn and source_account for maximum security:

```ruby
aws_lambda_permission(:s3_secure, {
  action: "lambda:InvokeFunction",
  function_name: function.arn,
  principal: "s3.amazonaws.com",
  source_arn: bucket.arn,
  source_account: "123456789012"  # Required for S3
})
```

## Integration Examples

### With API Gateway
```ruby
# REST API integration
aws_api_gateway_integration(:lambda_integration, {
  rest_api_id: api.id,
  resource_id: resource.id,
  http_method: "POST",
  integration_http_method: "POST",
  type: "AWS_PROXY",
  uri: lambda_function.invoke_arn
})

# Corresponding permission
aws_lambda_permission(:api_permission, {
  action: "lambda:InvokeFunction",
  function_name: lambda_function.function_name,
  principal: "apigateway.amazonaws.com",
  source_arn: "${api.execution_arn}/*/*"
})
```

### With S3 Bucket Notification
```ruby
# S3 bucket notification
aws_s3_bucket_notification(:upload_trigger, {
  bucket: bucket.id,
  lambda_function: [{
    lambda_function_arn: lambda_function.arn,
    events: ["s3:ObjectCreated:*"],
    filter_prefix: "uploads/"
  }]
})

# Corresponding permission
aws_lambda_permission(:s3_permission, {
  action: "lambda:InvokeFunction",
  function_name: lambda_function.arn,
  principal: "s3.amazonaws.com",
  source_arn: bucket.arn
})
```

### With EventBridge
```ruby
# EventBridge rule target
aws_cloudwatch_event_target(:lambda_target, {
  rule: event_rule.name,
  arn: lambda_function.arn
})

# Corresponding permission
aws_lambda_permission(:event_permission, {
  action: "lambda:InvokeFunction",
  function_name: lambda_function.function_name,
  principal: "events.amazonaws.com",
  source_arn: event_rule.arn
})
```

## Statement ID Management

### Auto-Generated IDs
If not specified, statement IDs are auto-generated with timestamp:
```ruby
statement_id: "AllowExecutionFrom#{Time.now.to_i}"
```

### Custom IDs
For better management, use descriptive custom IDs:
```ruby
statement_id: "AllowAPIGatewayProdInvoke"
statement_id: "AllowS3BucketUploadsTrigger"
statement_id: "AllowEventBridgeScheduledJob"
```

## Troubleshooting

### Common Issues

1. **Missing Permissions**: Function not triggering
   - Check statement_id uniqueness
   - Verify source_arn format
   - Ensure principal is correct

2. **Access Denied**: Despite having permission
   - Check function qualifier matches
   - Verify source account for S3
   - Ensure IAM execution role has necessary permissions

3. **Duplicate Statement ID**: Terraform apply fails
   - Use unique statement_id values
   - Consider including resource names in IDs

## Migration Guide

### From Inline Permissions
```ruby
# Before: Inline permission
resource :aws_lambda_permission, :allow_api do
  action "lambda:InvokeFunction"
  function_name lambda_function_name
  principal "apigateway.amazonaws.com"
end

# After: Type-safe function
aws_lambda_permission(:allow_api, {
  action: "lambda:InvokeFunction",
  function_name: lambda_function.function_name,
  principal: "apigateway.amazonaws.com",
  source_arn: api_execution_arn
})
```