# AWS WorkSpaces Directory - Implementation Notes

## Resource Overview

The `aws_workspaces_directory` resource registers an existing AWS Directory Service directory for use with Amazon WorkSpaces. This resource acts as a bridge between directory services and the WorkSpaces environment, configuring how WorkSpaces behave within the directory context.

## Architectural Considerations

### Directory Registration Model
- **Not a directory creation**: This resource registers an existing directory
- **One-to-many relationship**: One directory can host many WorkSpaces
- **Configuration inheritance**: Settings apply to all WorkSpaces in the directory
- **Multi-AZ support**: Subnets determine availability zone distribution

### Key Components
1. **Directory Integration**: Links to AWS Managed AD, AD Connector, or Simple AD
2. **Network Configuration**: Subnet placement for WorkSpace instances
3. **Security Policies**: Device access, IP restrictions, user permissions
4. **Default Settings**: Creation properties for new WorkSpaces

## Implementation Details

### Directory ID Validation

```ruby
attribute :directory_id, Resources::Types::String.constrained(
  format: /\Ad-[a-f0-9]{10}\z/
)
```

This ensures only valid AWS Directory Service IDs are accepted.

### Self-Service Permissions Model

```ruby
class SelfServicePermissionsType < Dry::Struct
  attribute :restart_workspace, Resources::Types::String.enum('ENABLED', 'DISABLED')
  attribute :increase_volume_size, Resources::Types::String.enum('ENABLED', 'DISABLED')
  attribute :change_compute_type, Resources::Types::String.enum('ENABLED', 'DISABLED')
  attribute :switch_running_mode, Resources::Types::String.enum('ENABLED', 'DISABLED')
  attribute :rebuild_workspace, Resources::Types::String.enum('ENABLED', 'DISABLED')
end
```

Each permission controls a specific user action in the WorkSpaces client.

### Device Access Control

The implementation provides granular control over client types:

```ruby
def allowed_device_types
  types = []
  types << 'Windows' if device_type_windows == 'ALLOW'
  types << 'macOS' if device_type_osx == 'ALLOW'
  types << 'Web' if device_type_web == 'ALLOW'
  # ... other device types
  types
end
```

### Security Level Assessment

```ruby
def security_level
  score = 0
  score += 2 if custom_security_group_id  # Using custom security group
  score += 1 unless enable_internet_access  # Internet access disabled
  score += 2 unless user_enabled_as_local_administrator  # No local admin
  
  case score
  when 4..5 then :high
  when 2..3 then :medium
  else :low
  end
end
```

## Advanced Usage Patterns

### 1. Environment-Specific Configurations
```ruby
def create_workspaces_directory_for_environment(env, directory_id)
  case env
  when :production
    aws_workspaces_directory(:prod_workspaces, {
      directory_id: directory_id,
      self_service_permissions: {
        restart_workspace: "ENABLED",
        increase_volume_size: "DISABLED",
        change_compute_type: "DISABLED",
        switch_running_mode: "DISABLED",
        rebuild_workspace: "DISABLED"
      },
      workspace_creation_properties: {
        enable_internet_access: false,
        user_enabled_as_local_administrator: false
      },
      workspace_access_properties: {
        device_type_web: "DENY",
        device_type_chrome_os: "DENY"
      }
    })
  when :development
    aws_workspaces_directory(:dev_workspaces, {
      directory_id: directory_id,
      self_service_permissions: {
        restart_workspace: "ENABLED",
        increase_volume_size: "ENABLED",
        change_compute_type: "ENABLED",
        switch_running_mode: "ENABLED",
        rebuild_workspace: "ENABLED"
      },
      workspace_creation_properties: {
        enable_internet_access: true,
        user_enabled_as_local_administrator: true
      }
    })
  end
end
```

### 2. Compliance-Based Configuration
```ruby
def configure_workspaces_for_compliance(compliance_type, directory_id)
  base_config = {
    directory_id: directory_id,
    workspace_creation_properties: {
      enable_maintenance_mode: true
    }
  }
  
  case compliance_type
  when :hipaa
    aws_workspaces_directory(:hipaa_workspaces, base_config.merge({
      workspace_creation_properties: {
        enable_internet_access: false,
        user_enabled_as_local_administrator: false,
        enable_maintenance_mode: true
      },
      workspace_access_properties: {
        device_type_web: "DENY",
        device_type_android: "DENY",
        device_type_ios: "DENY"
      },
      self_service_permissions: {
        restart_workspace: "ENABLED",
        increase_volume_size: "DISABLED",
        change_compute_type: "DISABLED",
        switch_running_mode: "DISABLED",
        rebuild_workspace: "DISABLED"
      }
    }))
  when :pci_dss
    aws_workspaces_directory(:pci_workspaces, base_config.merge({
      workspace_creation_properties: {
        enable_internet_access: false,
        user_enabled_as_local_administrator: false
      },
      workspace_access_properties: {
        device_type_web: "DENY"
      }
    }))
  end
end
```

