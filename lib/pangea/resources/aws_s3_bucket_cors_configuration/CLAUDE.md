# AWS S3 Bucket CORS Configuration Implementation

## Overview

The `aws_s3_bucket_cors_configuration` resource provides type-safe S3 CORS (Cross-Origin Resource Sharing) management with comprehensive security validation and terraform synthesis. This implementation follows Pangea's architecture patterns with dry-struct validation and terraform-synthesizer integration.

## Architecture

### Type Safety Hierarchy

```
S3BucketCorsConfigurationAttributes (Top Level)
├── CorsRule[] (1-100 rules)
│   ├── allowed_methods: String[] (required)
│   ├── allowed_origins: String[] (required)
│   ├── allowed_headers: String[] (optional)
│   ├── expose_headers: String[] (optional)
│   ├── max_age_seconds: Integer (optional)
│   └── id: String (optional)
```

### Key Components

1. **S3BucketCorsConfigurationAttributes**: Root validation and configuration management
2. **CorsRule**: Individual CORS rule with complete HTTP method and origin validation
3. **Security Validation**: Wildcard origin warnings and method restrictions
4. **Cache Management**: Max age validation and cache strategy enforcement
5. **Multi-Rule Coordination**: Cross-rule validation and conflict detection

## Implementation Details

### Validation Strategy

**Rule-Level Validation**:
- Unique rule IDs across all rules (when specified)
- HTTP method enum validation (GET, PUT, POST, DELETE, HEAD)
- Origin pattern validation (wildcard exclusivity)
- Rule count constraints (1-100 rules)

**Security Validation**:
- Wildcard origin warnings with credential-enabling methods
- Max age bounds checking (0-2147483647 seconds)
- Reasonable max age warnings (>7 days)
- Method-origin combination security analysis

**Origin Validation**:
- Wildcard (*) origin exclusivity enforcement
- Protocol validation (HTTPS recommendation)
- Domain pattern validation
- Port number support validation

### Terraform Synthesis

The resource generates clean Terraform CORS rule structures:

```ruby
resource(:aws_s3_bucket_cors_configuration, name) do
  bucket attrs.bucket
  
  attrs.cors_rule.each do |cors_rule|
    cors_rule do
      id cors_rule.id if cors_rule.id
      allowed_methods cors_rule.allowed_methods
      allowed_origins cors_rule.allowed_origins
      allowed_headers cors_rule.allowed_headers if cors_rule.allowed_headers
      expose_headers cors_rule.expose_headers if cors_rule.expose_headers
      max_age_seconds cors_rule.max_age_seconds if cors_rule.max_age_seconds
    end
  end
end
```

### Computed Properties

The resource provides comprehensive CORS analytics:

- `total_rules_count`: Total CORS rules configured
- `wildcard_rules_count`: Rules allowing all origins (*)
- `rules_with_max_age_count`: Rules with cache configuration
- `rules_exposing_headers_count`: Rules exposing response headers
- `max_max_age_seconds`: Highest cache time across rules
- `all_allowed_methods`: All HTTP methods across all rules
- `all_allowed_origins`: All origins across all rules
- `allows_*`: Boolean flags for specific HTTP methods

## Security Architecture

### Origin Security Patterns

**Secure Patterns**:
```ruby
# Production - specific HTTPS origins
allowed_origins: ["https://app.example.com"]

# Multi-domain - explicit trusted domains
allowed_origins: [
  "https://app.example.com",
  "https://admin.example.com"
]
```

**Development Patterns**:
```ruby
# Development - controlled wildcard with warnings
allowed_origins: ["*"] # Generates security warning
```

### Method Security Matrix

| Method | Security Level | Common Use Case |
|--------|---------------|-----------------|
| GET | Low | Asset retrieval, API reads |
| POST | Medium | Form uploads, API creates |
| PUT | High | Direct uploads, API updates |
| DELETE | Critical | Resource deletion |
| HEAD | Low | Metadata queries |

### Header Security Considerations

**Allowed Headers** (Client → S3):
- Minimize to required headers only
- Avoid wildcard (*) in production
- Include authentication headers explicitly

**Exposed Headers** (S3 → Client):
- Expose only necessary response headers
- Common: ETag, Content-Length, x-amz-request-id
- Avoid exposing sensitive AWS metadata

