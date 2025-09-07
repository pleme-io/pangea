# AWS Volume Attachment Resource Implementation

## Overview

The `aws_volume_attachment` resource provides type-safe EBS volume attachment to EC2 instances with comprehensive validation, device name management, and cross-platform support. This implementation follows Pangea's resource function patterns and provides extensive computed properties for attachment management.

## Implementation Architecture

### Type Safety and Validation

**Dry-Struct Schema (`VolumeAttachmentAttributes`)**:
- Validates device name format using regex patterns
- Ensures required attributes (device_name, instance_id, volume_id)
- Provides optional attachment behavior controls (force_detach, skip_destroy, stop_instance_before_detaching)
- Includes comprehensive AWS device naming validation

**Device Name Validation**:
```ruby
# Regex pattern validates both Linux and Windows device naming
attribute :device_name, Types::String.constrained(
  format: /\A(?:\/dev\/(?:sd[f-p]|xvd[f-p])|xvd[f-p])\z/
)

# Custom validation prevents reserved device names
if device_name.match?(/\A\/dev\/sd[a-e]\z/)
  raise Dry::Struct::Error, "Device names /dev/sda through /dev/sde are reserved by AWS"
end
```

### Resource Function Implementation

**Function Signature**:
```ruby
def aws_volume_attachment(name, attributes = {})
```

**Terraform Resource Generation**:
- Maps validated attributes to terraform resource block
- Conditionally includes optional boolean attributes only when true
- Handles cross-platform device naming automatically
- Supports comprehensive tagging

### Cross-Platform Device Naming

**Device Name Normalization**:
- **Linux Format**: `/dev/sdf` through `/dev/sdp`
- **Windows Format**: `xvdf` through `xvdp`
- **Validation**: Prevents use of reserved device names (`sda-sde`, `xvda-xvde`)
- **Conversion**: Provides methods for format conversion between platforms

**Platform Detection Methods**:
```ruby
def linux_device_naming?
  device_name.start_with?('/dev/')
end

def windows_device_naming?
  device_name.match?(/\Axvd[f-p]\z/)
end

def normalized_device_name
  # Returns device name without /dev/ prefix
end
```

## Key Features

### 1. Comprehensive Device Name Management

**Device Name Validation**:
- Regex validation for AWS-compliant device names
- Prevention of reserved device name usage
- Cross-platform format support (Linux `/dev/sd*` vs Windows `xvd*`)
- Sequential device naming guidance

**Device Naming Utilities**:
- Device letter extraction (`f`, `g`, `h`, etc.)
- Next available device name suggestions
- Format normalization between platforms
- Best practices validation

### 2. Production Safety Controls

**Attachment Behavior Options**:
- `force_detach`: Force detachment during destroy (development use)
- `skip_destroy`: Preserve attachment when infrastructure is destroyed
- `stop_instance_before_detaching`: Safe detachment for critical volumes

**Production Safety Assessment**:
```ruby
def production_safe?
  !force_detach && !stop_instance_before_detaching
end
```

### 3. Multi-Volume Support

**Sequential Attachment Pattern**:
- Validation ensures proper device name sequencing
- Helper methods for multi-volume setups
- Device conflict prevention
- Volume attachment ordering guidance

### 4. Computed Properties and Metadata

**Attachment Analysis**:
- Platform compatibility assessment
- Device naming convention validation
- Production readiness evaluation
- Detachment behavior summarization

**Resource Reference Properties**:
```ruby
computed_properties: {
  linux_device_naming: attrs.linux_device_naming?,
  windows_device_naming: attrs.windows_device_naming?,
  normalized_device_name: attrs.normalized_device_name,
  production_safe: attrs.production_safe?,
  detachment_behavior: attrs.detachment_behavior
}
```

## Terraform Resource Mapping

### Required Terraform Attributes
- `device_name`: String - Device name exposed to instance
- `instance_id`: String - Target EC2 instance ID  
- `volume_id`: String - EBS volume ID to attach

### Optional Terraform Attributes
- `force_detach`: Boolean - Force detachment on destroy
- `skip_destroy`: Boolean - Skip detachment on resource destroy
- `stop_instance_before_detaching`: Boolean - Stop instance before detach
- `tags`: Map - Resource tags

### Terraform Outputs
All standard aws_volume_attachment outputs are exposed:
- Basic attributes (device_name, instance_id, volume_id)
- Behavior flags (force_detach, skip_destroy, stop_instance_before_detaching)
- Generated attributes (tags_all)

## Validation Rules

### 1. Device Name Validation
- **Format Compliance**: Must match AWS device naming patterns
- **Reserved Names**: Prevents use of AWS reserved device names
- **Platform Conventions**: Validates Linux vs Windows naming conventions
- **Sequential Logic**: Ensures logical device name progression

### 2. Attachment Safety
- **Instance-Volume AZ Matching**: Assumes instances and volumes are in same AZ
- **Device Availability**: Validates device names are in available range
- **Conflict Prevention**: Prevents device name conflicts

