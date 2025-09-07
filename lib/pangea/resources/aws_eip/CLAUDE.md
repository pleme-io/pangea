# AWS Elastic IP Implementation Documentation

## Overview

This directory contains the implementation for the `aws_eip` resource function, providing type-safe creation and management of AWS Elastic IP addresses through terraform-synthesizer integration.

## Implementation Architecture

### Core Components

#### 1. Resource Function (`resource.rb`)
The main `aws_eip` function that:
- Accepts a symbol name and attributes hash
- Validates attributes using dry-struct types
- Generates terraform resource blocks via terraform-synthesizer
- Returns ResourceReference with computed outputs and properties

#### 2. Type Definitions (`types.rb`)
EipAttributes dry-struct defining:
- Required attributes: `domain` (defaults to "vpc")
- Optional attributes: `instance`, `network_interface`, `associate_with_private_ip`, `customer_owned_ipv4_pool`, `network_border_group`, `public_ipv4_pool`
- Custom validations for mutually exclusive options
- Computed properties for EIP state

#### 3. Documentation
- **CLAUDE.md** (this file): Implementation details for developers
- **README.md**: User-facing documentation with examples

## Technical Implementation Details

### Elastic IP Overview
AWS Elastic IPs are static IPv4 addresses designed for dynamic cloud computing. They can be:
- Associated with EC2 instances
- Associated with network interfaces
- Reserved for future use
- Moved between instances/interfaces

### Key Features
- **Domains**: "vpc" (modern VPC) or "standard" (EC2-Classic, deprecated)
- **Association**: Can be associated with instances or network interfaces
- **Customer-Owned IPs**: Support for customer-owned IP pools (Outposts)
- **Network Border Groups**: For multi-region deployments

### Type Validation Logic

```ruby
class EipAttributes < Dry::Struct
  # Domain validation
  attribute :domain, Types::String.enum("vpc", "standard").default("vpc")
  
  # Association options (mutually exclusive)
  attribute? :instance, Types::String.optional
  attribute? :network_interface, Types::String.optional
  
  # Custom validation rules
  def self.new(attributes = {})
    attrs = super(attributes)
    
    # Cannot associate with both instance and network interface
    if attrs.instance && attrs.network_interface
      raise Dry::Struct::Error, "Cannot specify both 'instance' and 'network_interface'"
    end
    
    # Private IP requires network interface
    if attrs.associate_with_private_ip && !attrs.network_interface
      raise Dry::Struct::Error, "'associate_with_private_ip' requires 'network_interface'"
    end
    
    attrs
  end
end
```

### Terraform Synthesis

The resource function generates terraform JSON through terraform-synthesizer:

```ruby
resource(:aws_eip, name) do
  domain attrs.domain
  
  # Optional associations
  instance attrs.instance if attrs.instance
  network_interface attrs.network_interface if attrs.network_interface
  associate_with_private_ip attrs.associate_with_private_ip if attrs.associate_with_private_ip
  
  # Advanced options
  customer_owned_ipv4_pool attrs.customer_owned_ipv4_pool if attrs.customer_owned_ipv4_pool
  network_border_group attrs.network_border_group if attrs.network_border_group
  public_ipv4_pool attrs.public_ipv4_pool if attrs.public_ipv4_pool
  
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
- `id`: The EIP allocation ID
- `allocation_id`: Allocation ID for VPC EIPs
- `association_id`: ID of the association
- `carrier_ip`: Carrier IP address (Wavelength)
- `customer_owned_ip`: Customer-owned IP
- `domain`: "vpc" or "standard"
- `instance`: Associated instance ID
- `network_interface`: Associated ENI ID
- `private_dns`: Private DNS hostname
- `private_ip`: Private IP address
- `public_dns`: Public DNS hostname
- `public_ip`: The actual Elastic IP address
- `public_ipv4_pool`: Public IPv4 pool
- `vpc`: Boolean indicating VPC EIP

#### Computed Properties
- `vpc`: Whether this is a VPC EIP
- `associated`: Whether EIP is associated
- `customer_owned`: Whether using customer-owned IP
- `association_type`: Type of association (`:instance`, `:network_interface`, or `:unassociated`)

## Integration Patterns

### 1. Basic EIP Allocation
```ruby
template :basic_eip do
  # Allocate an Elastic IP
  public_ip = aws_eip(:web_ip, {
    domain: "vpc",
    tags: {
      Name: "web-server-ip",
      Environment: "production"
    }
  })
  
  output :elastic_ip do
    value public_ip.public_ip
    description "The allocated Elastic IP address"
  end
