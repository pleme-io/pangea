# AWS Network Interface Implementation Documentation

## Overview

This directory contains the implementation for the `aws_network_interface` resource function, providing type-safe creation and management of AWS Elastic Network Interface (ENI) resources through terraform-synthesizer integration.

## Implementation Architecture

### Core Components

#### 1. Resource Function (`resource.rb`)
The main `aws_network_interface` function that:
- Accepts a symbol name and attributes hash
- Validates attributes using dry-struct types
- Generates terraform resource blocks via terraform-synthesizer
- Returns ResourceReference with computed outputs and properties

#### 2. Type Definitions (`types.rb`)
NetworkInterfaceAttributes dry-struct defining:
- Required attributes: `subnet_id`
- Optional attributes: `description`, `private_ips`, `private_ips_count`, `security_groups`, `source_dest_check`, `interface_type`, IPv4/IPv6 configuration, `attachment`
- Custom validations for IP conflicts and attachment requirements
- Computed properties for interface state and capabilities

#### 3. Documentation
- **CLAUDE.md** (this file): Implementation details for developers
- **README.md**: User-facing documentation with examples

## Technical Implementation Details

### Elastic Network Interface (ENI) Overview
AWS ENIs are virtual network cards that can be:
- Attached to EC2 instances
- Used for multi-homing (multiple network interfaces)
- Preserved and moved between instances
- Configured with multiple private IPs
- Associated with security groups

### Key Features
- **Multiple IPs**: Support for multiple private IPv4 and IPv6 addresses
- **Interface Types**: Standard, EFA (Elastic Fabric Adapter), trunk, branch
- **Attachment**: Can be attached at instance launch or later
- **Source/Dest Check**: Can be disabled for NAT/routing instances
- **IPv6 Support**: Full dual-stack networking capabilities

### Type Validation Logic

```ruby
class NetworkInterfaceAttributes < Dry::Struct
  # IP conflict validation
  if attrs.private_ips.any? && attrs.private_ips_count
    raise Dry::Struct::Error, "Cannot specify both 'private_ips' and 'private_ips_count'"
  end
  
  # IPv6 conflict validation
  if attrs.ipv6_addresses.any? && attrs.ipv6_address_count
    raise Dry::Struct::Error, "Cannot specify both 'ipv6_addresses' and 'ipv6_address_count'"
  end
  
  # Attachment validation
  if attrs.attachment.any?
    required_keys = [:instance, :device_index]
    missing_keys = required_keys - attrs.attachment.keys
    unless missing_keys.empty?
      raise Dry::Struct::Error, "Attachment requires: #{missing_keys.join(', ')}"
    end
  end
end
```

### Terraform Synthesis

The resource function generates terraform JSON through terraform-synthesizer:

```ruby
resource(:aws_network_interface, name) do
  # Required
  subnet_id attrs.subnet_id
  
  # Optional network configuration
  description attrs.description if attrs.description
  private_ips attrs.private_ips if attrs.private_ips.any?
  private_ips_count attrs.private_ips_count if attrs.private_ips_count
  security_groups attrs.security_groups if attrs.security_groups.any?
  source_dest_check attrs.source_dest_check unless attrs.source_dest_check.nil?
  interface_type attrs.interface_type if attrs.interface_type
  
  # IPv4/IPv6 configuration
  ipv4_prefix_count attrs.ipv4_prefix_count if attrs.ipv4_prefix_count
  ipv4_prefixes attrs.ipv4_prefixes if attrs.ipv4_prefixes.any?
  ipv6_address_count attrs.ipv6_address_count if attrs.ipv6_address_count
  ipv6_addresses attrs.ipv6_addresses if attrs.ipv6_addresses.any?
  
  # Attachment at creation
  if attrs.attachment.any?
    attachment do
      instance attrs.attachment[:instance]
      device_index attrs.attachment[:device_index]
    end
  end
  
  # Tags
  if attrs.tags.any?
    tags do
      attrs.tags.each do |key, value|
        public_send(key, value)
      end
    end
  end
end
```

### ResourceReference Return Value

The function returns a ResourceReference providing:

#### Terraform Outputs
- `id`: The ENI ID
- `arn`: The ENI ARN
- `mac_address`: MAC address of the interface
- `private_dns_name`: Private DNS hostname
- `private_ip`: Primary private IP address
- `private_ips`: All private IP addresses
- `ipv6_addresses`: IPv6 addresses
- `security_groups`: Security group IDs
- `subnet_id`: Subnet ID
- `owner_id`: AWS account ID
- `interface_type`: Type of interface
- `attachment`: Attachment details

