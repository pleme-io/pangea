# AWS EFS Mount Target Implementation

## Overview

The AWS EFS Mount Target resource creates network interfaces within VPC subnets to provide access to EFS file systems. This implementation provides type-safe configuration with comprehensive validation for IP addresses, security groups, and network topology.

## Implementation Architecture

### Type System

The implementation uses Pangea's type-safe resource pattern with network-focused validation:

```ruby
class EfsMountTargetAttributes < Dry::Struct
  # Core network configuration
  attribute :file_system_id, Resources::Types::String
  attribute :subnet_id, Resources::Types::String
  
  # Optional network configuration
  attribute :ip_address, Resources::Types::String.optional
  attribute :security_groups, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
```

### Network Validation Logic

The type system includes sophisticated validation for network configuration:

1. **IP Address Validation**: Ensures valid IPv4 format and private IP range compliance
2. **Security Group Limits**: Enforces AWS limit of 5 security groups per mount target
3. **Network Topology**: Validates proper VPC subnet and file system associations
4. **Cost Awareness**: Provides cost estimation for cross-AZ data transfer

### Resource Function Interface

```ruby
def aws_efs_mount_target(name, attributes = {})
  validated_attrs = AWS::Types::EfsMountTargetAttributes.new(attributes)
  # Process network configuration
  # Create terraform mount target resource
  # Return ResourceReference with network outputs
end
```

## Key Features

### Network Interface Management

The implementation handles AWS EFS mount target network interface creation:

- **ENI Creation**: Automatic creation of Elastic Network Interface in specified subnet
- **IP Assignment**: Support for automatic or custom IP address assignment
- **Security Groups**: Association of up to 5 security groups for traffic control
- **AZ Mapping**: Automatic availability zone detection and configuration

### VPC Integration

Comprehensive support for VPC network topology:

- **Subnet Association**: Mount targets are created within specific VPC subnets
- **Multi-AZ Support**: Enables creation of mount targets across multiple availability zones
- **Private Subnets**: Optimized for private subnet deployment patterns
- **Network Routing**: Proper integration with VPC routing and DNS resolution

### High Availability Patterns

Built-in support for high availability deployment patterns:

- **Cross-AZ Deployment**: Facilitates mount target creation across multiple AZs
- **Fault Tolerance**: Each AZ gets its own mount target for fault isolation
- **Regional Access**: Support for regional DNS names for automatic failover
- **One Zone Optimization**: Special handling for One Zone EFS configurations

## Custom Validation Features

### IP Address Validation

```ruby
def self.new(attributes)
  if attrs[:ip_address]
    ip = attrs[:ip_address]
    unless ip.match?(/\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/)
      raise Dry::Struct::Error, "ip_address must be a valid IPv4 address, got '#{ip}'"
    end
    
    # Validate private IP range requirement
    # ... private range validation logic
  end
end
```

### Security Group Limits

```ruby
if attrs[:security_groups] && attrs[:security_groups].length > 5
  raise Dry::Struct::Error, "Maximum of 5 security groups allowed for EFS mount targets"
end
```

## Computed Properties

The implementation includes operational insight properties:

### Network Configuration Analysis

```ruby
def has_custom_ip?
  !ip_address.nil?
end

def is_fully_configured?
  !file_system_id.empty? && !subnet_id.empty? && !security_groups.empty?
end
```

### Cost Estimation

```ruby
def estimated_data_transfer_cost_per_gb
  {
    cross_az_data_transfer: 0.01,
    same_az_data_transfer: 0.00,
    note: "Actual costs depend on file system type and access patterns"
  }
end
```

## Resource Outputs

The ResourceReference provides comprehensive network information:

### Network Identifiers
- `id`: Mount target unique identifier
- `network_interface_id`: ENI ID for network troubleshooting
- `ip_address`: Actual IP address assigned to mount target

### DNS Configuration
- `dns_name`: Regional DNS name for mounting
- `mount_target_dns_name`: Mount target specific DNS name

### Topology Information
- `availability_zone_id`, `availability_zone_name`: AZ placement information
- `subnet_id`: Subnet association confirmation
- `security_groups`: Applied security groups

## Integration Patterns

### With EFS File Systems

```ruby
# File system reference integration
efs = aws_efs_file_system(:storage, { ... })

mount = aws_efs_mount_target(:mount_a, {
  file_system_id: efs.id,  # Direct reference to file system
  subnet_id: subnet_ref.id,
  security_groups: [sg_ref.id]
})
```

### With VPC Infrastructure

```ruby
# VPC subnet integration
vpc = aws_vpc(:main, { cidr_block: "10.0.0.0/16" })
subnet = aws_subnet(:private_a, {
  vpc_id: vpc.id,
  cidr_block: "10.0.1.0/24",
  availability_zone: "us-east-1a"
})

mount = aws_efs_mount_target(:mount, {
  file_system_id: efs_ref.id,
  subnet_id: subnet.id,  # References created subnet
  security_groups: [sg_ref.id]
})
```

### With Security Groups

```ruby
# Security group for EFS access
efs_sg = aws_security_group(:efs_access, {
  name: "efs-access",
  vpc_id: vpc_ref.id,
  ingress_rules: [{
    from_port: 2049,
    to_port: 2049,
    protocol: "tcp",
    security_groups: [client_sg_ref.id]
  }]
})

mount = aws_efs_mount_target(:mount, {
  file_system_id: efs_ref.id,
  subnet_id: subnet_ref.id,
  security_groups: [efs_sg.id]  # References security group
})
```

