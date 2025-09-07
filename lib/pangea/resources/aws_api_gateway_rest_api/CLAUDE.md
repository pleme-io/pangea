# AWS API Gateway REST API Implementation

## Overview

The `aws_api_gateway_rest_api` resource implements type-safe creation of REST APIs in Amazon API Gateway. This resource serves as the foundation for building RESTful APIs with various endpoint types, security configurations, and integration patterns.

## Implementation Details

### Type System

The implementation uses `dry-struct` for runtime validation with the following key validations:

1. **Name Validation**: Ensures API names contain only alphanumeric characters, hyphens, underscores, and periods
2. **Endpoint Type Validation**: Enforces valid endpoint types (EDGE, REGIONAL, PRIVATE)
3. **VPC Endpoint Validation**: Requires VPC endpoint IDs for PRIVATE APIs
4. **Media Type Validation**: Validates binary media type format (type/subtype)
5. **Compression Size Validation**: Ensures compression threshold is between 0 and 10MB

### Endpoint Types

The resource supports three API endpoint types:

- **EDGE**: CloudFront-distributed for global low latency
- **REGIONAL**: Direct regional endpoint for same-region access
- **PRIVATE**: VPC-only access through VPC endpoints

### Computed Properties

The type class provides several computed properties:

- `is_edge_optimized?`: Checks if API uses CloudFront distribution
- `is_regional?`: Checks if API is regional
- `is_private?`: Checks if API is VPC-private
- `supports_binary_content?`: Checks if binary media types are configured
- `has_custom_domain?`: Checks if custom domain is configured
- `estimated_monthly_cost`: Provides rough cost estimate

### Resource Synthesis

The resource function synthesizes Terraform configuration with:

1. Core API configuration (name, description)
2. Endpoint configuration with type and VPC endpoints
3. Binary media type support for file uploads
4. Security settings (TLS version, resource policy)
5. API Gateway-specific features (compression, API key source)
6. OpenAPI/Swagger body import support

## Design Patterns

### API Type Selection

Choose endpoint type based on use case:

- **EDGE**: Global applications requiring low latency worldwide
- **REGIONAL**: Applications with users in specific regions
- **PRIVATE**: Internal APIs accessed only from within VPC

### Binary Content Handling

For APIs handling file uploads or binary data:

```ruby
binary_media_types: [
  "image/*",           # All image types
  "application/pdf",   # PDFs
  "multipart/form-data" # Form uploads
]
```

### Security Patterns

1. **Resource Policies**: IP-based access control
2. **TLS Version**: Enforce TLS 1.2 minimum
3. **Private APIs**: VPC-only access
4. **API Key Source**: Header vs custom authorizer

## Integration with Other Resources

The REST API resource integrates with:

- `aws_api_gateway_resource`: Define API paths
- `aws_api_gateway_method`: Define HTTP methods
- `aws_api_gateway_deployment`: Deploy API to stages
- `aws_api_gateway_stage`: Configure deployment stages
- `aws_vpc_endpoint`: For private API access

## Performance Considerations

1. **Endpoint Type Impact**:
   - EDGE: CloudFront caching reduces latency globally
   - REGIONAL: Lower latency for same-region access
   - PRIVATE: Highest security, VPC-only access

2. **Compression Settings**:
   - Set appropriate threshold to balance CPU vs bandwidth
   - Typical values: 1KB-10KB for JSON APIs

3. **Binary Media Types**:
   - Only include necessary types to avoid processing overhead
   - Use wildcards carefully (e.g., "image/*")

## Common Issues and Solutions

1. **Private API Access**: Ensure VPC endpoints are created before API
2. **Binary Upload Failures**: Verify binary media types are configured
3. **CORS Issues**: Configure CORS at method level, not API level
4. **Custom Domain**: Requires separate domain and certificate setup

## Testing Considerations

When testing API Gateway REST APIs:

1. Test each endpoint type in appropriate environment
2. Verify binary content handling with actual file uploads
3. Test compression with various payload sizes
4. Validate security policies with different client IPs
5. Test API cloning for version management

## Cost Optimization

1. **Development**: Use REGIONAL to avoid CloudFront charges
2. **Production**: Use EDGE with caching for frequently accessed content
3. **Internal**: Use PRIVATE to avoid internet data transfer charges
4. **Compression**: Enable to reduce data transfer costs

## Monitoring and Observability

The REST API integrates with:

- CloudWatch Logs for request/response logging
- CloudWatch Metrics for performance monitoring
- X-Ray for distributed tracing
- API Gateway dashboard for usage analytics

## Security Best Practices

1. Always use TLS 1.2 minimum
2. Implement resource policies for IP restrictions
3. Use private APIs for internal services
4. Enable CloudWatch Logs for audit trails
5. Regular review of API access patterns

## Future Enhancements

Potential improvements to consider:

1. Automatic OpenAPI generation from resources
2. Built-in throttling configuration
3. Request/response transformation helpers
4. API documentation generation
5. Cost estimation refinements based on usage patterns