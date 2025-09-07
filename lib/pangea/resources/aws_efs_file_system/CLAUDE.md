# AWS EFS File System Implementation

## Overview

The AWS EFS File System resource provides type-safe, validated creation of Elastic File Systems with comprehensive support for all AWS EFS features including performance modes, throughput configuration, encryption, and lifecycle management.

## Implementation Architecture

### Type System

The implementation uses Pangea's type-safe resource pattern with comprehensive validation:

```ruby
class EfsFileSystemAttributes < Dry::Struct
  # Core configuration with validation
  attribute :performance_mode, Resources::Types::EfsPerformanceMode.default("generalPurpose")
  attribute :throughput_mode, Resources::Types::EfsThroughputMode.default("bursting")
  attribute :provisioned_throughput_in_mibps, Resources::Types::Integer.optional
  attribute :encrypted, Resources::Types::Bool.default(true)
  
  # Lifecycle and storage configuration
  attribute? :lifecycle_policy, Resources::Types::EfsLifecyclePolicy.optional
  attribute :availability_zone_name, Resources::Types::String.optional
```

### Custom Validation Logic

The type system includes sophisticated validation for EFS-specific constraints:

1. **Throughput Mode Validation**: Ensures provisioned throughput is only set when using provisioned mode
2. **Performance Mode Constraints**: Validates that maxIO is not used with One Zone storage
3. **Throughput Range Validation**: Enforces AWS limits of 1-3584 MiB/s for provisioned throughput
4. **Cost Estimation**: Provides computed properties for cost analysis

### Resource Function Interface

```ruby
def aws_efs_file_system(name, attributes = {})
  validated_attrs = AWS::Types::EfsFileSystemAttributes.new(attributes)
  # Process and validate attributes
  # Create terraform resource
  # Return ResourceReference with comprehensive outputs
end
```

## Key Features

### Performance and Throughput Management

The implementation provides full support for EFS performance characteristics:

- **Performance Modes**: generalPurpose (low latency) vs maxIO (high ops/second)
- **Throughput Modes**: bursting (scales with size) vs provisioned (fixed)
- **Throughput Validation**: Automatic validation of provisioned throughput limits
- **One Zone Constraints**: Prevents invalid combinations like maxIO + One Zone

### Storage Class Support

Comprehensive support for both Regional and One Zone storage classes:

- **Regional**: Multi-AZ replication for high availability
- **One Zone**: Single AZ storage for cost optimization
- **Cost Estimation**: Built-in cost modeling for different configurations

### Security and Encryption

Security-first approach with encryption enabled by default:

- **Encryption at Rest**: Enabled by default with optional KMS key specification
- **Creation Token Management**: Automatic generation with optional override
- **Resource Tagging**: Comprehensive tagging support for governance

### Lifecycle Management

Full support for EFS intelligent tiering:

- **Transition to IA**: Configurable transition periods (7-90 days)
- **Transition to Primary**: AFTER_1_ACCESS for frequently accessed files
- **Policy Validation**: Ensures at least one transition is configured

## Computed Properties

The implementation includes several computed properties for operational insight:

### Cost Estimation

```ruby
def estimated_monthly_cost_per_gb
  base_cost = is_one_zone? ? 0.0225 : 0.30
  
  if throughput_mode == "provisioned" && provisioned_throughput_in_mibps
    throughput_cost = provisioned_throughput_in_mibps * 6.00 / 1024
    return { storage: base_cost, throughput: throughput_cost, total: base_cost + throughput_cost }
  end
  
  { storage: base_cost, throughput: 0.0, total: base_cost }
end
```

### Storage Classification

```ruby
def storage_class
  is_one_zone? ? "One Zone" : "Regional"
end

def is_one_zone?
  !availability_zone_name.nil?
end
```

## Resource Outputs

The ResourceReference includes comprehensive outputs for integration:

### Core Identifiers
- `id`: File system ID for mount targets and access points
- `arn`: Full ARN for IAM policies and cross-service references
- `dns_name`: Regional DNS name for NFS mounting

### Configuration Details
- `performance_mode`, `throughput_mode`: Runtime configuration verification
- `encrypted`, `kms_key_id`: Security configuration details
- `provisioned_throughput_in_mibps`: Throughput configuration

