# AWS WorkSpaces Workspace - Implementation Notes

## Resource Overview

The `aws_workspaces_workspace` resource manages Amazon WorkSpaces virtual desktop instances, providing secure, managed desktop computing in the AWS cloud. WorkSpaces are essential for enterprise desktop virtualization, remote work scenarios, and secure access to corporate resources.

## Architectural Considerations

### Desktop Virtualization Model
- **Persistent desktops**: Each WorkSpace maintains state between sessions
- **User-specific**: One-to-one mapping between users and WorkSpaces
- **Directory integration**: Requires AWS Managed Microsoft AD or AD Connector
- **Network isolation**: Runs in VPC with controlled access

### Bundle System
WorkSpaces use predefined bundles that determine:
- Hardware configuration (CPU, memory, storage)
- Software image (Windows/Linux with pre-installed apps)
- Root and user volume sizes
- Graphics capabilities

### Running Modes
1. **AUTO_STOP**: Charges monthly fee + hourly when running
2. **ALWAYS_ON**: Flat monthly fee, no hourly charges

## Implementation Details

### Type Safety Implementation

```ruby
class WorkspacesWorkspaceAttributes < Dry::Struct
  # Directory ID validation ensures proper format
  attribute :directory_id, Resources::Types::String.constrained(
    format: /\Ad-[a-f0-9]{10}\z/
  )
  
  # Bundle ID validation for AWS WorkSpaces bundles
  attribute :bundle_id, Resources::Types::String.constrained(
    format: /\Awsb-[a-z0-9]{9}\z/
  )
  
  # User name follows Active Directory naming conventions
  attribute :user_name, Resources::Types::String.constrained(
    min_size: 1,
    max_size: 63,
    format: /\A[a-zA-Z0-9][a-zA-Z0-9._-]*\z/
  )
end
```

### Encryption Validation

The implementation enforces that encryption keys must be provided when encryption is enabled:

```ruby
def self.new(attributes)
  attrs = attributes.is_a?(Hash) ? attributes : {}
  
  if (attrs[:root_volume_encryption_enabled] || attrs[:user_volume_encryption_enabled])
    unless attrs[:volume_encryption_key]
      raise Dry::Struct::Error, "volume_encryption_key is required when encryption is enabled"
    end
  end
  
  super(attrs)
end
```

### Running Mode Configuration

Auto-stop timeout validation ensures proper configuration:

```ruby
# Valid timeout values in minutes
attribute :running_mode_auto_stop_timeout_in_minutes, Resources::Types::Integer.constrained(
  included_in: [60, 120, 180, 240, 300, 360, 420, 480, 540, 600, 660, 720]
).optional
```

### Computed Properties

#### Bundle Type Detection
```ruby
def compute_type_from_bundle
  case bundle_id
  when /wsb-bh8rsxt14/, /wsb-gm7rt3w1y/
    'VALUE'
  when /wsb-92tn3b7gx/, /wsb-8vbljg4r6/
    'STANDARD'
  # ... other patterns
  end
end
```

#### Cost Estimation
```ruby
def monthly_cost_estimate
  base_cost = case compute_type_name
             when 'VALUE' then 21
             when 'STANDARD' then 25
             when 'PERFORMANCE' then 35
             # ...
             end
  
  if always_on?
    hourly_cost = compute_hourly_rate
    base_cost + (hourly_cost * 730)
  else
    base_cost
  end
end
```

## Advanced Usage Patterns

### 1. Bulk WorkSpace Deployment
```ruby
users = ["john.doe", "jane.smith", "bob.jones"]

users.each do |username|
  aws_workspaces_workspace(:"workspace_#{username.tr('.', '_')}", {
    directory_id: directory.id,
    bundle_id: "wsb-92tn3b7gx",
    user_name: username,
    workspace_properties: {
      running_mode: "AUTO_STOP",
      running_mode_auto_stop_timeout_in_minutes: 120
    }
  })
end
```

### 2. Department-Specific Configurations
```ruby
def create_workspace_for_department(user, department)
  config = case department
           when :engineering
             {
               bundle_id: "wsb-b0s22j3d7",  # Performance
               workspace_properties: {
                 compute_type_name: "PERFORMANCE",
                 user_volume_size_gib: 200,
                 running_mode: "ALWAYS_ON"
               }
             }
           when :design
             {
               bundle_id: "wsb-wps19h2gn",  # Graphics
               workspace_properties: {
                 compute_type_name: "GRAPHICS",
                 user_volume_size_gib: 500,
                 running_mode: "AUTO_STOP"
               }
             }
           else
             {
               bundle_id: "wsb-92tn3b7gx",  # Standard
               workspace_properties: {
                 running_mode: "AUTO_STOP"
               }
             }
           end
  
  aws_workspaces_workspace(:"workspace_#{user}", config.merge({
    directory_id: directory.id,
    user_name: user,
    root_volume_encryption_enabled: true,
    user_volume_encryption_enabled: true,
    volume_encryption_key: kms_key.id
  }))
end
```

