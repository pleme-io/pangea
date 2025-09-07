# AWS API Gateway Method Implementation

## Overview

The `aws_api_gateway_method` resource implements type-safe creation of HTTP methods on API Gateway resources. Methods define the HTTP verbs (GET, POST, etc.) that clients can use to interact with your API endpoints.

## Implementation Details

### Type System

The implementation uses `dry-struct` for runtime validation with the following key validations:

1. **HTTP Method Validation**: Enforces valid HTTP methods including ANY for wildcard
2. **Authorization Validation**: 
   - Requires `authorizer_id` for CUSTOM and COGNITO_USER_POOLS
   - Restricts `authorization_scopes` to COGNITO_USER_POOLS only
3. **Request Parameter Validation**: 
   - Validates parameter name format: `method.request.{location}.{name}`
   - Ensures valid locations (path, querystring, header, etc.)
4. **Content Type Validation**: Validates MIME type format for request models

### Authorization Types

The resource supports four authorization types:

- **NONE**: No authorization (public access)
- **AWS_IAM**: AWS signature version 4 authorization
- **CUSTOM**: Lambda-based custom authorizer
- **COGNITO_USER_POOLS**: Cognito user pool authorization with OAuth scopes

### Request Configuration

Methods can define:

1. **Request Parameters**: Expected parameters and whether they're required
2. **Request Models**: JSON schema models for request body validation
3. **Request Validators**: Validate body, parameters, or both

### Computed Properties

The type class provides helper properties:

- `requires_authorization?`: Check if method needs auth
- `is_cognito_authorized?`: Check for Cognito auth
- `is_iam_authorized?`: Check for IAM auth
- `has_request_validation?`: Check if validation is configured
- `cors_enabled?`: Check if method handles CORS (OPTIONS)

## Design Patterns

### RESTful Method Mapping

Standard REST conventions:

```
GET     /resources     - List collection
POST    /resources     - Create new item
GET     /resources/{id} - Get specific item
PUT     /resources/{id} - Update item
DELETE  /resources/{id} - Delete item
OPTIONS /resources     - CORS preflight
```

### Authorization Strategies

1. **Public Endpoints**: Health checks, documentation
2. **API Key Protected**: Rate-limited public access
3. **IAM Protected**: Service-to-service communication
4. **User Pool Protected**: End-user authentication
5. **Custom Auth**: Complex authorization logic

### Request Validation Patterns

1. **Path Parameters**: Always required, extracted from URL
2. **Query Parameters**: Optional filters, pagination
3. **Headers**: Authentication, content negotiation
4. **Body Models**: Structured request validation

## Integration Patterns

### With Lambda Integration

Methods typically integrate with Lambda functions:

```ruby
method -> integration -> lambda_function
```

### With HTTP Integration

Proxy requests to HTTP endpoints:

```ruby
method -> integration -> http_endpoint
```

### With AWS Service Integration

Direct integration with AWS services:

```ruby
method -> integration -> aws_service (S3, DynamoDB, etc.)
```

## Security Considerations

1. **Authorization Layering**: 
   - API-level: API keys
   - Method-level: IAM/Cognito/Custom
   - Integration-level: IAM roles

2. **Request Validation**:
   - Prevent injection attacks
   - Enforce data types
   - Limit payload sizes

3. **CORS Configuration**:
   - OPTIONS methods for preflight
   - Proper header configuration
   - Origin restrictions

## Performance Optimization

1. **Authorization Caching**: Authorizer results are cached
2. **Request Validation**: Early rejection of invalid requests
3. **Method Selection**: Use specific methods vs ANY
4. **Parameter Optimization**: Only require necessary parameters

## Common Patterns

### CRUD Operations

Complete Create, Read, Update, Delete pattern:

```ruby
GET    /items     - List
POST   /items     - Create  
GET    /items/{id} - Read
PUT    /items/{id} - Update
DELETE /items/{id} - Delete
```

### Search Endpoints

```ruby
GET /items/search?q=query&filter=value
```

### Batch Operations

```ruby
POST /batch/items - Process multiple items
```

### Webhook Receivers

```ruby
POST /webhooks/{provider} - Provider-specific webhooks
```

## Request Parameter Helpers

The implementation provides helper methods:

- `build_request_parameter`: Constructs parameter names correctly
- `common_request_parameters`: Pre-built common parameters
- `common_content_types`: Standard MIME types

## Error Handling

Common method-related errors:

1. **Missing Authorizer**: CUSTOM/COGNITO without authorizer_id
2. **Invalid Scopes**: Scopes used with non-Cognito auth
3. **Parameter Format**: Incorrect parameter naming
4. **Content Type**: Invalid MIME type format

## Best Practices

1. **Explicit Methods**: Avoid ANY unless necessary
2. **Consistent Auth**: Same auth type for related endpoints
3. **Parameter Validation**: Validate all inputs
4. **Model Reuse**: Share request/response models
5. **Operation Names**: Meaningful names for SDK generation

## Testing Strategies

1. **Authorization Testing**: Test each auth type
2. **Parameter Testing**: Required vs optional parameters
3. **Content Type Testing**: Multiple content types
4. **Error Testing**: Invalid requests return proper errors

## Monitoring and Debugging

1. **CloudWatch Metrics**: 
   - 4xx/5xx errors per method
   - Latency per method
   - Request count

2. **CloudWatch Logs**:
   - Full request/response logging
   - Authorization failures
   - Validation errors

3. **X-Ray Tracing**:
   - End-to-end request flow
   - Authorization latency
   - Integration performance

## Integration with Other Resources

Methods work with:

- **Integrations**: Define backend connections
- **Integration Responses**: Transform responses
- **Method Responses**: Define possible responses
- **Models**: Request/response schemas
- **Authorizers**: Custom authorization logic

## Cost Considerations

1. **Request Pricing**: Charged per million requests
2. **Authorization Caching**: Reduces authorizer invocations
3. **Validation**: Cheaper than backend processing
4. **Method Count**: No charge for method definitions

## Future Enhancements

Potential improvements:

1. **Auto-documentation**: Generate from method definitions
2. **Type inference**: Infer models from parameters
3. **Security templates**: Pre-configured auth patterns
4. **Testing helpers**: Generate test requests
5. **SDK generation**: Automatic client SDK creation