#### Computed Properties
- `attached_at_creation`: Whether ENI was attached at creation
- `explicit_private_ips`: Whether using explicit IP list
- `ipv6_enabled`: Whether IPv6 is configured
- `interface_type_name`: Human-readable interface type

## Integration Patterns

### 1. Basic ENI Creation
```ruby
template :basic_eni do
  eni = aws_network_interface(:app, {
    subnet_id: private_subnet.id,
    description: "Application ENI",
    security_groups: [app_sg.id]
  })
end
```

### 2. Multi-IP Configuration
```ruby
template :multi_ip do
  # Explicit IPs
  eni = aws_network_interface(:multi, {
    subnet_id: subnet.id,
    private_ips: ["10.0.1.10", "10.0.1.11", "10.0.1.12"]
  })
  
  # Auto-assign count
  eni2 = aws_network_interface(:auto, {
    subnet_id: subnet.id,
    private_ips_count: 3
  })
end
```

### 3. Attached ENI
```ruby
template :attached do
  instance = aws_instance(:app, { ... })
  
  eni = aws_network_interface(:secondary, {
    subnet_id: subnet.id,
    attachment: {
      instance: instance.id,
      device_index: 1
    }
  })
end
```

### 4. EFA Interface
```ruby
template :hpc do
  efa_eni = aws_network_interface(:efa, {
    subnet_id: compute_subnet.id,
    interface_type: "efa",
    security_groups: [hpc_sg.id]
  })
end
```

## Error Handling and Validation

### Common Validation Errors

#### 1. IP Specification Conflicts
```ruby
# ERROR: Both explicit IPs and count
aws_network_interface(:bad, {
  subnet_id: "subnet-123",
  private_ips: ["10.0.1.10"],
  private_ips_count: 3
})
# Raises: "Cannot specify both 'private_ips' and 'private_ips_count'"
```

#### 2. Incomplete Attachment
```ruby
# ERROR: Missing device_index
aws_network_interface(:bad, {
  subnet_id: "subnet-123",
  attachment: { instance: "i-123" }
})
# Raises: "Attachment requires: device_index"
```

#### 3. IPv6 Conflicts
```ruby
# ERROR: Both addresses and count
aws_network_interface(:bad, {
  subnet_id: "subnet-123",
  ipv6_addresses: ["2001:db8::1"],
  ipv6_address_count: 2
})
# Raises: "Cannot specify both 'ipv6_addresses' and 'ipv6_address_count'"
```

## Testing Strategy

### Unit Tests
```ruby
RSpec.describe Pangea::Resources::AWS do
  describe "#aws_network_interface" do
    it "creates ENI with required attributes" do
      eni_ref = aws_network_interface(:test, {
        subnet_id: "subnet-12345"
      })
      
      expect(eni_ref).to be_a(ResourceReference)
      expect(eni_ref.type).to eq('aws_network_interface')
    end
    
    it "validates IP specification conflicts" do
      expect {
        aws_network_interface(:test, {
          subnet_id: "subnet-12345",
          private_ips: ["10.0.1.10"],
          private_ips_count: 3
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both/)
    end
    
    it "determines interface capabilities" do
      efa_eni = aws_network_interface(:test, {
        subnet_id: "subnet-12345",
        interface_type: "efa"
      })
      
      expect(efa_eni.interface_type_name).to eq("Elastic Fabric Adapter")
    end
  end
end
```

## Security Best Practices

### 1. Security Group Management
- Apply least-privilege security groups
- Use separate ENIs for different security zones
- Regularly audit security group rules

### 2. IP Address Security
- Document and reserve IP ranges
- Use explicit IPs for critical services
- Monitor for IP conflicts

### 3. Source/Dest Check
- Keep enabled unless specifically needed (NAT/routing)
- Document why it's disabled
- Regular security reviews

### 4. Interface Isolation
- Use multiple ENIs for network isolation
- Separate management and data traffic
- Apply appropriate IAM policies

## Future Enhancements

### 1. Advanced Attachment Management
- Support for hot-attach/detach workflows
- Attachment state monitoring
- Automatic failover patterns

### 2. Enhanced IPv6 Support
- IPv6 prefix delegation
- Dual-stack templates
- IPv6-only configurations

### 3. Performance Features
- SR-IOV configuration
- Placement group integration
- Network performance metrics

### 4. Monitoring Integration
- CloudWatch metrics for ENI
- VPC Flow Logs configuration
- Network performance alerts

This implementation provides comprehensive ENI management within the Pangea resource system, emphasizing flexibility, security, and proper network isolation patterns.
