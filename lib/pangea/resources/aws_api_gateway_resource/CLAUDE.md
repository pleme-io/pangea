# AWS API Gateway Resource Implementation

## Overview

The `aws_api_gateway_resource` resource implements type-safe creation of resources (paths) in API Gateway REST APIs. Resources represent the URL path structure of your API and serve as containers for HTTP methods.

## Implementation Details

### Type System

The implementation uses `dry-struct` for runtime validation with the following key validations:

1. **Path Part Validation**: 
   - No slashes allowed (path hierarchy is built through parent relationships)
   - Must be alphanumeric with hyphens/underscores OR a parameter in brackets
   - Parameters follow format: `{parameterName}` or `{parameterName+}` for greedy

2. **Greedy Parameter Validation**:
   - Greedy parameters (`{proxy+}`) must be the complete path segment
   - Can only appear as the last segment in a path hierarchy

3. **Path Parameter Detection**:
   - Automatically detects if path part is a parameter
   - Provides helper methods for parameter introspection

### Resource Hierarchy

API Gateway resources form a tree structure:

```
/ (root - provided by REST API)
├── /users
│   ├── /{userId}
│   │   ├── /posts
│   │   └── /profile
│   └── /search
├── /products
│   └── /{productId}
└── /admin
    └── /{proxy+}
```

### Computed Properties

The type class provides several computed properties:

- `is_path_parameter?`: Checks if path part is a parameter
- `is_greedy_parameter?`: Checks if parameter is greedy (catches all)
- `parameter_name`: Extracts parameter name without brackets
- `requires_request_validator?`: Indicates if validation is recommended

### Path Building Helpers

Static methods help with path management:

- `common_path_parts`: Dictionary of common path patterns
- `validate_path_hierarchy`: Ensures parent resources exist
- `build_full_path`: Constructs full path from resource hierarchy

## Design Patterns

### RESTful Resource Hierarchy

Standard REST pattern with collections and items:

```ruby
# Collection: /users
# Item: /users/{userId}
# Nested: /users/{userId}/posts
```

### API Versioning Strategies

1. **Path-based versioning**: `/v1/users`, `/v2/users`
2. **Resource-based versioning**: Different resources per version
3. **Proxy-based versioning**: `/{version}/users`

### Microservice Gateway Pattern

Route to different services based on path:

```ruby
# /services/{serviceName}/{proxy+}
# Routes all requests to appropriate microservice
```

## Integration Patterns

### With Methods

Each resource can have multiple HTTP methods:

```ruby
resource = aws_api_gateway_resource(:users, {...})

# Add methods to the resource
aws_api_gateway_method(:get_users, {
  rest_api_id: api.id,
  resource_id: resource.id,
  http_method: "GET"
})
```

### With Integrations

Resources connect methods to backends:

- Lambda functions for compute
- HTTP endpoints for proxying
- AWS services for direct integration
- Mock responses for testing

### With Authorizers

Resources can have method-level authorization:

- IAM authorization
- Cognito user pools
- Custom Lambda authorizers
- API keys

## Performance Considerations

1. **Path Depth**: Deeper paths have slightly higher latency
2. **Parameter Count**: Multiple parameters increase processing
3. **Greedy Parameters**: Add overhead for path matching
4. **Resource Count**: API Gateway has limits on total resources

## Common Patterns

### Health Check Endpoints

```ruby
# Simple: /health
# Detailed: /health/live, /health/ready
```

### Batch Operations

```ruby
# /batch/{operation}
# Allows bulk operations on resources
```

### Search Endpoints

```ruby
# /users/search
# /products/search
# Separate from CRUD operations
```

### Admin Interfaces

```ruby
# /admin/{resource}/{action}
# Segregated admin functionality
```

## Validation Considerations

Path parameters should be validated:

1. **Format Validation**: Ensure IDs match expected format
2. **Existence Validation**: Check if resource exists
3. **Authorization**: Verify access to specific resources
4. **Input Sanitization**: Prevent injection attacks

## Error Handling

Common resource-related errors:

1. **Invalid Path Part**: Contains slashes or invalid characters
2. **Missing Parent**: Parent resource doesn't exist
3. **Duplicate Path**: Same path part at same level
4. **Greedy Misplacement**: Greedy parameter not at end

## Best Practices

1. **Consistent Naming**: Use consistent path naming conventions
2. **Shallow Hierarchies**: Avoid deeply nested paths (>3-4 levels)
3. **Parameter Naming**: Use descriptive parameter names
4. **Resource Grouping**: Group related resources under common parents
5. **Version Early**: Include versioning from the start

## Security Considerations

1. **Path Traversal**: Validate parameters to prevent directory traversal
2. **Information Disclosure**: Don't expose internal IDs in paths
3. **Rate Limiting**: Apply appropriate throttling per resource
4. **Access Control**: Implement proper authorization per resource

## Testing Strategies

1. **Path Resolution**: Test full path construction
2. **Parameter Extraction**: Verify parameter parsing
3. **Hierarchy Validation**: Ensure parent-child relationships
4. **Edge Cases**: Test special characters, empty parameters

## Monitoring and Debugging

1. **CloudWatch Metrics**: Monitor per-resource metrics
2. **Access Logs**: Track resource access patterns
3. **X-Ray Tracing**: Trace requests through resources
4. **Error Rates**: Monitor 4xx/5xx per resource

## Future Enhancements

Potential improvements:

1. **Auto-path generation**: Generate paths from resource names
2. **Path validation rules**: Custom validation per parameter
3. **Resource templates**: Pre-built resource hierarchies
4. **Documentation generation**: Auto-generate from resources
5. **Path conflict detection**: Warn about ambiguous paths