### 3. Configuration Safety
- **Production Guidelines**: Identifies potentially unsafe configurations
- **Detachment Behavior**: Validates consistent detachment policies
- **Tag Management**: Ensures proper resource tagging

## Use Case Support

### 1. Database Storage Architecture
- **Data Volumes**: High-IOPS volumes for database files
- **Log Volumes**: Separate volumes for transaction logs  
- **Backup Volumes**: Cost-optimized volumes for backups
- **Sequential Device Naming**: Logical device organization

### 2. Multi-Tier Applications  
- **Application Data**: Persistent application storage
- **Cache Volumes**: Local caching storage
- **Log Storage**: Centralized logging volumes
- **Configuration Data**: Separate configuration storage

### 3. Development vs Production
- **Development**: Force detach enabled for rapid iteration
- **Production**: Safe detachment with instance stop options
- **Staging**: Balanced approach with selective safety measures

### 4. Cross-Platform Deployment
- **Linux Instances**: Standard `/dev/sd*` device naming
- **Windows Instances**: Windows-compatible `xvd*` naming
- **Mixed Environments**: Consistent attachment patterns across platforms

## Integration Patterns

### With EBS Volume Resources
```ruby
# Create volume and attachment together
volume = aws_ebs_volume(:data_volume, { ... })
attachment = aws_volume_attachment(:data_attachment, {
  volume_id: volume.id,
  instance_id: instance_ref.id,
  device_name: "/dev/sdf"
})
```

### With EC2 Instance Resources
```ruby  
# Multi-volume instance setup
instance = aws_instance(:db_server, { ... })

# Attach multiple volumes with sequential device names
[:data, :logs, :backup].each_with_index do |purpose, index|
  device_letter = ('f'.ord + index).chr
  aws_volume_attachment(:"#{purpose}_attachment", {
    device_name: "/dev/sd#{device_letter}",
    instance_id: instance.id,
    volume_id: volumes[purpose].id
  })
end
```

### With Auto Scaling Groups
```ruby
# Launch template with user data for volume mounting
launch_template = aws_launch_template(:app_template, {
  user_data: base64encode(volume_mounting_script)
})

# Note: ASG instances typically handle volume attachment via user data
# rather than explicit aws_volume_attachment resources
```

## Error Handling and Debugging

### Common Validation Errors
1. **Reserved Device Names**: Using `sda-sde` or `xvda-xvde`
2. **Format Mismatch**: Wrong device naming for target platform  
3. **Missing Required Attributes**: Instance ID or volume ID not provided
4. **Device Range**: Using device names outside `f-p` range

### Debugging Utilities
- Device name format validation
- Platform compatibility checking  
- Production safety assessment
- Detachment behavior analysis

### Resource Reference Inspection
```ruby
attachment_ref = aws_volume_attachment(:data_attachment, { ... })

# Check device naming convention
puts attachment_ref.linux_device_naming  # true/false
puts attachment_ref.normalized_device_name  # "sdf"
puts attachment_ref.production_safe  # true/false
```

## Best Practices

### 1. Device Name Management
- Use sequential device names starting with `f`
- Maintain consistent naming across environments  
- Document device usage purpose in tags
- Validate platform compatibility before deployment

### 2. Production Safety
- Avoid `force_detach` in production environments
- Use `stop_instance_before_detaching` for critical volumes
- Consider `skip_destroy` for persistent data volumes
- Implement proper backup strategies before volume operations

### 3. Multi-Volume Architecture
- Separate volumes by function (data, logs, backups)
- Use appropriate EBS volume types for each purpose
- Plan device naming strategy for scalability
- Document volume mount points in infrastructure code

### 4. Cross-Platform Considerations
- Use correct device naming conventions for target OS
- Test volume attachment behavior across platforms
- Document OS-specific mounting procedures
- Maintain consistent volume labeling across platforms

## Performance Considerations

### Resource Creation
- Volume attachments are typically fast operations (seconds)
- Instance state affects attachment speed
- AZ proximity improves attachment reliability

### State Management
- Template-level isolation prevents attachment conflicts
- Minimal terraform state due to simple resource structure
- Cross-reference management through resource IDs

### Scalability
- Supports up to 11 additional volumes per instance (f through p)
- Efficient device name validation through regex patterns
- Computed properties cached for performance

## Security Considerations

### Access Control
- Volume attachment requires instance and volume access
- IAM policies should restrict volume attachment permissions
- Cross-account volume attachment may require additional policies

### Data Security
- Volume encryption handled at EBS volume level
- Volume attachment does not affect encryption status
- Consider instance-level access controls for mounted volumes

### Audit and Compliance
- Volume attachment events logged in CloudTrail
- Resource tagging enables compliance tracking
- Attachment metadata supports security assessments

## Testing Strategy

### Unit Testing
- Device name validation logic
- Platform compatibility methods
- Production safety assessment
- Computed property calculations

### Integration Testing  
- Volume attachment with running instances
- Cross-platform device naming
- Multi-volume attachment scenarios
- Detachment behavior validation

### End-to-End Testing
- Complete infrastructure deployment
- Volume mounting and formatting
- Application data persistence
- Disaster recovery procedures