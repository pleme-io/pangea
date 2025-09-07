# AWS S3 Bucket Website Configuration Implementation

## Overview

The `aws_s3_bucket_website_configuration` resource provides type-safe S3 static website hosting and redirect management with comprehensive validation and terraform synthesis. This implementation supports both website hosting mode and redirect-all mode with advanced routing capabilities.

## Architecture

### Type Safety Hierarchy

```
S3BucketWebsiteConfigurationAttributes (Top Level)
├── WebsiteIndexDocument (Required for hosting mode)
├── WebsiteErrorDocument (Optional)
├── WebsiteRedirectAllRequestsTo (Alternative mode)
└── WebsiteRoutingRule[] (0-50 rules)
    ├── WebsiteRoutingRuleCondition (Optional)
    │   ├── http_error_code_returned_equals (HTTP error matching)
    │   └── key_prefix_equals (URL prefix matching)
    └── WebsiteRoutingRuleRedirect (Required)
        ├── host_name (Target hostname)
        ├── protocol (http/https)
        ├── http_redirect_code (301/302/303/307/308)
        ├── replace_key_prefix_with (Prefix replacement)
        └── replace_key_with (Full key replacement)
```

### Key Components

1. **S3BucketWebsiteConfigurationAttributes**: Root configuration with mode validation
2. **WebsiteIndexDocument**: Index document configuration with common file validation
3. **WebsiteErrorDocument**: Error document configuration with path validation
4. **WebsiteRedirectAllRequestsTo**: Domain redirect configuration with protocol validation
5. **WebsiteRoutingRule**: Advanced routing with condition-based redirects
6. **Validation System**: Comprehensive business rule enforcement

## Implementation Details

### Configuration Mode Validation

**Mutual Exclusivity**:
- Website hosting mode: `index_document` + optional `error_document` + optional `routing_rule`
- Redirect-all mode: `redirect_all_requests_to` only
- Cannot combine modes within single configuration

**Mode Detection Logic**:
```ruby
has_website_config = attrs.index_document || attrs.error_document || attrs.routing_rule
has_redirect_all = attrs.redirect_all_requests_to

if has_website_config && has_redirect_all
  raise Dry::Struct::Error, "Cannot specify both hosting and redirect modes"
end
```

### Routing Rule Architecture

**Condition Types**:
- HTTP Error Code: Match specific HTTP response codes (404, 403, etc.)
- Key Prefix: Match URL path prefixes ("api/", "old-blog/", etc.)
- Combined: Both conditions must match (AND logic)

**Redirect Types**:
- Host redirect: Change domain/hostname
- Protocol redirect: Change HTTP/HTTPS
- Key prefix replacement: Change URL path prefix
- Full key replacement: Change entire URL path
- HTTP code specification: Control redirect type (permanent vs temporary)

### Validation Strategy

**Key Format Validation**:
- Keys cannot start with '/' (S3 requirement)
- Index document suffix validation (common patterns)
- Error document key validation (HTML file recommendations)

**Redirect Validation**:
- HTTP redirect code enum validation (301, 302, 303, 307, 308)
- Hostname format validation (RFC compliant)
- Protocol security warnings (HTTP vs HTTPS)
- Key replacement conflict detection

**Routing Rule Validation**:
- Maximum 50 rules per configuration
- At least one condition required per rule
- Cannot combine prefix and full key replacement
- HTTP error code format validation (1XX-5XX)

### Terraform Synthesis

The resource generates flexible Terraform website configurations:

```ruby
resource(:aws_s3_bucket_website_configuration, name) do
  bucket attrs.bucket
  
  # Website hosting mode
  if attrs.index_document
    index_document do
      suffix attrs.index_document.suffix
    end
  end
  
  # Redirect all mode
  if attrs.redirect_all_requests_to
    redirect_all_requests_to do
      host_name attrs.redirect_all_requests_to.host_name
      protocol attrs.redirect_all_requests_to.protocol if attrs.redirect_all_requests_to.protocol
    end
  end
  
  # Advanced routing rules
  attrs.routing_rule&.each do |rule|
    routing_rule do
      condition do
        # Conditional synthesis based on rule type
      end if rule.condition
      
      redirect do
        # Flexible redirect synthesis
      end
    end
  end
end
```

### Computed Properties

The resource provides comprehensive website analytics:

- `hosting_mode`: Configuration mode ("website_hosting" or "redirect_all")
- `has_error_document`: Boolean error document presence
- `has_routing_rules`: Boolean routing rules presence
- `routing_rules_count`: Total routing rules count
- `*_rules_count`: Categorized rule counts (error code, prefix, redirect type)
- `index_document_suffix`: Active index document filename
- `error_document_key`: Active error document path
- `redirect_target_*`: Redirect destination information

## Helper Methods System

### Document-Level Helpers
```ruby
# Index document helpers
index_doc.html_file?              # Check if HTML file
index_doc.common_index_file?      # Check if common index name
index_doc.filename                # Extract filename

# Error document helpers
error_doc.html_file?              # Check if HTML file
error_doc.in_subdirectory?        # Check if in subdirectory
error_doc.filename                # Extract filename
error_doc.directory               # Extract directory path
```

### Redirect-All Helpers
```ruby
redirect_all.uses_https?          # Check HTTPS usage
redirect_all.uses_http?           # Check HTTP usage
redirect_all.same_protocol?       # Check protocol preservation
redirect_all.localhost?           # Check development hostname
redirect_all.target_url(path)     # Generate target URL
```

