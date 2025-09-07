# AWS API Gateway Integration Implementation

## Overview

The `aws_api_gateway_integration` resource implements type-safe creation of backend integrations for API Gateway methods. Integrations define how API Gateway connects HTTP methods to backend services like Lambda functions, HTTP endpoints, or AWS services.

## Implementation Details

### Type System

The implementation uses `dry-struct` for runtime validation with comprehensive validation:

1. **Integration Type Validation**: Supports MOCK, HTTP, HTTP_PROXY, AWS, and AWS_PROXY
2. **URI Requirements**: Validates URI is provided for non-MOCK integrations  
3. **HTTP Method Requirements**: Validates integration_http_method for non-proxy integrations
4. **VPC Link Validation**: Requires connection_id when using VPC_LINK connection type
5. **Parameter Mapping Validation**: Ensures proper parameter mapping format
6. **Content Handling Validation**: Validates binary/text conversion options

### Integration Types

The resource supports five integration types:

- **MOCK**: Static responses without backend calls
- **HTTP**: HTTP endpoint with request/response transformation
- **HTTP_PROXY**: Direct HTTP proxy without transformation
- **AWS**: AWS service integration with transformation
- **AWS_PROXY**: Lambda proxy integration (most common for serverless)

### Connection Types

Two connection types are supported:

- **INTERNET**: Standard internet-based connections
- **VPC_LINK**: Private connections through VPC Link for internal services

### Request Configuration

Integrations can define:

1. **Request Templates**: Transform incoming requests (VTL mapping)
2. **Request Parameters**: Map method parameters to integration parameters
3. **Passthrough Behavior**: Control template matching behavior
4. **Content Handling**: Binary content conversion

### Computed Properties

The type class provides extensive helper properties:

- `is_proxy_integration?`: Check for proxy-style integration
- `is_lambda_integration?`: Detect Lambda function backends
- `is_http_integration?`: Identify HTTP backends
- `is_aws_service_integration?`: Detect AWS service backends
- `uses_vpc_link?`: Check for VPC connectivity
- `has_caching?`: Determine if caching is configured
- `requires_iam_role?`: Check if IAM credentials needed

## Integration Patterns

### Lambda Proxy Integration (Most Common)

The simplest pattern for Lambda functions:

```ruby
aws_api_gateway_integration(:lambda_proxy, {
  rest_api_id: api.id,
  resource_id: resource.id,
  http_method: method.http_method,
  type: 'AWS_PROXY',
  integration_http_method: 'POST',
  uri: lambda_function.invoke_arn,
  credentials: lambda_role.arn
})
```

### Lambda Custom Integration

For custom request/response transformation:

```ruby
aws_api_gateway_integration(:lambda_custom, {
  rest_api_id: api.id,
  resource_id: resource.id,
  http_method: method.http_method,
  type: 'AWS',
  integration_http_method: 'POST',
  uri: lambda_function.invoke_arn,
  request_templates: {
    'application/json' => vtl_template
  }
})
```

### HTTP Proxy Integration

Direct proxy to HTTP backends:

```ruby
aws_api_gateway_integration(:http_proxy, {
  rest_api_id: api.id,
  resource_id: resource.id,
  http_method: method.http_method,
  type: 'HTTP_PROXY',
  integration_http_method: 'ANY',
  uri: 'https://backend.example.com/{proxy}',
  connection_type: 'VPC_LINK',
  connection_id: vpc_link.id
})
```

### Mock Integration

For testing and static responses:

```ruby
aws_api_gateway_integration(:mock, {
  rest_api_id: api.id,
  resource_id: resource.id,
  http_method: method.http_method,
  type: 'MOCK',
  request_templates: {
    'application/json' => '{"statusCode": 200}'
  }
})
```

### AWS Service Integration

Direct integration with AWS services:

```ruby
aws_api_gateway_integration(:dynamodb, {
  rest_api_id: api.id,
  resource_id: resource.id,
  http_method: method.http_method,
  type: 'AWS',
  integration_http_method: 'POST',
  uri: 'arn:aws:apigateway:region:dynamodb:action/GetItem',
  credentials: dynamodb_role.arn,
  request_templates: {
    'application/json' => dynamodb_template
  }
})
```

## Helper Methods

The implementation provides static helper methods for common patterns:

