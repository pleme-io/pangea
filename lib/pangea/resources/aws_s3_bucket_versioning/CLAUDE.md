# AWS S3 Bucket Versioning Implementation

## Implementation Overview

The `aws_s3_bucket_versioning` resource provides type-safe S3 bucket versioning configuration with comprehensive validation and state management.

## Architecture

```
S3BucketVersioningAttributes (dry-struct)
    ↓ validates
Versioning Configuration
    ↓ synthesizes
aws_s3_bucket_versioning (terraform)
    ↓ returns
ResourceReference with versioning state
```

## Type Safety

### Attributes Structure
- **bucket**: Required string bucket name
- **versioning_configuration**: Required hash with status and optional MFA delete
- **expected_bucket_owner**: Optional string for multi-account scenarios

### Versioning Configuration Schema
```ruby
versioning_configuration: Resources::Types::Hash.schema(
  status: Resources::Types::String.enum('Enabled', 'Suspended'),
  mfa_delete?: Resources::Types::String.enum('Enabled', 'Disabled').optional
)
```

### Validation Logic
```ruby
def self.new(attributes = {})
  unless attrs.versioning_configuration
    raise Dry::Struct::Error, "versioning_configuration is required"
  end
end
```

## State Management

### Versioning States
- **Enabled**: New uploads create versions, existing versions preserved
- **Suspended**: New uploads overwrite, existing versions preserved

### MFA Delete States
- **Enabled**: Requires MFA to delete versions or suspend versioning
- **Disabled**: Standard delete permissions apply
- **Not Configured**: MFA delete not specified

## Helper Methods

### State Detection
```ruby
def versioning_enabled?
  versioning_configuration[:status] == 'Enabled'
end

def versioning_suspended?
  versioning_configuration[:status] == 'Suspended'
end

def mfa_delete_enabled?
  versioning_configuration[:mfa_delete] == 'Enabled'
end
```

### Configuration Analysis
```ruby
def mfa_delete_configured?
  versioning_configuration.key?(:mfa_delete)
end

def status
  versioning_configuration[:status]
end
```

## Terraform Integration

### Resource Generation
```ruby
resource(:aws_s3_bucket_versioning, name) do
  bucket versioning_attrs.bucket
  expected_bucket_owner versioning_attrs.expected_bucket_owner if versioning_attrs.expected_bucket_owner
  
  versioning_configuration do
    status versioning_attrs.versioning_configuration[:status]
    mfa_delete versioning_attrs.versioning_configuration[:mfa_delete] if versioning_attrs.versioning_configuration[:mfa_delete]
  end
end
```

### Output Properties
- `id`: Versioning configuration ID
- `bucket`: Associated bucket name

## Computed Properties

### State Analysis
- **versioning_enabled**: Boolean indicating if versioning is active
- **versioning_suspended**: Boolean indicating if versioning is suspended
- **mfa_delete_enabled**: Boolean indicating if MFA delete is active
- **mfa_delete_configured**: Boolean indicating if MFA delete is set
- **status**: Current versioning status string

### Usage Pattern
```ruby
versioning_ref = aws_s3_bucket_versioning(:bucket_versioning, {...})

if versioning_ref.computed[:versioning_enabled]
  puts "Versioning is active - object history preserved"
end

if versioning_ref.computed[:mfa_delete_enabled]
  puts "MFA required for version deletion"
end
```

## Implementation Patterns

### Basic Versioning
```ruby
basic_versioning = aws_s3_bucket_versioning(:basic, {
  bucket: "my-bucket",
  versioning_configuration: {
    status: "Enabled"
  }
})
```

### High-Security Versioning
```ruby
secure_versioning = aws_s3_bucket_versioning(:secure, {
  bucket: "critical-data",
  versioning_configuration: {
    status: "Enabled",
    mfa_delete: "Enabled"
  }
})
```

### Cross-Account Configuration
```ruby
cross_account_versioning = aws_s3_bucket_versioning(:cross_account, {
  bucket: "shared-bucket",
  expected_bucket_owner: "123456789012",
  versioning_configuration: {
    status: "Enabled"
  }
})
```

## Integration Points

### With Bucket Lifecycle
```ruby
# Versioning enables lifecycle rules for non-current versions
bucket_with_lifecycle = aws_s3_bucket(:versioned_bucket, {
  lifecycle_rule: [
    {
      id: "cleanup_old_versions",
      enabled: true,
      noncurrent_version_expiration: {
        days: 30
      }
    }
  ]
})

aws_s3_bucket_versioning(:lifecycle_versioning, {
  bucket: bucket_with_lifecycle.bucket,
  versioning_configuration: { status: "Enabled" }
})
```