### 3. Geographic Access Patterns
```ruby
def configure_regional_access(region_type, directory_id)
  case region_type
  when :global
    # Allow all device types for global access
    aws_workspaces_directory(:global_access, {
      directory_id: directory_id,
      workspace_access_properties: {
        device_type_windows: "ALLOW",
        device_type_osx: "ALLOW",
        device_type_web: "ALLOW",
        device_type_ios: "ALLOW",
        device_type_android: "ALLOW",
        device_type_chrome_os: "ALLOW",
        device_type_zero_client: "ALLOW",
        device_type_linux: "ALLOW"
      }
    })
  when :office_only
    # Restrict to traditional desktop clients
    aws_workspaces_directory(:office_access, {
      directory_id: directory_id,
      workspace_access_properties: {
        device_type_windows: "ALLOW",
        device_type_osx: "ALLOW",
        device_type_web: "DENY",
        device_type_ios: "DENY",
        device_type_android: "DENY",
        device_type_chrome_os: "DENY",
        device_type_zero_client: "ALLOW",
        device_type_linux: "ALLOW"
      }
    })
  when :mobile_workforce
    # Optimize for mobile access
    aws_workspaces_directory(:mobile_access, {
      directory_id: directory_id,
      workspace_access_properties: {
        device_type_windows: "ALLOW",
        device_type_osx: "ALLOW",
        device_type_web: "ALLOW",
        device_type_ios: "ALLOW",
        device_type_android: "ALLOW",
        device_type_chrome_os: "ALLOW",
        device_type_zero_client: "DENY",
        device_type_linux: "DENY"
      }
    })
  end
end
```

## Integration Patterns

### With AWS Managed Microsoft AD
```ruby
# Create the directory first
ad_directory = aws_directory_service_directory(:corp_ad, {
  name: "corp.example.com",
  password: vault_secret.value,
  type: "MicrosoftAD",
  edition: "Enterprise"
})

# Register for WorkSpaces
workspaces_config = aws_workspaces_directory(:corp_workspaces, {
  directory_id: ad_directory.directory_id,
  subnet_ids: [private_subnet_a.id, private_subnet_b.id],
  workspace_creation_properties: {
    default_ou: "OU=WorkSpaces,OU=Computers,DC=corp,DC=example,DC=com"
  }
})
```

### With IP Access Control
```ruby
# Create IP groups
office_ips = aws_workspaces_ip_group(:office, {
  group_name: "Office Networks",
  user_rules: [
    { ip_rule: "10.0.0.0/8", rule_desc: "Internal network" },
    { ip_rule: "203.0.113.0/24", rule_desc: "Office public IP" }
  ]
})

vpn_ips = aws_workspaces_ip_group(:vpn, {
  group_name: "VPN Access",
  user_rules: [
    { ip_rule: "172.16.0.0/12", rule_desc: "VPN range" }
  ]
})

# Associate with directory
aws_workspaces_directory(:restricted_access, {
  directory_id: directory.directory_id,
  ip_group_ids: [office_ips.id, vpn_ips.id]
})
```

## Troubleshooting Guide

### Common Issues

1. **Registration Fails**
   - Verify directory is in ACTIVE state
   - Check IAM permissions for WorkSpaces service
   - Ensure subnets are in the same VPC as directory

2. **WorkSpace Creation Fails After Registration**
   - Validate security group rules
   - Check subnet routing and internet gateway
   - Verify OU exists if specified

3. **Device Access Not Working**
   - Confirm device type is set to ALLOW
   - Check client version compatibility
   - Verify network connectivity

### Directory State Requirements

```
Directory States:
- ACTIVE: Can register with WorkSpaces
- CREATING: Cannot register yet
- DELETING: Registration will fail
- FAILED: Must fix directory first
```

## Best Practices

### 1. Network Design
- Use private subnets for WorkSpaces
- Implement NAT gateways for internet access
- Place WorkSpaces in multiple AZs
- Use VPC endpoints for AWS services

### 2. Security Configuration
- Disable unnecessary device types
- Implement IP-based restrictions
- Use custom security groups
- Disable local administrator by default

### 3. User Experience
- Enable appropriate self-service options
- Set reasonable auto-stop timeouts
- Consider time zones for global deployments
- Plan for maintenance windows

### 4. Compliance Considerations
- Document device access policies
- Implement audit logging
- Regular security reviews
- Maintain access control lists

## Performance Optimization

### Subnet Selection
```ruby
# Optimize for user geography
aws_workspaces_directory(:optimized_placement, {
  directory_id: directory.directory_id,
  subnet_ids: [
    us_east_1a_subnet.id,  # Primary user location
    us_east_1b_subnet.id   # Failover location
  ]
})
```

### Connection Optimization
- Place WorkSpaces close to users
- Use AWS Direct Connect for on-premises
- Implement Connection Alias for custom domains
- Monitor CloudWatch metrics for latency

## Monitoring Considerations

Key metrics to track:
- Directory registration status
- Subnet availability
- IP group associations
- Self-service usage patterns
- Device type connections
- Failed connection attempts

## Migration Strategies

### From On-Premises VDI
1. Set up AD Connector to existing AD
2. Register directory with conservative settings
3. Gradually enable features
4. Monitor and adjust based on usage

### Between AWS Regions
1. Create new directory in target region
2. Configure similar settings
3. Use AWS Application Migration Service
4. Update DNS and connection endpoints