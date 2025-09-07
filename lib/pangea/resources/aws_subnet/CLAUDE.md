# AWS Subnet Resource Implementation

## Overview

The AWS Subnet resource provides type-safe subnet creation within VPCs with intelligent default handling and computed subnet properties.

## Architecture

### Function Signature
```ruby
aws_subnet(name, attributes) -> ResourceReference
```

### Type System
The Subnet resource uses `SubnetAttributes` dry-struct for runtime validation:

```ruby
class SubnetAttributes < Dry::Struct
  attribute :vpc_id, Types::String
  attribute :cidr_block, Types::CidrBlock
  attribute :availability_zone, Types::AwsAvailabilityZone
  attribute :map_public_ip_on_launch, Types::Bool.default(false)
  attribute :tags, Types::AwsTags.default({})
end
```

### Validation Features

1. **VPC Reference Validation**: Ensures valid VPC ID format
2. **CIDR Block Validation**: Subnet-specific CIDR size validation (/16 to /28)
3. **Availability Zone Format**: AWS AZ naming pattern validation
4. **Public IP Mapping**: Boolean validation for public IP assignment
5. **Tags Validation**: Symbol keys, string values

## Implementation Details

### Terraform Synthesis
The resource function uses terraform-synthesizer to generate valid Terraform JSON:

```ruby
resource(:aws_subnet, name) do
  vpc_id subnet_attrs.vpc_id
  cidr_block subnet_attrs.cidr_block
  availability_zone subnet_attrs.availability_zone
  map_public_ip_on_launch subnet_attrs.map_public_ip_on_launch
  
  if subnet_attrs.tags.any?
    tags do
      subnet_attrs.tags.each do |key, value|
        public_send(key, value)
      end
    end
  end
end
```

### Output References
The function returns a ResourceReference with all available Subnet outputs:

- `id`: Subnet identifier for use in EC2 instances, NAT gateways, etc.
- `arn`: Amazon Resource Name for IAM policies and service integrations
- `availability_zone`: The AZ where the subnet is located
- `availability_zone_id`: AZ unique identifier (different from name)
- `cidr_block`: The subnet's CIDR block (computed from input)
- `vpc_id`: Parent VPC identifier
- `owner_id`: AWS account ID that owns the subnet

### Computed Properties

Subnets include rich computed properties via `SubnetComputedAttributes`:

```ruby
subnet_ref.computed_attributes.is_public?        # Public IP assignment check
subnet_ref.computed_attributes.subnet_type       # "public" or "private"  
subnet_ref.computed_attributes.ip_capacity       # Available IP addresses
subnet_ref.computed_attributes.cidr_size         # Network size (e.g., "/24")
```

## Error Handling

### Validation Errors
- `Dry::Struct::Error`: Invalid attribute types, CIDR constraints
- `ArgumentError`: Missing required attributes
- `Types::ConstraintError`: Invalid CIDR format or availability zone

### Common Validation Examples
```ruby
# Invalid CIDR for subnet (too small)
aws_subnet(:invalid, {
  vpc_id: vpc.id,
  cidr_block: "10.0.0.0/10",  # Too large for subnet
  availability_zone: "us-east-1a"
})
# Raises: Dry::Struct::Error

# Invalid availability zone format
aws_subnet(:invalid, {
  vpc_id: vpc.id,
  cidr_block: "10.0.1.0/24",
  availability_zone: "invalid-az"
})
# Raises: Dry::Types::ConstraintError
```

## Usage Patterns

### Basic Public Subnet
```ruby
public_subnet = aws_subnet(:public, {
  vpc_id: vpc.id,
  cidr_block: "10.0.1.0/24",
  availability_zone: "us-east-1a",
  map_public_ip_on_launch: true,
  tags: { 
    Name: "public-subnet-1a", 
    Type: "public" 
  }
})
```

### Basic Private Subnet  
```ruby
private_subnet = aws_subnet(:private, {
  vpc_id: vpc.id,
  cidr_block: "10.0.2.0/24", 
  availability_zone: "us-east-1a",
  tags: { 
    Name: "private-subnet-1a", 
    Type: "private"
  }
})
```

### Multi-AZ Subnet Pattern
```ruby
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
base_cidr = "10.0"

availability_zones.each_with_index do |az, index|
  # Public subnets (10.0.1.0/24, 10.0.2.0/24, ...)
  aws_subnet(:"public_#{index}", {
    vpc_id: vpc.id,
    cidr_block: "#{base_cidr}.#{index + 1}.0/24",
    availability_zone: az,
    map_public_ip_on_launch: true,
    tags: { 
      Name: "public-subnet-#{az}", 
      Type: "public" 
    }
  })
  
  # Private subnets (10.0.10.0/24, 10.0.11.0/24, ...)  
  aws_subnet(:"private_#{index}", {
    vpc_id: vpc.id,
    cidr_block: "#{base_cidr}.#{index + 10}.0/24",
    availability_zone: az,
    tags: { 
      Name: "private-subnet-#{az}", 
      Type: "private" 
    }
  })
end
```