### Operational Metrics
- `size_in_bytes`: File system size information for monitoring
- `number_of_mount_targets`: Infrastructure topology insight
- `owner_id`: Account ownership information

## Integration Patterns

### With Mount Targets

```ruby
efs = aws_efs_file_system(:app_storage, { ... })

aws_efs_mount_target(:mount_a, {
  file_system_id: efs.id,  # Direct reference to file system
  subnet_id: subnet_ref.id,
  security_groups: [sg_ref.id]
})
```

### With Access Points

```ruby
aws_efs_access_point(:app_access, {
  file_system_id: efs.id,  # References the file system
  posix_user: { uid: 1000, gid: 1000 },
  root_directory: { path: "/app" }
})
```

### With Security Groups

```ruby
# EFS requires NFS (port 2049) access
aws_security_group_rule(:efs_ingress, {
  type: "ingress",
  from_port: 2049,
  to_port: 2049,
  protocol: "tcp",
  security_group_id: sg_ref.id,
  source_security_group_id: client_sg_ref.id
})
```

## Production Patterns

### High Availability Setup

```ruby
# Regional EFS with multi-AZ mount targets
regional_efs = aws_efs_file_system(:prod_storage, {
  performance_mode: "generalPurpose",
  throughput_mode: "bursting",
  encrypted: true,
  lifecycle_policy: { transition_to_ia: "AFTER_30_DAYS" }
})

# Mount targets in each AZ
["a", "b", "c"].each do |az|
  aws_efs_mount_target(:"mount_#{az}", {
    file_system_id: regional_efs.id,
    subnet_id: ref(:aws_subnet, :"private_#{az}", :id),
    security_groups: [ref(:aws_security_group, :efs_sg, :id)]
  })
end
```

### Performance-Optimized Setup

```ruby
# High performance EFS for demanding workloads
performance_efs = aws_efs_file_system(:high_perf, {
  performance_mode: "maxIO",
  throughput_mode: "provisioned",
  provisioned_throughput_in_mibps: 1000,
  encrypted: true,
  kms_key_id: kms_key_ref.arn
})
```

### Cost-Optimized Setup

```ruby
# One Zone EFS for development/testing
cost_efs = aws_efs_file_system(:dev_storage, {
  availability_zone_name: "us-east-1a",
  performance_mode: "generalPurpose",
  throughput_mode: "bursting",
  encrypted: true
})
```

## Error Handling

The implementation includes comprehensive error handling for common misconfigurations:

### Throughput Configuration Errors

```ruby
# These will raise validation errors:
aws_efs_file_system(:bad_config, {
  throughput_mode: "provisioned"
  # Missing provisioned_throughput_in_mibps
})

aws_efs_file_system(:bad_config2, {
  throughput_mode: "bursting",
  provisioned_throughput_in_mibps: 100  # Invalid for bursting mode
})
```

### Performance Mode Constraints

```ruby
# This will raise a validation error:
aws_efs_file_system(:bad_config, {
  availability_zone_name: "us-east-1a",  # One Zone
  performance_mode: "maxIO"  # Not supported for One Zone
})
```

### Throughput Limits

```ruby
# These will raise validation errors:
aws_efs_file_system(:too_low, {
  throughput_mode: "provisioned",
  provisioned_throughput_in_mibps: 0  # Below minimum of 1
})

aws_efs_file_system(:too_high, {
  throughput_mode: "provisioned", 
  provisioned_throughput_in_mibps: 4000  # Above maximum of 3584
})
```

## Testing Considerations

The implementation supports comprehensive testing through:

1. **Type Validation Testing**: All dry-struct validations can be unit tested
2. **Computed Property Testing**: Cost calculations and classifications
3. **Integration Testing**: Resource reference outputs and terraform generation
4. **Configuration Testing**: Various EFS configurations and edge cases

## AWS Service Integration

The EFS File System resource integrates with multiple AWS services:

- **EC2**: Mount targets connect to VPC subnets and security groups
- **ECS/EKS**: Native support for container storage volumes
- **Lambda**: EFS can be mounted to Lambda functions
- **KMS**: Integration for encryption key management
- **CloudWatch**: Automatic metrics and monitoring integration
- **IAM**: Access control through policies and access points