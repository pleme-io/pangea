# AWS EBS Volume Implementation Documentation

## Overview

The AWS EBS Volume resource provides type-safe creation and management of Amazon Elastic Block Store volumes with comprehensive validation, performance optimization, and cost estimation capabilities.

## Architecture

### Type System
- **EbsVolumeAttributes**: Dry::Struct with comprehensive validation
- **Conditional Requirements**: Volume type-specific attribute validation
- **Performance Constraints**: IOPS and throughput ratio validation
- **Cost Estimation**: Built-in monthly cost calculation

### Validation Framework

The implementation includes sophisticated validation logic:

1. **Volume Type Constraints**
   - Size requirements by type (gp2/gp3: 1-16384 GiB, io1/io2: 4-16384 GiB, etc.)
   - IOPS requirements and limits per volume type
   - Throughput validation for gp3 volumes

2. **Performance Validation**
   - IOPS-to-size ratio validation for provisioned IOPS volumes
   - Throughput-to-IOPS ratio validation for gp3 volumes
   - Multi-Attach compatibility checks

3. **Encryption and Security**
   - KMS key validation with encryption requirement
   - Outpost ARN format validation

## Key Features

### Volume Types Support
- **gp3**: Latest generation general purpose with configurable IOPS/throughput
- **gp2**: Previous generation general purpose with burstable performance  
- **io1/io2**: Provisioned IOPS SSD for high-performance workloads
- **st1**: Throughput optimized HDD for big data workloads
- **sc1**: Cold HDD for infrequent access
- **standard**: Magnetic storage (legacy)

### Advanced Capabilities
- **Multi-Attach**: Shared block storage across multiple EC2 instances (io1/io2 only)
- **Encryption**: AWS managed or customer managed KMS encryption
- **Snapshot Integration**: Create volumes from existing snapshots
- **Outpost Support**: Local storage on AWS Outposts

### Performance Configuration
- **IOPS Provisioning**: Type-specific IOPS configuration with validation
- **Throughput Control**: gp3 throughput optimization (125-1000 MiB/s)
- **Size Optimization**: Automatic validation of size limits by type

## Implementation Details

### Terraform Mapping

The resource maps Ruby attributes to Terraform `aws_ebs_volume` resource:

```ruby
# Ruby DSL
aws_ebs_volume(:volume_name, {
  availability_zone: "us-east-1a",
  size: 100,
  type: "gp3",
  iops: 5000,
  throughput: 250,
  encrypted: true
})

# Generated Terraform
resource "aws_ebs_volume" "volume_name" {
  availability_zone = "us-east-1a"
  size             = 100
  type             = "gp3"
  iops             = 5000
  throughput       = 250
  encrypted        = true
}
```

### Computed Properties

Rich computed properties provide configuration insights:

- **Performance Characteristics**: `provisioned_iops?`, `gp3?`, `throughput_optimized?`
- **Capability Checks**: `supports_encryption?`, `supports_multi_attach?`
- **Configuration Defaults**: `default_iops`, `default_throughput`
- **Cost Analysis**: `estimated_monthly_cost_usd`

### Cost Estimation Algorithm

Built-in cost estimation provides rough monthly AWS costs:

```ruby
def estimated_monthly_cost_usd
  base_cost = case type
  when 'gp2' then size * 0.10      # $0.10/GB-month
  when 'gp3' then size * 0.08      # $0.08/GB-month  
  when 'io1', 'io2' then size * 0.125 + iops * 0.065  # Storage + IOPS
  when 'st1' then size * 0.045     # $0.045/GB-month
  when 'sc1' then size * 0.015     # $0.015/GB-month
  end
  
  # Add gp3 throughput costs
  if type == 'gp3' && throughput > 125
    base_cost += (throughput - 125) * 0.04
  end
end
```

## Validation Examples

### IOPS Validation
```ruby
# io2 volume - IOPS required
EbsVolumeAttributes.new({
  availability_zone: "us-east-1a",
  size: 100,
  type: "io2"
  # Missing iops - will raise validation error
})

# gp3 volume - IOPS optional but validated against size
EbsVolumeAttributes.new({
  availability_zone: "us-east-1a", 
  size: 100,
  type: "gp3",
  iops: 60000  # Exceeds 100 * 500 IOPS limit - validation error
})
```