### Routing Rule Helpers
```ruby
# Condition helpers
condition.matches_error_code?     # Has error code condition
condition.matches_key_prefix?     # Has prefix condition
condition.error_code              # Get error code as integer
condition.client_error?           # Check 4XX error
condition.server_error?           # Check 5XX error

# Redirect helpers
redirect.permanent_redirect?      # Check 301 redirect
redirect.temporary_redirect?      # Check 302/307/308 redirect
redirect.replaces_key_prefix?     # Check prefix replacement
redirect.replaces_entire_key?     # Check full key replacement
redirect.changes_host?            # Check hostname change
redirect.changes_protocol?        # Check protocol change

# Rule-level helpers
rule.has_condition?               # Check condition presence
rule.unconditional?               # Check unconditional rule
rule.error_code_rule?            # Check error-based rule
rule.prefix_rule?                 # Check prefix-based rule
```

### Configuration-Level Helpers
```ruby
attrs.website_hosting_mode?       # Check hosting mode
attrs.redirect_all_mode?          # Check redirect mode
attrs.has_error_document?         # Check error document
attrs.has_routing_rules?          # Check routing rules
attrs.routing_rules_count         # Total rules count

# Rule categorization
attrs.unconditional_routing_rules # Rules without conditions
attrs.error_code_routing_rules    # Rules matching error codes
attrs.prefix_routing_rules        # Rules matching prefixes
attrs.permanent_redirect_rules    # 301 redirect rules
attrs.temporary_redirect_rules    # 302/307/308 redirect rules
```

## Security Considerations

### Protocol Security
- HTTPS enforcement recommendations
- HTTP warnings for production hostnames
- Localhost detection for development configurations

### Redirect Security
- Host validation to prevent open redirects
- Protocol downgrade warnings
- Hostname format validation

### Path Security
- Key format validation (no leading slashes)
- Path traversal prevention
- Filename extension recommendations

## Performance Optimization

### Routing Rule Performance
- Order rules by specificity (most specific first)
- Minimize unconditional rules
- Use prefix matching for performance
- Combine similar rules when possible

### Caching Considerations
- 301 redirects are cached by browsers
- 302 redirects are not cached
- Choose redirect codes carefully

### CloudFront Integration
- Website endpoint as origin domain
- SPA-friendly error document configuration
- Cache behavior optimization

## Common Patterns

### Single Page Application (SPA)
```ruby
# Route all 404s to index.html for client-side routing
error_document: { key: "index.html" },
routing_rule: [{
  condition: { http_error_code_returned_equals: "404" },
  redirect: { replace_key_with: "index.html" }
}]
```

### API Migration
```ruby
# Redirect API calls to new domain
routing_rule: [{
  condition: { key_prefix_equals: "api/" },
  redirect: {
    host_name: "api.newdomain.com",
    protocol: "https",
    http_redirect_code: "301"
  }
}]
```

### Domain Migration
```ruby
# Redirect entire domain
redirect_all_requests_to: {
  host_name: "newdomain.com",
  protocol: "https"
}
```

## Error Handling

### Validation Errors
- Mode conflicts: "Cannot specify both website hosting and redirect_all_requests_to"
- Missing index: "index_document is required when using website hosting"
- Key format: "Key should not start with '/'"
- Redirect conflicts: "Cannot specify both replace_key_prefix_with and replace_key_with"
- HTTP codes: "Invalid HTTP redirect code. Use 301, 302, 303, 307, or 308"

### Security Warnings
- Protocol warnings: "Using HTTP for production hostname may be insecure"
- File warnings: "Error document doesn't appear to be HTML file"
- Index warnings: "Index document suffix is not common index file name"

## Integration Patterns

### Template Usage
```ruby
template :static_website do
  provider :aws do
    region "us-east-1"
  end
  
  # Create S3 bucket
  bucket_ref = aws_s3_bucket(:site_bucket, {
    bucket: "my-static-site"
  })
  
  # Configure website hosting
  website_ref = aws_s3_bucket_website_configuration(:site_website, {
    bucket: bucket_ref.outputs[:id],
    index_document: { suffix: "index.html" },
    error_document: { key: "error.html" }
  })
  
  # Output website URL
  output :website_url do
    value "https://#{website_ref.outputs[:website_domain]}"
  end
end
```

### Environment-Specific Configuration
```ruby
# Development configuration
dev_config = {
  index_document: { suffix: "index.html" },
  error_document: { key: "dev-error.html" },
  routing_rule: [{
    condition: { key_prefix_equals: "api/" },
    redirect: { host_name: "localhost:3000", protocol: "http" }
  }]
}

# Production configuration  
prod_config = {
  index_document: { suffix: "index.html" },
  error_document: { key: "error.html" },
  routing_rule: [{
    condition: { key_prefix_equals: "api/" },
    redirect: {
      host_name: "api.example.com",
      protocol: "https",
      http_redirect_code: "301"
    }
  }]
}
```

## Testing Strategy

The implementation supports comprehensive testing:

1. **Unit Tests**: Dry-struct validation and helper methods
2. **Mode Tests**: Website hosting vs redirect-all mode validation
3. **Routing Tests**: Complex routing rule logic
4. **Security Tests**: Protocol and hostname validation
5. **Integration Tests**: Terraform synthesis verification
6. **Property Tests**: Computed property accuracy
7. **Error Tests**: Validation error scenarios

This implementation provides enterprise-grade S3 static website hosting with advanced routing capabilities, security validation, and comprehensive analysis tools while supporting both simple static sites and complex single-page applications.