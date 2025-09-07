# AWS AMI Resource Implementation

## Overview

The `aws_ami` resource provides type-safe infrastructure management for AWS AMI (Amazon Machine Image) resources. This implementation follows Pangea's established patterns for resource abstraction with comprehensive validation, computed properties, and Terraform integration.

## Architecture

### Type System
- **Primary Type**: `AmiAttributes` - Comprehensive AMI configuration with validation
- **Base Types**: Utilizes `Types::String`, `Types::Bool`, `Types::Array`, and custom enums
- **Validation**: Multi-level validation including format checking and compatibility rules

### Resource Function Signature
```ruby
def aws_ami(name, attributes = {})
  # Returns ResourceReference with outputs and computed properties
end
```

## Implementation Details

### Core Attributes

**Required Attributes:**
- `name` - AMI name (unique identifier)

**Optional Basic Attributes:**
- `description` - Human-readable AMI description
- `architecture` - CPU architecture (x86_64, i386, arm64)
- `boot_mode` - Boot mode (legacy-bios, uefi)
- `virtualization_type` - Virtualization type (hvm, paravirtual)

**Advanced Attributes:**
- `ena_support` - Enhanced networking support
- `sriov_net_support` - SR-IOV networking support
- `tpm_support` - Trusted Platform Module support
- `imds_support` - Instance Metadata Service version
- `deprecation_time` - Scheduled deprecation timestamp

### Block Device Configuration

**EBS Block Devices:**
```ruby
ebs_block_device: [
  {
    device_name: "/dev/sda1",          # Required
    volume_size: 20,                   # Optional
    volume_type: "gp3",                # Optional (gp2, gp3, io1, io2, etc.)
    iops: 3000,                        # Optional
    throughput: 125,                   # Optional
    encrypted: true,                   # Optional
    kms_key_id: "alias/my-key",        # Optional
    delete_on_termination: true,       # Optional
    snapshot_id: "snap-12345678"       # Optional
  }
]
```

**Instance Store Block Devices:**
```ruby
ephemeral_block_device: [
  {
    device_name: "/dev/sdb",           # Required
    virtual_name: "ephemeral0"         # Required
  }
]
```

## Validation Rules

### 1. Architecture and Virtualization Compatibility
```ruby
if attrs.architecture == "i386" && attrs.virtualization_type == "hvm"
  raise Dry::Struct::Error, "i386 architecture is not compatible with hvm virtualization type"
end
```

### 2. Boot Mode Compatibility
```ruby
if attrs.boot_mode == "uefi" && attrs.virtualization_type == "paravirtual"
  raise Dry::Struct::Error, "UEFI boot mode is only compatible with hvm virtualization type"
end
```

### 3. Feature Compatibility
- TPM support requires HVM virtualization
- IMDS support requires HVM virtualization
- Enhanced networking requires modern architectures

### 4. Time Format Validation
```ruby
if attrs.deprecation_time
  begin
    Time.iso8601(attrs.deprecation_time)
  rescue ArgumentError
    raise Dry::Struct::Error, "deprecation_time must be in ISO 8601 format"
  end
end
```

## Computed Properties

### Infrastructure Assessment
- `modern_ami?` - Checks for HVM + ENA support combination
- `compatible_with_nitro?` - Validates Nitro system compatibility
- `supports_sriov?` - SR-IOV networking capability

### Storage Analysis  
- `encrypted_by_default?` - Default encryption status
- `root_volume_size` - Root device storage size
- `total_storage_size` - Sum of all EBS volumes
- `has_instance_store?` - Instance store volume presence

### Cost and Recommendations
- `estimated_monthly_cost` - Storage and feature cost estimation
- `recommended_instance_types` - Architecture-appropriate instance types

## Terraform Integration

### Resource Block Generation
```ruby
resource(:aws_ami, name) do
  name ami_attrs.name
  architecture ami_attrs.architecture
  virtualization_type ami_attrs.virtualization_type
  
  # Conditional attributes
  description ami_attrs.description if ami_attrs.description
  ena_support ami_attrs.ena_support unless ami_attrs.ena_support.nil?
  
  # Block device iteration
  ami_attrs.ebs_block_device.each do |ebs_device|
    ebs_block_device do
      device_name ebs_device[:device_name]
      volume_size ebs_device[:volume_size] if ebs_device[:volume_size]
      # ... other attributes
    end
  end
end
```

### Output Generation
The resource provides comprehensive Terraform outputs:
- Standard AWS AMI attributes (id, arn, creation_date, state, etc.)
- Platform information (architecture, virtualization_type, platform_details)
- Configuration details (boot_mode, tpm_support, imds_support)

## Usage Patterns

### 1. Basic AMI Creation
Simple AMI creation with minimal configuration for development environments.

### 2. Production AMI with Security Features
Comprehensive security-hardened AMI with encryption, modern boot modes, and compliance features.

### 3. Multi-Architecture Support
ARM64 AMIs for Graviton processors with architecture-specific optimizations.

### 4. Storage-Optimized AMIs
Complex storage configurations with multiple EBS volumes and instance store.

### 5. Lifecycle Management
AMIs with scheduled deprecation and automated cleanup processes.

## Integration Points

### With EC2 Instances
```ruby
my_ami = aws_ami(:custom_ami, { ... })
aws_instance(:server, {
  ami: my_ami.id,
  instance_type: my_ami.computed_properties[:recommended_instance_types].first
})
```

### With Launch Templates
```ruby
my_ami = aws_ami(:app_ami, { ... })
aws_launch_template(:app_template, {
  image_id: my_ami.id,
  instance_type: "t3.medium"
})
```

### Cross-Reference Validation
The resource integrates with other AWS resources for comprehensive infrastructure validation:
- Instance type compatibility checks
- Security group and networking validation
- Storage encryption alignment

## Error Handling

### Validation Errors
- Architecture and virtualization type mismatches
- Boot mode compatibility issues
- Feature support validation
- Time format validation for deprecation schedules

### Runtime Considerations
- AWS API limits for AMI operations
- Regional AMI availability
- Cross-account AMI sharing permissions
- Snapshot dependencies

## Performance Characteristics

### Resource Creation Time
- AMI creation is typically slow (5-20 minutes)
- EBS snapshot creation adds additional time
- Instance store AMIs create faster than EBS-backed

### Storage Costs
- Estimated monthly cost calculation includes:
  - EBS snapshot storage costs
  - Feature-based cost adjustments
  - Regional pricing variations

## Best Practices

### Security
1. Always encrypt EBS volumes for sensitive workloads
2. Use IMDSv2 for enhanced metadata security
3. Enable TPM support for compliance requirements
4. Set appropriate deprecation schedules

### Performance
1. Use ENA support for better networking
2. Enable SR-IOV for high-performance networking
3. Choose appropriate EBS volume types for workload requirements
4. Consider ARM64 for cost optimization

### Operations
1. Use consistent naming conventions
2. Apply comprehensive tagging for resource management
3. Set deprecation times for AMI lifecycle management
4. Document AMI purpose and configuration in descriptions

## Testing Strategy

### Validation Testing
- Architecture and virtualization type combinations
- Block device configuration validation
- Time format parsing for deprecation schedules
- Feature compatibility matrix

### Integration Testing  
- AMI creation with various configurations
- Cross-resource references (instances, launch templates)
- Multi-environment deployment scenarios
- Cost estimation accuracy

This implementation provides a robust, type-safe interface for AWS AMI management while maintaining compatibility with Pangea's architecture patterns and Terraform integration requirements.