### Multi-Attach Validation
```ruby
# Only io1/io2 support Multi-Attach
EbsVolumeAttributes.new({
  availability_zone: "us-east-1a",
  size: 100,
  type: "gp3",
  multi_attach_enabled: true  # Validation error - not supported
})
```

### Size Validation
```ruby
# st1 minimum size requirement
EbsVolumeAttributes.new({
  availability_zone: "us-east-1a",
  size: 100,  # Too small - st1 requires 125 GiB minimum
  type: "st1"
})
```

## Usage Patterns

### Database Storage Pattern
```ruby
aws_ebs_volume(:db_primary, {
  availability_zone: "us-east-1a",
  size: 1000,
  type: "io2",
  iops: 20000,
  encrypted: true,
  kms_key_id: "arn:aws:kms:...",
  tags: { Name: "database-primary", Backup: "required" }
})
```

### Application Data Pattern
```ruby
aws_ebs_volume(:app_data, {
  availability_zone: "us-east-1a",
  size: 200,
  type: "gp3", 
  iops: 6000,
  throughput: 300,
  encrypted: true,
  tags: { Name: "application-data", Environment: "production" }
})
```

### Archive Storage Pattern
```ruby
aws_ebs_volume(:archive, {
  availability_zone: "us-east-1a",
  size: 2000,
  type: "sc1",  # Cold storage for cost optimization
  encrypted: true,
  tags: { Name: "archive-storage", AccessPattern: "infrequent" }
})
```

## Integration Points

### EC2 Instance Integration
The EBS Volume resource integrates seamlessly with EC2 instances through volume attachment:

```ruby
instance_ref = aws_instance(:web_server, {...})
volume_ref = aws_ebs_volume(:app_storage, {...})

aws_volume_attachment(:attachment, {
  device_name: "/dev/sdf",
  volume_id: volume_ref.id,
  instance_id: instance_ref.id
})
```

### Snapshot Integration
Create volumes from existing snapshots:

```ruby
aws_ebs_volume(:restored, {
  availability_zone: "us-east-1a",
  snapshot_id: "snap-1234567890abcdef0",
  type: "gp3"
  # Size inherited from snapshot if not specified
})
```

## Performance Considerations

### IOPS Optimization
- **gp2**: 3 IOPS per GiB (minimum 100, maximum 16,000)
- **gp3**: 3,000 baseline, configurable up to 16,000
- **io1/io2**: Fully configurable, up to 64,000 IOPS

### Throughput Optimization
- **gp3**: 125 MiB/s baseline, configurable up to 1,000 MiB/s
- **st1**: Up to 500 MiB/s throughput optimized for sequential workloads

### Cost Optimization
- **gp3 vs gp2**: gp3 provides better price/performance for most workloads
- **st1/sc1**: Lower cost per GB for big data and archive use cases
- **Right-sizing**: Use computed cost estimates to optimize configurations

## Security Features

### Encryption at Rest
- Default AWS managed keys or custom KMS keys
- Automatic validation of encryption configuration
- Inherited encryption from snapshots

### Access Control
- Integration with AWS IAM for volume management
- Resource tagging for fine-grained access control
- Outpost integration for local data residency

## Error Handling

The implementation provides clear error messages for common configuration mistakes:

- Missing required attributes (IOPS for provisioned volumes)
- Invalid attribute combinations (Multi-Attach with wrong volume type)
- Performance limit violations (IOPS exceeding size-based limits)
- Size constraint violations (below minimum or above maximum)

This comprehensive validation prevents deployment-time errors and ensures optimal volume configurations.

## Testing Strategy

### Unit Tests
- Attribute validation with valid/invalid combinations
- Computed property calculations
- Cost estimation accuracy

### Integration Tests  
- Terraform resource generation
- Cross-reference with other AWS resources
- End-to-end volume creation and attachment workflows

### Performance Tests
- IOPS and throughput configuration validation
- Cost estimation against actual AWS pricing
- Multi-Attach functionality verification