- `lambda_proxy_integration`: Pre-configured Lambda proxy setup
- `lambda_integration`: Lambda with custom templates
- `http_proxy_integration`: HTTP proxy configuration
- `http_integration`: HTTP with custom templates
- `mock_integration`: Mock response configuration
- `s3_integration`: S3 service integration
- `dynamodb_integration`: DynamoDB service integration

## Security Considerations

1. **IAM Roles**: 
   - Lambda integrations need invoke permissions
   - AWS service integrations need service-specific permissions
   - Use least-privilege principles

2. **VPC Connectivity**:
   - VPC Links for private backend access
   - Security group configuration
   - Network ACL considerations

3. **Request Validation**:
   - Parameter sanitization in templates
   - Input validation before backend calls
   - Prevent injection attacks

## Performance Optimization

1. **Caching Strategy**:
   - Cache key parameters for consistent caching
   - Cache namespace for isolation
   - TTL configuration at stage level

2. **Connection Pooling**:
   - HTTP(S) connection reuse
   - VPC Link connection management
   - Timeout optimization

3. **Payload Optimization**:
   - Request template optimization
   - Binary content handling
   - Compression configuration

## Error Handling

Common integration errors and solutions:

1. **Backend Unavailable**: Configure retry logic in Lambda
2. **Timeout Issues**: Adjust timeout_milliseconds (max 29 seconds)
3. **Permission Errors**: Verify IAM role permissions
4. **Template Errors**: Validate VTL syntax
5. **Parameter Mapping**: Check parameter name formats

## Monitoring and Debugging

1. **CloudWatch Metrics**:
   - Integration latency
   - Backend error rates
   - Cache hit/miss ratios

2. **CloudWatch Logs**:
   - Request/response logging
   - Template execution logs
   - Error details

3. **X-Ray Tracing**:
   - End-to-end request flow
   - Backend service calls
   - Performance bottlenecks

## Content Handling

Binary content handling options:

- **CONVERT_TO_BINARY**: Convert text to binary
- **CONVERT_TO_TEXT**: Convert binary to text
- **Automatic**: Based on content-type headers

## Request Templates

VTL (Velocity Template Language) for request transformation:

```vtl
{
  "httpMethod": "$context.httpMethod",
  "path": "$context.resourcePath",
  "queryString": "$input.params().querystring",
  "headers": "$input.params().header",
  "body": $input.json('$'),
  "requestId": "$context.requestId"
}
```

## Parameter Mapping

Map method parameters to integration parameters:

```ruby
request_parameters: {
  'integration.request.path.id' => 'method.request.path.userId',
  'integration.request.header.Content-Type' => "'application/json'",
  'integration.request.querystring.version' => 'stageVariables.version'
}
```

## Caching Configuration

Enable response caching for improved performance:

```ruby
cache_key_parameters: ['method.request.path.id', 'method.request.querystring.version'],
cache_namespace: 'user-api-v1'
```

## Best Practices

1. **Proxy vs Custom**: Use AWS_PROXY for simplicity, custom for complex transformations
2. **Error Handling**: Implement proper error responses in backend
3. **Security**: Always use IAM roles, never embed credentials
4. **Monitoring**: Enable logging and tracing for troubleshooting
5. **Testing**: Test with various payloads and error conditions

## Integration with Other Resources

Integrations work with:

- **Methods**: Define HTTP method behavior
- **Integration Responses**: Transform backend responses  
- **Method Responses**: Define possible response formats
- **VPC Links**: Private connectivity to backends
- **Lambda Functions**: Serverless backend processing
- **IAM Roles**: Authorization and permissions

## Cost Considerations

1. **Request Pricing**: Charged per million API calls
2. **VPC Link Costs**: Hourly charges for VPC connectivity
3. **Lambda Costs**: Invocation and duration charges
4. **Data Transfer**: Costs for cross-AZ and internet traffic

## Testing Strategies

1. **Unit Testing**: Mock integrations for isolated testing
2. **Integration Testing**: Test with actual backends
3. **Load Testing**: Validate performance under load
4. **Security Testing**: Verify authorization and input validation
5. **Error Testing**: Test timeout and error conditions

## Migration and Versioning

1. **Blue-Green**: Deploy new integrations alongside existing
2. **Canary**: Gradually shift traffic to new integrations
3. **Stage Variables**: Environment-specific configuration
4. **API Versions**: Multiple API versions with different integrations

This implementation provides a comprehensive, type-safe way to configure API Gateway integrations with extensive validation, helper methods, and computed properties for all common integration patterns.