end
```

### 2. EIP with Instance Association
```ruby
template :instance_with_eip do
  # Create instance
  instance = aws_instance(:web, {
    ami: "ami-12345678",
    instance_type: "t3.micro",
    subnet_id: public_subnet.id
  })
  
  # Create and associate EIP
  eip = aws_eip(:web_eip, {
    domain: "vpc",
    instance: instance.id,
    tags: {
      Name: "web-server-eip",
      Instance: instance.id
    }
  })
end
```

### 3. EIP with Network Interface
```ruby
template :eni_with_eip do
  # Create network interface
  eni = aws_network_interface(:secondary, {
    subnet_id: public_subnet.id,
    security_groups: [web_sg.id]
  })
  
  # Associate EIP with specific private IP
  eip = aws_eip(:eni_eip, {
    domain: "vpc",
    network_interface: eni.id,
    associate_with_private_ip: eni.private_ip,
    tags: {
      Name: "secondary-interface-eip"
    }
  })
end
```

### 4. EIP Pool Reservation
```ruby
template :eip_pool do
  # Reserve multiple EIPs for future use
  eip_pool = (1..5).map do |i|
    aws_eip(:"reserved_#{i}", {
      domain: "vpc",
      tags: {
        Name: "reserved-ip-#{i}",
        Status: "unassigned",
        Pool: "web-servers"
      }
    })
  end
  
  output :available_ips do
    value eip_pool.map(&:public_ip)
    description "Pool of reserved Elastic IPs"
  end
end
```

## Error Handling and Validation

### Common Validation Errors

#### 1. Conflicting Associations
```ruby
# ERROR: Both instance and network_interface
aws_eip(:bad_eip, {
  instance: "i-12345",
  network_interface: "eni-67890"
})
# Raises: Dry::Struct::Error: "Cannot specify both 'instance' and 'network_interface'"
```

#### 2. Private IP Without ENI
```ruby
# ERROR: Private IP requires network interface
aws_eip(:bad_private, {
  associate_with_private_ip: "10.0.1.5"
})
# Raises: Dry::Struct::Error: "'associate_with_private_ip' requires 'network_interface'"
```

#### 3. Conflicting IP Pools
```ruby
# ERROR: Both customer and public pools
aws_eip(:bad_pool, {
  customer_owned_ipv4_pool: "ipv4pool-coip-12345",
  public_ipv4_pool: "amazon"
})
# Raises: Dry::Struct::Error: "Cannot specify both pools"
```

## Testing Strategy

### Unit Tests
```ruby
RSpec.describe Pangea::Resources::AWS do
  describe "#aws_eip" do
    it "creates EIP with default VPC domain" do
      eip_ref = aws_eip(:test, {})
      
      expect(eip_ref).to be_a(ResourceReference)
      expect(eip_ref.type).to eq('aws_eip')
      expect(eip_ref.vpc?).to be true
    end
    
    it "validates association conflicts" do
      expect {
        aws_eip(:test, {
          instance: "i-12345",
          network_interface: "eni-67890"
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both/)
    end
    
    it "determines association type" do
      instance_eip = aws_eip(:test1, { instance: "i-12345" })
      eni_eip = aws_eip(:test2, { network_interface: "eni-67890" })
      unassoc_eip = aws_eip(:test3, {})
      
      expect(instance_eip.association_type).to eq(:instance)
      expect(eni_eip.association_type).to eq(:network_interface)
      expect(unassoc_eip.association_type).to eq(:unassociated)
    end
  end
end
```

## Security Best Practices

### 1. EIP Management
- Avoid leaving EIPs unassociated (charges apply)
- Use tags to track EIP ownership and purpose
- Regular audits for unused EIPs
- Consider using dynamic IPs when static not required

### 2. Association Security
- Restrict who can associate/disassociate EIPs via IAM
- Monitor EIP association changes with CloudTrail
- Use security groups to control traffic to EIP

### 3. Cost Optimization
- Release unused EIPs promptly
- Use EIP only when static IP is required
- Consider IPv6 for public addressing
- Monitor EIP usage and costs

## Future Enhancements

### 1. EIP Association Resource
- Separate resource for managing associations
- Support for re-association workflows
- Association history tracking

### 2. IPv6 Support
- Support for IPv6 addressing
- Dual-stack configurations
- IPv6-only options

### 3. Advanced Features
- BYOIP (Bring Your Own IP) support
- Multi-region EIP management
- EIP warming for faster associations

### 4. Cost Management
- Cost estimation based on association status
- Alerts for unassociated EIPs
- Usage analytics

This implementation provides comprehensive Elastic IP management within the Pangea resource system, emphasizing proper association handling and cost-conscious practices.