### With Object Lock
```ruby
# Object lock requires versioning
aws_s3_bucket_versioning(:object_lock_versioning, {
  bucket: "immutable-records",
  versioning_configuration: { status: "Enabled" }
})

# Object lock configuration depends on versioning
aws_s3_bucket(:immutable_bucket, {
  object_lock_configuration: {
    object_lock_enabled: "Enabled"
  }
})
```

### With Encryption
```ruby
# Versioning works with encryption
aws_s3_bucket_encryption(:encrypted_versions, {
  bucket: "versioned-encrypted-bucket",
  server_side_encryption_configuration: {
    rule: [{
      apply_server_side_encryption_by_default: {
        sse_algorithm: "aws:kms",
        kms_master_key_id: "alias/s3-key"
      }
    }]
  }
})

aws_s3_bucket_versioning(:encrypted_versioning, {
  bucket: "versioned-encrypted-bucket",
  versioning_configuration: { status: "Enabled" }
})
```

## Best Practices Implementation

### Versioning Strategy
```ruby
# Enable versioning early in bucket lifecycle
new_bucket_versioning = aws_s3_bucket_versioning(:new_bucket, {
  bucket: "new-project-bucket",
  versioning_configuration: { status: "Enabled" }
})
```

### MFA Delete for Critical Data
```ruby
# Use MFA delete for compliance-critical buckets
compliance_versioning = aws_s3_bucket_versioning(:compliance, {
  bucket: "audit-logs",
  versioning_configuration: {
    status: "Enabled",
    mfa_delete: "Enabled"
  }
})
```

### Gradual Implementation
```ruby
# Start with versioning enabled, add MFA delete later
initial_versioning = aws_s3_bucket_versioning(:gradual_step1, {
  bucket: "gradual-bucket",
  versioning_configuration: { status: "Enabled" }
})

# Later deployment can update to include MFA delete
# enhanced_versioning = aws_s3_bucket_versioning(:gradual_step2, {
#   bucket: "gradual-bucket", 
#   versioning_configuration: {
#     status: "Enabled",
#     mfa_delete: "Enabled"
#   }
# })
```

## State Transition Management

### Enabling Versioning
- From unversioned → Enabled: Creates new versions for new objects
- Existing objects get null version ID until modified

### Suspending Versioning
- From Enabled → Suspended: Stops creating new versions
- Existing versions remain accessible
- New uploads overwrite current version

### MFA Delete Changes
- Requires MFA device for root or IAM user
- Cannot be changed via Terraform without MFA
- Must be configured via AWS CLI or Console with MFA

## Error Handling

### Validation Errors
```ruby
# Missing versioning configuration
aws_s3_bucket_versioning(:invalid, {
  bucket: "my-bucket"
  # Missing versioning_configuration - raises error
})

# Invalid status value  
aws_s3_bucket_versioning(:invalid_status, {
  bucket: "my-bucket",
  versioning_configuration: {
    status: "Invalid"  # Must be "Enabled" or "Suspended"
  }
})
```

### Multi-Account Scenarios
```ruby
# Specify expected owner to prevent cross-account issues
safe_cross_account = aws_s3_bucket_versioning(:safe_cross_account, {
  bucket: "shared-bucket",
  expected_bucket_owner: "123456789012",
  versioning_configuration: { status: "Enabled" }
})
```

## Performance Considerations

- **Version proliferation**: Monitor version count and storage usage
- **Lifecycle management**: Implement rules for old version cleanup
- **Access patterns**: Consider impact on list operations
- **Cost monitoring**: Track storage costs for version retention

## Security Implications

### Data Protection
- **Accidental deletion**: Versioning protects against data loss
- **Malicious deletion**: MFA delete adds security layer
- **Point-in-time recovery**: Access to historical versions

### Compliance Benefits
- **Audit trails**: Version history for compliance requirements
- **Data integrity**: Immutable version history
- **Retention policies**: Support for regulatory requirements

## Testing Considerations

### Validation Testing
- Test missing configuration detection
- Test invalid status values
- Test MFA delete configuration validation
- Test expected bucket owner scenarios

### Integration Testing
- Test versioning state transitions
- Test interaction with lifecycle rules
- Test object lock dependencies
- Test encryption compatibility

### Operational Testing
- Test version creation behavior
- Test suspension and re-enabling
- Test MFA delete requirements
- Test cross-account scenarios