## Helper Methods

### Rule-Level Helpers
```ruby
rule.allows_method?("GET")    # Check if rule allows specific method
rule.allows_origin?(origin)    # Check if rule allows specific origin
rule.allows_all_origins?       # Check if rule uses wildcard origin
rule.has_headers?              # Check if rule specifies allowed headers
rule.exposes_headers?          # Check if rule exposes response headers
rule.has_max_age?              # Check if rule has cache configuration
rule.method_count              # Number of allowed methods
rule.origin_count              # Number of allowed origins
```

### Configuration-Level Helpers
```ruby
attrs.total_rules_count                    # Total rule count
attrs.rules_with_wildcards                 # Rules allowing all origins
attrs.rules_allowing_method("POST")        # Rules allowing specific method
attrs.rules_with_max_age                   # Rules with cache config
attrs.rules_exposing_headers               # Rules exposing headers
attrs.max_max_age                          # Highest cache time
attrs.all_allowed_methods                  # All methods across rules
attrs.all_allowed_origins                  # All origins across rules
```

## Performance Considerations

### Cache Strategy
- **Development**: Low max_age (300-3600s) for frequent changes
- **Staging**: Medium max_age (3600-14400s) for testing stability
- **Production**: High max_age (3600-86400s) for performance

### Rule Optimization
- Combine similar rules when possible
- Order rules by specificity (most specific first)
- Minimize wildcard usage for security and performance
- Use specific headers rather than wildcards

### Browser Cache Behavior
- Preflight requests cached based on max_age_seconds
- Longer cache times reduce preflight overhead
- Balance cache duration with configuration change frequency

## Error Handling

### Validation Errors
- Rule ID conflicts: "CORS rule IDs must be unique when specified"
- Origin conflicts: "When using wildcard '*' origin, it must be the only allowed origin"
- Method validation: Enum constraint errors for invalid HTTP methods
- Rule count limits: Array constraint errors for >100 rules

### Security Warnings
- Wildcard origin warnings: "Allowing all origins (*) with POST method may be insecure"
- High max age warnings: "max_age_seconds very high (>7 days). Consider lower value"

### Runtime Safety
- Enum validation for HTTP methods
- Array constraint validation (1-100 rules)
- Integer bounds checking for max_age_seconds
- String validation for origins and headers

## Integration Patterns

### Template Usage
```ruby
template :s3_cors do
  provider :aws do
    region "us-east-1"
  end
  
  # Create S3 bucket
  bucket_ref = aws_s3_bucket(:app_bucket, {
    bucket: "my-app-bucket"
  })
  
  # Apply CORS configuration
  cors_ref = aws_s3_bucket_cors_configuration(:app_cors, {
    bucket: bucket_ref.outputs[:id],
    cors_rule: [
      {
        allowed_methods: ["GET", "POST"],
        allowed_origins: ["https://app.example.com"],
        max_age_seconds: 3600
      }
    ]
  })
end
```

### Environment-Specific Patterns
```ruby
# Production - restrictive CORS
cors_production = {
  allowed_origins: ["https://app.example.com"],
  allowed_methods: ["GET"],
  max_age_seconds: 86400
}

# Development - permissive CORS
cors_development = {
  allowed_origins: ["*"],
  allowed_methods: ["GET", "POST", "PUT", "DELETE"],
  allowed_headers: ["*"],
  max_age_seconds: 300
}
```

### Cross-Resource References
```ruby
# Reference CORS configuration in monitoring
output :cors_security_summary do
  value {
    bucket: cors_ref.outputs[:bucket],
    wildcard_rules: cors_ref.computed_properties[:wildcard_rules_count],
    total_rules: cors_ref.computed_properties[:total_rules_count],
    allows_delete: cors_ref.computed_properties[:allows_delete]
  }
end
```

## Testing Strategy

The implementation supports comprehensive testing:

1. **Unit Tests**: Dry-struct validation and helper methods
2. **Security Tests**: Wildcard origin and method combination validation
3. **Integration Tests**: Terraform synthesis verification
4. **Property Tests**: Computed property accuracy
5. **Error Tests**: Validation error scenarios
6. **Performance Tests**: Large rule set handling

This implementation provides enterprise-grade S3 CORS management with security-first validation and comprehensive analysis capabilities while maintaining simplicity for common web application use cases.