## Production Deployment Patterns

### Multi-AZ High Availability

```ruby
# Deploy mount targets across multiple AZs
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
subnets = {
  "us-east-1a" => private_subnet_a_ref,
  "us-east-1b" => private_subnet_b_ref,
  "us-east-1c" => private_subnet_c_ref
}

availability_zones.each do |az|
  az_suffix = az.split('-').last
  
  aws_efs_mount_target(:"mount_#{az_suffix}", {
    file_system_id: efs_ref.id,
    subnet_id: subnets[az].id,
    security_groups: [
      ref(:aws_security_group, :efs_client, :id),
      ref(:aws_security_group, :monitoring, :id)
    ]
  })
end
```

### Container Platform Integration

```ruby
# Mount targets for container workloads
container_subnets = [
  { name: "ecs_a", subnet: ecs_subnet_a_ref, az: "us-east-1a" },
  { name: "ecs_b", subnet: ecs_subnet_b_ref, az: "us-east-1b" }
]

container_subnets.each do |subnet_config|
  aws_efs_mount_target(:"#{subnet_config[:name]}_mount", {
    file_system_id: container_efs_ref.id,
    subnet_id: subnet_config[:subnet].id,
    security_groups: [
      ref(:aws_security_group, :ecs_tasks, :id),
      ref(:aws_security_group, :efs_access, :id)
    ]
  })
end
```

### One Zone Cost Optimization

```ruby
# Single mount target for One Zone EFS
one_zone_mount = aws_efs_mount_target(:dev_mount, {
  file_system_id: one_zone_efs_ref.id,
  subnet_id: dev_subnet_ref.id,
  ip_address: "10.0.1.100",  # Predictable IP for development
  security_groups: [dev_efs_sg_ref.id]
})
```

## Error Handling

### Network Configuration Errors

The implementation prevents common network misconfigurations:

```ruby
# Invalid IP address format
aws_efs_mount_target(:bad_ip, {
  file_system_id: efs_ref.id,
  subnet_id: subnet_ref.id,
  ip_address: "999.999.999.999"  # Invalid IP - will raise error
})

# Public IP address (not allowed)
aws_efs_mount_target(:public_ip, {
  file_system_id: efs_ref.id,
  subnet_id: subnet_ref.id,
  ip_address: "8.8.8.8"  # Public IP - will raise error
})
```

### Security Group Limits

```ruby
# Too many security groups
aws_efs_mount_target(:too_many_sgs, {
  file_system_id: efs_ref.id,
  subnet_id: subnet_ref.id,
  security_groups: [sg1, sg2, sg3, sg4, sg5, sg6]  # 6 SGs - will raise error
})
```

## Performance Considerations

### Network Topology Impact

- **Cross-AZ Access**: Mount targets in different AZs than clients incur data transfer costs
- **Same-AZ Optimization**: Prefer mount targets in the same AZ as clients when possible
- **Regional DNS**: Use regional DNS names for automatic routing to nearest mount target
- **IP Address Selection**: Custom IPs can impact routing efficiency

### Security Configuration

- **Security Group Rules**: Minimize rules while ensuring necessary access
- **NFS Protocol**: Default NFS is unencrypted - consider TLS for encryption in transit
- **Network ACLs**: Consider subnet-level ACLs for additional security layers
- **VPC Endpoints**: Consider VPC endpoints for EFS API access

## Testing Strategies

### Unit Testing

```ruby
# Test IP validation
expect {
  AWS::Types::EfsMountTargetAttributes.new({
    file_system_id: "fs-12345678",
    subnet_id: "subnet-12345678", 
    ip_address: "invalid-ip"
  })
}.to raise_error(Dry::Struct::Error)
```

### Integration Testing

```ruby
# Test mount target creation with dependencies
mount_target = aws_efs_mount_target(:test_mount, {
  file_system_id: test_efs.id,
  subnet_id: test_subnet.id,
  security_groups: [test_sg.id]
})

expect(mount_target.outputs[:subnet_id]).to eq("${aws_efs_mount_target.test_mount.subnet_id}")
```

## AWS Service Dependencies

The mount target resource requires coordination with:

- **EFS File System**: Must exist before mount target creation
- **VPC Subnet**: Must exist with sufficient available IP addresses
- **Security Groups**: Must exist and have appropriate NFS rules
- **Route Tables**: Must have routes for proper network connectivity
- **DNS Resolution**: Requires VPC DNS resolution enabled

## Operational Considerations

### Monitoring and Observability

- **CloudWatch Metrics**: Mount target performance and connection metrics
- **VPC Flow Logs**: Network traffic analysis and troubleshooting
- **ENI Monitoring**: Network interface performance and health
- **DNS Resolution**: Monitoring DNS query patterns and resolution times

### Maintenance and Updates

- **Security Group Updates**: Changes to security groups affect existing connections
- **Subnet Changes**: Cannot change subnet after mount target creation
- **IP Address Changes**: Cannot change IP address after creation
- **High Availability**: Plan for mount target replacement during maintenance