# AWS CloudWatch Log Group Implementation

## Overview

This implementation provides type-safe AWS CloudWatch Log Group resources with comprehensive validation, cost estimation, and enterprise logging patterns.

## Architecture

### Type System
- **`CloudWatchLogGroupAttributes`**: dry-struct validation with CloudWatch-specific constraints
- **Name Validation**: AWS log group naming pattern enforcement
- **Retention Validation**: Validates against AWS-supported retention periods
- **Cost Estimation**: Built-in monthly cost estimation based on log class and encryption

### Key Features

#### 1. AWS-Compliant Name Validation
- Enforces AWS log group naming restrictions
- Prevents reserved prefix usage (`aws/`)
- Validates character sets and length limits
- Checks for invalid path patterns

#### 2. Retention Period Management
- Validates against all AWS-supported retention periods (1-3653 days)
- Supports unlimited retention (no retention_in_days specified)
- Clear enumeration of valid values in type system

#### 3. Cost Optimization Features
- Support for `INFREQUENT_ACCESS` log class for cost savings
- Built-in cost estimation methodology
- KMS encryption cost considerations
- Storage vs ingestion cost calculations

#### 4. Security and Compliance
- KMS encryption support with `kms_key_id`
- `skip_destroy` option for critical log groups
- Comprehensive tagging for governance
- Security-focused validation patterns

## Implementation Details

### Validation Logic

#### Log Group Name Validation
```ruby
# Pattern: only alphanumeric, periods, underscores, hyphens, forward slashes
name.match?(/\A[a-zA-Z0-9._\-\/]+\z/)

# Reserved prefix check
name.start_with?('aws/')  # Forbidden

# Path validation
name.include?('//')       # Forbidden consecutive slashes
name.end_with?('/') && name.length > 1  # Forbidden trailing slash
```

#### Retention Period Validation
```ruby
# Enum constraint with all AWS-supported values
retention_in_days.enum(1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, nil)
```

### Cost Estimation Algorithm

```ruby
def estimated_monthly_cost_usd
  base_gb_per_month = 10.0 # Assumption baseline
  
  case log_group_class
  when 'INFREQUENT_ACCESS'
    ingestion_cost = base_gb_per_month * 0.25 # $0.25/GB
    storage_cost = base_gb_per_month * 0.013  # $0.013/GB/month
  else # STANDARD
    ingestion_cost = base_gb_per_month * 0.50 # $0.50/GB 
    storage_cost = base_gb_per_month * 0.025  # $0.025/GB/month
  end
  
  encryption_cost = has_encryption? ? 1.00 : 0.0 # $1/month KMS
  
  (ingestion_cost + storage_cost + encryption_cost).round(2)
end
```

### Computed Properties

1. **`has_retention?`**: Boolean indicating if retention period is configured
2. **`has_encryption?`**: Boolean indicating if KMS encryption is enabled
3. **`is_infrequent_access?`**: Boolean indicating if IA class is used
4. **`estimated_monthly_cost_usd`**: Float with cost estimation

### Terraform Resource Mapping

```ruby
resource(:aws_cloudwatch_log_group, name) do
  name_attr log_group_attrs.name              # Required
  retention_in_days log_group_attrs.retention_in_days if log_group_attrs.retention_in_days
  kms_key_id log_group_attrs.kms_key_id if log_group_attrs.kms_key_id  
  log_group_class log_group_attrs.log_group_class if log_group_attrs.log_group_class
  skip_destroy log_group_attrs.skip_destroy    # Boolean
  
  # Tags block
  tags do
    log_group_attrs.tags.each do |key, value|
      public_send(key, value)
    end
  end
end
```

### Resource Reference Outputs

```ruby
outputs: {
  id: "${aws_cloudwatch_log_group.#{name}.id}",
  arn: "${aws_cloudwatch_log_group.#{name}.arn}",
  name: "${aws_cloudwatch_log_group.#{name}.name}",
  retention_in_days: "${aws_cloudwatch_log_group.#{name}.retention_in_days}",
  kms_key_id: "${aws_cloudwatch_log_group.#{name}.kms_key_id}",
  log_group_class: "${aws_cloudwatch_log_group.#{name}.log_group_class}",
  tags_all: "${aws_cloudwatch_log_group.#{name}.tags_all}"
}
```

## Enterprise Patterns

### 1. Multi-Service Logging
- Standardized naming patterns for services
- Consistent retention policies by log type
- Cost optimization through IA class usage
- Centralized governance through tagging

### 2. Security and Compliance
- Long retention periods for audit logs (up to 7 years)
- KMS encryption for sensitive data
- `skip_destroy` for critical log groups
- Comprehensive tagging for compliance tracking

### 3. Cost Optimization Strategies
- IA class for infrequently accessed logs
- Shorter retention for high-volume logs
- Cost estimation for budget planning
- Storage class selection based on access patterns

### 4. Integration Patterns
- Lambda function log groups with automatic naming
- ECS service log configurations
- VPC Flow Logs integration
- CloudTrail log group setup

## Validation Error Messages

The implementation provides clear error messages for common validation failures:

- Name pattern violations with specific character requirements
- Reserved prefix usage explanations
- Path validation errors with examples
- Retention period validation with valid value lists
- Cost estimation assumptions and calculations

## Best Practices Encoded

1. **Naming Conventions**: Hierarchical naming with service/type/environment structure
2. **Retention Policies**: Different retention for different log types
3. **Cost Management**: Automatic IA class recommendations for certain patterns
4. **Security**: Encryption for sensitive logs, skip_destroy for critical logs
5. **Governance**: Comprehensive tagging requirements and patterns

## Testing Considerations

The implementation supports testing through:
- Deterministic cost calculations
- Predictable computed properties
- Clear validation rules
- Comprehensive error messages
- Type safety through dry-struct validation