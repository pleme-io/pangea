# AWS S3 Bucket Resource Implementation

## Overview

The `aws_s3_bucket` resource function provides a type-safe interface for creating and configuring AWS S3 buckets with comprehensive feature support including versioning, encryption, lifecycle management, CORS, website hosting, and access controls.

## Implementation Details

### Type Safety

The implementation uses `dry-struct` for runtime validation and type safety:

- **S3BucketAttributes**: Main attributes class with comprehensive S3 bucket configuration options
- **Nested Schemas**: Complex configurations (encryption, lifecycle, CORS) use nested dry-struct schemas
- **Enum Types**: String enums for ACL types, storage classes, encryption algorithms, etc.
- **Custom Validation**: Business rule validation (e.g., KMS key required for KMS encryption)

### Resource Function

```ruby
def aws_s3_bucket(name, attributes = {})
  # 1. Validate attributes using dry-struct
  bucket_attrs = S3BucketAttributes.new(attributes)
  
  # 2. Generate main bucket resource
  resource(:aws_s3_bucket, name) do
    # Configure all bucket properties
  end
  
  # 3. Create public access block if configured (separate resource)
  if bucket_attrs.public_access_block_configuration.any?
    resource(:aws_s3_bucket_public_access_block, "#{name}_public_access_block") do
      # Configure public access restrictions
    end
  end
  
  # 4. Return ResourceReference with outputs and computed properties
end
```

### Key Features

1. **Encryption Support**
   - Default AES256 encryption
   - KMS encryption with custom key support
   - Bucket key optimization for KMS

2. **Lifecycle Management**
   - Transition rules to different storage classes
   - Expiration rules for current and noncurrent versions
   - Tag-based lifecycle rules

3. **Access Control**
   - ACL support (private by default)
   - Bucket policies via JSON string
   - Public access block configuration (separate resource)

4. **Website Hosting**
   - Static website configuration
   - Index and error documents
   - Redirect rules

5. **Advanced Features**
   - Versioning with MFA delete support
   - Object lock for compliance
   - CORS configuration
   - Access logging to another bucket

### Computed Properties

The ResourceReference includes computed properties for easy access:

- `encryption_enabled`: Whether encryption is configured
- `kms_encrypted`: Whether using KMS encryption
- `versioning_enabled`: Whether versioning is enabled
- `website_enabled`: Whether website hosting is configured
- `lifecycle_rules_count`: Number of lifecycle rules
- `public_access_blocked`: Whether all public access is blocked

### Validation Rules

1. **KMS Encryption**: Requires `kms_master_key_id` when using `aws:kms` algorithm
2. **Lifecycle Rules**: Must have at least one action (transition/expiration)
3. **Object Lock**: Requires versioning to be enabled
4. **Website Config**: Cannot specify both redirect and index/error documents
5. **Subnet Count**: Validates CIDR block sizes for practical use

### Design Decisions

1. **Separate Public Access Block**: Created as a separate resource (`aws_s3_bucket_public_access_block`) to match Terraform's resource model
2. **Default Encryption**: AES256 encryption enabled by default for security best practices
3. **Flexible Lifecycle Rules**: Array of rules allows multiple lifecycle configurations
4. **Policy as String**: Bucket policies are passed as JSON strings to maintain flexibility

### Integration with Terraform Synthesizer

The function uses terraform-synthesizer's DSL to generate proper Terraform JSON:

```ruby
resource(:aws_s3_bucket, name) do
  # Properties are set using the DSL
  bucket bucket_attrs.bucket if bucket_attrs.bucket
  acl bucket_attrs.acl
  
  # Nested blocks for complex configurations
  versioning do
    enabled bucket_attrs.versioning[:enabled]
  end
end
```

### Error Handling

- Type validation errors from dry-struct
- Custom validation errors for business rules
- Clear error messages indicating the specific issue

### Testing Considerations

When testing S3 bucket resources:

1. Verify encryption is properly configured
2. Test lifecycle rules generate correct Terraform
3. Ensure public access block is created when configured
4. Validate website endpoint outputs are available
5. Check computed properties reflect actual configuration

### Performance Notes

- Validation happens once during attribute creation
- Computed properties are calculated on-demand
- No external API calls during resource creation

### Security Best Practices

1. Private ACL by default
2. Encryption enabled by default (AES256)
3. Public access block configuration available
4. Support for bucket policies for fine-grained access control
5. Object lock support for compliance requirements