## Testing Considerations

### Unit Testing with terraform-synthesizer
```ruby
RSpec.describe 'aws_subnet function' do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:vpc_ref) { "${aws_vpc.test.id}" }
  
  it 'synthesizes valid terraform with required attributes' do
    result = nil
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      result = aws_subnet(:test, {
        vpc_id: vpc_ref,
        cidr_block: "10.0.1.0/24",
        availability_zone: "us-east-1a"
      })
    end
    
    # Verify function result
    expect(result).to be_a(Pangea::Resources::ResourceReference)
    expect(result.type).to eq('aws_subnet')
    
    # Verify terraform synthesis  
    tf_json = synthesizer.synthesis
    expect(tf_json[:resource][:aws_subnet]).to have_key(:test)
    
    subnet_config = tf_json[:resource][:aws_subnet][:test]
    expect(subnet_config[:vpc_id]).to eq(vpc_ref)
    expect(subnet_config[:cidr_block]).to eq("10.0.1.0/24")
    expect(subnet_config[:availability_zone]).to eq("us-east-1a")
    expect(subnet_config[:map_public_ip_on_launch]).to be false
  end
  
  it 'handles public subnet configuration' do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      aws_subnet(:public, {
        vpc_id: vpc_ref,
        cidr_block: "10.0.1.0/24", 
        availability_zone: "us-east-1a",
        map_public_ip_on_launch: true
      })
    end
    
    tf_json = synthesizer.synthesis
    subnet_config = tf_json[:resource][:aws_subnet][:public]
    expect(subnet_config[:map_public_ip_on_launch]).to be true
  end
end
```

### Integration Testing
Subnet resources should be tested with:
- Valid CIDR ranges within VPC CIDR blocks
- All supported availability zones
- Public and private subnet configurations
- Tag application and formatting
- Error conditions for invalid CIDRs and AZs
- Terraform synthesis output verification

## CIDR Planning Considerations

### Subnet Size Guidelines
- `/24`: 256 IPs (251 usable) - Standard for most applications
- `/23`: 512 IPs (507 usable) - Large applications, container workloads  
- `/25`: 128 IPs (123 usable) - Small applications, development
- `/26`: 64 IPs (59 usable) - Specialized use cases
- `/27`: 32 IPs (27 usable) - Very small workloads
- `/28`: 16 IPs (11 usable) - Minimum size, specialized networking

### IP Address Reservations
AWS reserves 5 IP addresses in each subnet:
- First IP (network address)
- Second IP (VPC router)
- Third IP (DNS resolver)
- Fourth IP (future use)
- Last IP (broadcast address)

## Performance Notes

- Type validation occurs at function call time
- Computed properties are calculated on-demand
- Terraform synthesis is deferred until template evaluation
- CIDR validation includes format and size checking

## Dependencies

- `pangea/resources/base`: Base resource functionality
- `pangea/resources/reference`: ResourceReference class
- `pangea/resources/aws_subnet/types`: Subnet-specific type definitions
- `dry-struct`: Runtime type validation
- `terraform-synthesizer`: Terraform JSON generation

## Common Integration Patterns

### With EC2 Instances
```ruby
subnet = aws_subnet(:web, {
  vpc_id: vpc.id,
  cidr_block: "10.0.1.0/24",
  availability_zone: "us-east-1a",
  map_public_ip_on_launch: true
})

instance = aws_instance(:web_server, {
  ami: "ami-12345678",
  instance_type: "t3.micro",
  subnet_id: subnet.id  # Reference subnet
})
```

### With NAT Gateways
```ruby
# Public subnet for NAT Gateway
public_subnet = aws_subnet(:public, {
  vpc_id: vpc.id,
  cidr_block: "10.0.1.0/24", 
  availability_zone: "us-east-1a",
  map_public_ip_on_launch: true
})

# NAT Gateway in public subnet
nat_gateway = aws_nat_gateway(:main, {
  subnet_id: public_subnet.id
})
```

## Future Enhancements

1. **IPv6 Support**: Add IPv6 CIDR block attributes
2. **Subnet Sharing**: Support for shared subnets across accounts
3. **Outpost Integration**: Support for AWS Outpost subnets
4. **Network ACL Integration**: Automatic network ACL associations
5. **Route Table Integration**: Automatic route table associations
6. **Cost Optimization**: Subnet-level cost analysis and recommendations