# AWS Lambda Function Resource Implementation

## Overview

The `aws_lambda_function` resource implements a type-safe wrapper around Terraform's AWS Lambda function resource, providing comprehensive validation for serverless function deployments with support for both Zip and container-based deployments.

## Implementation Details

### Type System (types.rb)

The `LambdaFunctionAttributes` class enforces:

1. **Function naming validation**: 1-64 characters, alphanumeric with hyphens and underscores
2. **Runtime validation**: Comprehensive enum of supported Lambda runtimes
3. **Memory constraints**: 128-10240 MB with proper increment validation
4. **Timeout limits**: 1-900 seconds (15 minutes maximum)
5. **Package type consistency**: Ensures code source matches package type
6. **Handler format validation**: Runtime-specific handler format checking
7. **Architecture restrictions**: Single architecture per function
8. **Snap start validation**: Java runtime requirement

### Resource Synthesis (resource.rb)

The resource function:
1. Validates all inputs using dry-struct
2. Conditionally generates Terraform blocks based on package type
3. Handles optional nested configurations (VPC, DLQ, EFS, etc.)
4. Returns comprehensive ResourceReference with outputs

### Key Features

#### Package Type Support
- **Zip**: Traditional deployment with handler and runtime
- **Image**: Container-based deployment with ECR images

#### Advanced Configurations
- **VPC Integration**: Subnet and security group configuration
- **Dead Letter Queue**: Error handling with SQS/SNS
- **EFS Mounting**: File system access for large files
- **Environment Encryption**: KMS key support
- **Code Signing**: Deployment verification
- **Snap Start**: Java cold start optimization
- **Ephemeral Storage**: Up to 10GB temporary storage

#### Monitoring & Observability
- **X-Ray Tracing**: Distributed tracing support
- **CloudWatch Logs**: Structured logging configuration
- **Custom metrics**: Via CloudWatch integration

## Validation Rules

### Runtime-Specific Handler Validation

```ruby
# Python: module.function
handler: "main.lambda_handler"

# Node.js: file.export
handler: "index.handler"

# Java: package.Class::method
handler: "com.example.Handler::handleRequest"

# .NET: Assembly::Type::Method
handler: "MyApp::MyApp.Function::Handler"

# Go: executable name
handler: "main"

# Ruby: file.method
handler: "lambda_function.handler"
```

### Memory Increments
- 128-512 MB: 64 MB increments
- 512+ MB: 1 MB increments

### Architecture Compatibility
- x86_64: All runtimes
- arm64: Not available for all runtime versions

## Common Patterns

### API Backend Pattern
```ruby
aws_lambda_function(:api_handler, {
  function_name: "api-handler",
  runtime: "python3.11",
  handler: "app.handler",
  filename: "api.zip",
  role: execution_role_arn,
  timeout: 30,
  memory_size: 512,
  environment: { variables: { STAGE: "prod" } },
  tracing_config: { mode: "Active" }
})
```

### Event Processing Pattern
```ruby
aws_lambda_function(:event_processor, {
  function_name: "event-processor",
  runtime: "nodejs18.x",
  handler: "index.handler",
  s3_bucket: "deployments",
  s3_key: "event-processor.zip",
  role: execution_role_arn,
  timeout: 300,
  memory_size: 1024,
  dead_letter_config: { target_arn: dlq_arn },
  reserved_concurrent_executions: 100
})
```

### Scheduled Task Pattern
```ruby
aws_lambda_function(:scheduled_job, {
  function_name: "nightly-batch",
  runtime: "python3.11",
  handler: "batch.process",
  filename: "batch.zip",
  role: execution_role_arn,
  timeout: 900,
  memory_size: 3008,
  ephemeral_storage: { size: 5120 }
})
```

### VPC Database Access Pattern
```ruby
aws_lambda_function(:db_sync, {
  function_name: "database-sync",
  runtime: "java17",
  handler: "com.example.DbSync::handle",
  s3_bucket: "jars",
  s3_key: "db-sync.jar",
  role: vpc_execution_role_arn,
  timeout: 120,
  memory_size: 2048,
  vpc_config: {
    subnet_ids: private_subnet_ids,
    security_group_ids: [lambda_sg_id]
  },
  snap_start: { apply_on: "PublishedVersions" }
})
```

## Cost Optimization

### Architecture Selection
- arm64: ~20% cost savings over x86_64
- Supported for most modern runtimes

### Memory Optimization
- Higher memory = higher cost but faster execution
- Find optimal memory/performance balance
- Use AWS Lambda Power Tuning

### Reserved Concurrency
- Prevents runaway costs from traffic spikes
- Ensures capacity for critical functions

## Security Considerations

1. **IAM Role**: Least privilege execution role
2. **Environment Encryption**: KMS key for sensitive variables
3. **VPC Isolation**: Private subnet deployment
4. **Code Signing**: Verify deployment integrity
5. **Dead Letter Queue**: Secure error handling

## Performance Optimization

1. **Snap Start**: Reduce Java cold starts
2. **Provisioned Concurrency**: Eliminate cold starts
3. **Connection Pooling**: Reuse database connections
4. **Layer Usage**: Share common dependencies
5. **ARM Architecture**: Better price/performance

## Integration with Other Resources

### API Gateway
```ruby
aws_api_gateway_integration(:api_integration, {
  rest_api_id: api.id,
  resource_id: resource.id,
  http_method: "POST",
  integration_http_method: "POST",
  type: "AWS_PROXY",
  uri: lambda_function.invoke_arn
})
```

### EventBridge Rule
```ruby
aws_cloudwatch_event_target(:lambda_target, {
  rule: event_rule.name,
  arn: lambda_function.arn,
  target_id: "lambda-target"
})
```

### S3 Trigger
```ruby
aws_s3_bucket_notification(:bucket_notification, {
  bucket: bucket.id,
  lambda_function: [{
    lambda_function_arn: lambda_function.arn,
    events: ["s3:ObjectCreated:*"],
    filter_prefix: "uploads/"
  }]
})
```

## Debugging Tips

1. **CloudWatch Logs**: Check `/aws/lambda/{function-name}`
2. **X-Ray Traces**: Enable active tracing
3. **Dead Letter Queue**: Monitor failed invocations
4. **Metrics**: Monitor duration, errors, throttles
5. **Reserved Concurrency**: Check for throttling

## Migration Guide

### From Inline Code
```ruby
# Before: Inline code
resource :aws_lambda_function, :example do
  filename "function.zip"
  function_name "example"
  role role_arn
  handler "index.handler"
  runtime "nodejs18.x"
end

# After: Type-safe function
aws_lambda_function(:example, {
  function_name: "example",
  filename: "function.zip",
  role: role_arn,
  handler: "index.handler",
  runtime: "nodejs18.x"
})
```

### Adding VPC Configuration
```ruby
# Add VPC config to existing function
aws_lambda_function(:existing, {
  # ... existing config ...
  vpc_config: {
    subnet_ids: [subnet_a.id, subnet_b.id],
    security_group_ids: [lambda_sg.id]
  }
})
```