### 3. Compliance-Driven Configuration
```ruby
def create_compliant_workspace(name, user, compliance_level)
  base_config = {
    directory_id: directory.id,
    user_name: user,
    root_volume_encryption_enabled: true,
    user_volume_encryption_enabled: true,
    volume_encryption_key: compliance_kms_key.id
  }
  
  case compliance_level
  when :high
    aws_workspaces_workspace(name, base_config.merge({
      bundle_id: "wsb-b0s22j3d7",  # Performance for better security tools
      workspace_properties: {
        compute_type_name: "PERFORMANCE",
        root_volume_size_gib: 200,  # More space for security software
        running_mode: "ALWAYS_ON"  # Always available for monitoring
      },
      tags: {
        Compliance: "HIGH",
        Monitoring: "REQUIRED",
        Encryption: "REQUIRED"
      }
    }))
  when :standard
    aws_workspaces_workspace(name, base_config.merge({
      bundle_id: "wsb-92tn3b7gx",
      workspace_properties: {
        running_mode: "AUTO_STOP",
        running_mode_auto_stop_timeout_in_minutes: 180
      },
      tags: {
        Compliance: "STANDARD"
      }
    }))
  end
end
```

## Integration Patterns

### With Directory Service
```ruby
directory = aws_directory_service_directory(:corp_directory, {
  name: "corp.example.com",
  password: secret_password.value,
  type: "MicrosoftAD",
  edition: "Standard"
})

workspace = aws_workspaces_workspace(:user_desktop, {
  directory_id: directory.directory_id,
  bundle_id: "wsb-92tn3b7gx",
  user_name: "john.doe"
})
```

### With IP Access Control
```ruby
ip_group = aws_workspaces_ip_group(:office_access, {
  group_name: "Office Network",
  group_desc: "Office IP addresses",
  user_rules: [
    {
      ip_rule: "203.0.113.0/24",
      rule_desc: "Main office"
    }
  ]
})

# IP groups are associated at the directory level
# WorkSpaces in that directory inherit the restrictions
```

## Troubleshooting Guide

### Common Issues

1. **WorkSpace Stuck in PENDING State**
   - Check directory health
   - Verify subnet has internet access
   - Ensure security groups allow required ports

2. **User Cannot Connect**
   - Verify user exists in directory
   - Check IP access restrictions
   - Validate network connectivity

3. **Performance Issues**
   - Review compute type selection
   - Check network latency
   - Consider upgrading bundle

### State Transitions

```
PENDING -> AVAILABLE -> RUNNING
           ↓            ↓
        TERMINATING  STOPPING
           ↓            ↓
        TERMINATED   STOPPED
```

## Best Practices

### 1. Cost Management
- Use AUTO_STOP for non-production WorkSpaces
- Set appropriate timeout values (shorter for dev, longer for production)
- Monitor usage patterns to optimize running modes
- Regularly review and terminate unused WorkSpaces

### 2. Security
- Always enable encryption for sensitive workloads
- Use customer-managed KMS keys
- Implement IP access controls
- Enable MFA on the directory
- Regular patching through custom images

### 3. Performance
- Choose appropriate bundle sizes
- Monitor CloudWatch metrics
- Use Performance or PowerPro bundles for resource-intensive applications
- Consider Graphics bundles for CAD/design work

### 4. Disaster Recovery
- Take regular snapshots of user volumes
- Document custom image creation process
- Test restore procedures
- Consider multi-region deployment for critical users

## Monitoring and Metrics

Key CloudWatch metrics to monitor:
- `Available` - WorkSpace availability
- `SessionLaunchTime` - Time to start a session
- `InSessionLatency` - Network latency during session
- `UserConnected` - Connection status
- `ComputeUtilization` - CPU usage
- `RootVolumeDiskUtilization` - Disk usage

## Compliance Considerations

1. **Data Residency**: WorkSpaces store data in the region where deployed
2. **Encryption**: Enable for PCI-DSS, HIPAA compliance
3. **Access Logging**: Enable CloudTrail for audit trails
4. **Network Isolation**: Use dedicated VPCs for compliance boundaries
5. **Patch Management**: Regular updates through custom images