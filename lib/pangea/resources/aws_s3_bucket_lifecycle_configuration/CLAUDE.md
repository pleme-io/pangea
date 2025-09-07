# AWS S3 Bucket Lifecycle Configuration Implementation

## Overview

The `aws_s3_bucket_lifecycle_configuration` resource provides type-safe S3 lifecycle rule management with comprehensive validation and terraform synthesis. This implementation follows Pangea's architecture patterns with dry-struct validation and terraform-synthesizer integration.

## Architecture

### Type Safety Hierarchy

```
S3BucketLifecycleConfigurationAttributes (Top Level)
├── LifecycleRule[] (1-1000 rules)
│   ├── LifecycleFilter (Optional)
│   │   ├── LifecycleFilterAnd (Complex AND conditions)
│   │   │   └── LifecycleFilterTag[] (Multiple tags)
│   │   └── LifecycleFilterTag (Single tag)
│   ├── LifecycleExpiration (Optional)
│   ├── LifecycleTransition[] (Optional)
│   ├── LifecycleNoncurrentVersionExpiration (Optional)
│   ├── LifecycleNoncurrentVersionTransition[] (Optional)
│   └── LifecycleAbortIncompleteMultipartUpload (Optional)
```

### Key Components

1. **S3BucketLifecycleConfigurationAttributes**: Root validation and configuration
2. **LifecycleRule**: Individual lifecycle rule with complete validation
3. **LifecycleFilter**: Flexible filtering system supporting simple and complex conditions
4. **Expiration/Transition Classes**: Type-safe storage class transitions and object expiration
5. **Noncurrent Version Classes**: Versioned object lifecycle management
6. **Custom Validation**: Business rule enforcement throughout the hierarchy

## Implementation Details

### Validation Strategy

**Rule-Level Validation**:
- Unique rule IDs across all rules in configuration
- Rule count constraints (1-1000 rules)
- Status enum validation (Enabled/Disabled)

**Expiration Validation**:
- Cannot specify both `date` and `days`
- Must specify at least one expiration property
- Date format validation (ISO 8601)

**Transition Validation**:
- Must specify either `date` or `days` (exclusive)
- Storage class enum validation
- Logical storage class progression validation

**Filter Validation**:
- Cannot combine multiple top-level filter conditions
- Complex AND conditions support multiple criteria
- Tag key/value pair validation

### Terraform Synthesis

The resource generates complex nested Terraform JSON structures:

```ruby
resource(:aws_s3_bucket_lifecycle_configuration, name) do
  bucket attrs.bucket
  
  attrs.rule.each do |lifecycle_rule|
    rule do
      id lifecycle_rule.id
      status lifecycle_rule.status
      
      # Complex nested filter synthesis
      if lifecycle_rule.filter&.and_condition
        filter do
          and_condition do
            # Multiple nested conditions
          end
        end
      end
      
      # Multiple transition blocks
      lifecycle_rule.transition&.each do |trans|
        transition do
          days trans.days
          storage_class trans.storage_class
        end
      end
    end
  end
end
```

### Computed Properties

The resource provides runtime analytics:

- `total_rules_count`: Total lifecycle rules
- `enabled_rules_count`: Active rules count  
- `disabled_rules_count`: Inactive rules count
- `rules_with_expiration_count`: Rules with object expiration
- `rules_with_transitions_count`: Rules with storage class transitions

## Storage Class Progression

Supports all AWS S3 storage classes with logical progression validation:

```
STANDARD → STANDARD_IA → ONEZONE_IA → GLACIER_IR → GLACIER → DEEP_ARCHIVE
            ↓
      INTELLIGENT_TIERING
            ↓
      REDUCED_REDUNDANCY (deprecated)
```

## Filter System Architecture

### Simple Filters
Single condition matching:
- `prefix`: Object key prefix matching
- `tag`: Single tag key/value matching  
- `object_size_greater_than`: Size-based filtering (bytes)
- `object_size_less_than`: Size-based filtering (bytes)

### Complex AND Filters  
Multiple condition matching via `and_condition`:
- Combines prefix + tags + size constraints
- All conditions must match for rule application
- Supports multiple tag conditions simultaneously

### Filter Precedence
1. Complex `and_condition` filters (highest precedence)
2. Simple top-level filters
3. Legacy `prefix` attribute (backward compatibility)

## Helper Methods

### Rule-Level Helpers
```ruby
rule.enabled?           # Check if rule is active
rule.disabled?          # Check if rule is inactive  
rule.has_expiration?    # Check if rule has expiration config
rule.has_transitions?   # Check if rule has storage transitions
rule.has_filter?        # Check if rule has filter conditions
```

### Configuration-Level Helpers
```ruby
attrs.enabled_rules             # Get all enabled rules
attrs.disabled_rules            # Get all disabled rules
attrs.rules_with_expiration     # Get rules with expiration
attrs.rules_with_transitions    # Get rules with transitions
attrs.total_rules_count         # Get total rule count
```

## Error Handling

### Validation Errors
- Rule ID conflicts: "Rule IDs must be unique within lifecycle configuration"
- Date/days conflicts: "Cannot specify both 'date' and 'days' for expiration"
- Missing expiration: "Must specify at least one expiration property"
- Filter conflicts: "Can only specify one top-level filter condition"

### Runtime Safety
- Enum validation for storage classes and rule status
- Array constraint validation (1-1000 rules)
- Integer constraints for days/size values
- String validation for dates and identifiers

## Performance Considerations

- Lazy evaluation of computed properties
- Efficient rule iteration for large configurations
- Memory-efficient nested structure handling
- Optimized terraform JSON generation

## Integration Patterns

### Template Usage
```ruby
template :s3_lifecycle do
  provider :aws do
    region "us-east-1"
  end
  
  # Create S3 bucket
  bucket_ref = aws_s3_bucket(:data_bucket, {
    bucket: "my-data-bucket"
  })
  
  # Apply lifecycle configuration
  lifecycle_ref = aws_s3_bucket_lifecycle_configuration(:data_lifecycle, {
    bucket: bucket_ref.outputs[:id],
    rule: [
      # Complex rule configuration
    ]
  })
end
```

### Cross-Resource References
```ruby
# Reference lifecycle configuration in monitoring
output :lifecycle_summary do
  value {
    bucket: lifecycle_ref.outputs[:bucket],
    total_rules: lifecycle_ref.computed_properties[:total_rules_count],
    enabled_rules: lifecycle_ref.computed_properties[:enabled_rules_count]
  }
end
```

## Testing Strategy

The implementation supports comprehensive testing:

1. **Unit Tests**: Dry-struct validation testing
2. **Integration Tests**: Terraform synthesis verification  
3. **Property Tests**: Computed property accuracy
4. **Error Tests**: Validation error scenarios
5. **Edge Cases**: Boundary condition testing

This implementation provides enterprise-grade S3 lifecycle management with complete type safety and comprehensive validation while maintaining simplicity for common use cases.