# AWS VPC Resource Implementation

## Overview

The AWS VPC resource provides type-safe Virtual Private Cloud creation with comprehensive validation, computed properties, and terraform synthesis integration.

## Architecture

### Function Signature
```ruby
aws_vpc(name, attributes) -> ResourceReference
```

### Type System
The VPC resource uses `VpcAttributes` dry-struct for runtime validation:

```ruby
class VpcAttributes < Dry::Struct
  attribute :cidr_block, Types::CidrBlock
  attribute :enable_dns_hostnames, Types::Bool.default(true)
  attribute :enable_dns_support, Types::Bool.default(true)
  attribute :instance_tenancy, Types::InstanceTenancy.default("default")
  attribute :tags, Types::AwsTags.default({})
end
```

### Validation Features

1. **CIDR Block Validation**: RFC compliant CIDR format checking
2. **Size Constraints**: CIDR blocks must be between /10 and /28
3. **RFC1918 Detection**: Automatic private CIDR space identification
4. **Instance Tenancy**: Validates against AWS allowed values
5. **Tags Validation**: Symbol keys, string values

## Implementation Details

### Terraform Synthesis
The resource function uses terraform-synthesizer to generate valid Terraform JSON:

```ruby
resource(:aws_vpc, name) do
  cidr_block vpc_attrs.cidr_block
  enable_dns_hostnames vpc_attrs.enable_dns_hostnames
  enable_dns_support vpc_attrs.enable_dns_support
  instance_tenancy vpc_attrs.instance_tenancy
  
  if vpc_attrs.tags.any?
    tags do
      vpc_attrs.tags.each do |key, value|
        public_send(key, value)
      end
    end
  end
end
```

### Output References
The function returns a ResourceReference with all available VPC outputs:

- `id`: VPC identifier for referencing in other resources
- `arn`: Amazon Resource Name for IAM policies
- `cidr_block`: The VPC's CIDR block (computed from input)
- `default_security_group_id`: AWS-created default security group
- `default_route_table_id`: AWS-created default route table
- `default_network_acl_id`: AWS-created default network ACL
- `dhcp_options_id`: Associated DHCP options set
- `main_route_table_id`: Main route table identifier
- `owner_id`: AWS account ID that owns the VPC

### Computed Properties

VPCs include rich computed properties via `VpcComputedAttributes`:

```ruby
vpc_ref.computed_attributes.is_private_cidr?    # RFC1918 detection
vpc_ref.computed_attributes.estimated_subnet_capacity  # Subnet planning
vpc_ref.computed_attributes.cidr_size          # Network size (e.g., "/16")
```

## Error Handling

### Validation Errors
- `Dry::Struct::Error`: Invalid attribute types or constraints
- `ArgumentError`: Missing required attributes
- `Types::ConstraintError`: CIDR format or size violations

### Common Validation Examples
```ruby
# Invalid CIDR format
aws_vpc(:invalid, cidr_block: "10.0.0.0") # Missing /prefix
# Raises: Dry::Types::ConstraintError

# CIDR too small
aws_vpc(:invalid, cidr_block: "10.0.0.0/8")  
# Raises: Dry::Types::ConstraintError

# CIDR too large  
aws_vpc(:invalid, cidr_block: "10.0.0.0/29")
# Raises: Dry::Types::ConstraintError
```

## Usage Patterns

### Basic VPC
```ruby
vpc = aws_vpc(:main, {
  cidr_block: "10.0.0.0/16",
  tags: { Name: "main-vpc", Environment: "production" }
})
```

### Multi-Tenancy VPC
```ruby
vpc = aws_vpc(:dedicated, {
  cidr_block: "172.16.0.0/16", 
  instance_tenancy: "dedicated",
  tags: { Name: "compliance-vpc", Compliance: "PCI-DSS" }
})
```

### Development VPC with Minimal Config
```ruby
vpc = aws_vpc(:dev, cidr_block: "192.168.0.0/24")
# Uses defaults: DNS hostnames/support enabled, default tenancy
```

## Testing Considerations

### Unit Testing with terraform-synthesizer
```ruby
RSpec.describe 'aws_vpc function' do
  let(:synthesizer) { TerraformSynthesizer.new }
  
  it 'synthesizes valid terraform with required attributes' do
    result = nil
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      result = aws_vpc(:test, cidr_block: "10.0.0.0/16")
    end
    
    # Verify function result
    expect(result).to be_a(Pangea::Resources::ResourceReference)
    expect(result.type).to eq('aws_vpc')
    
    # Verify terraform synthesis  
    tf_json = synthesizer.synthesis
    expect(tf_json[:resource][:aws_vpc]).to have_key(:test)
    expect(tf_json[:resource][:aws_vpc][:test][:cidr_block]).to eq("10.0.0.0/16")
  end
end
```

### Integration Testing
VPC resources should be tested with:
- Valid CIDR ranges across different sizes
- All supported instance tenancy values
- Tag application and formatting
- Error conditions and validation failures
- Terraform synthesis output verification

## Performance Notes

- Type validation occurs at function call time
- Computed properties are calculated on-demand
- Terraform synthesis is deferred until template evaluation
- Large tag sets have minimal performance impact

## Dependencies

- `pangea/resources/base`: Base resource functionality
- `pangea/resources/reference`: ResourceReference class
- `pangea/resources/aws_vpc/types`: VPC-specific type definitions
- `dry-struct`: Runtime type validation
- `terraform-synthesizer`: Terraform JSON generation

## Future Enhancements

1. **IPv6 Support**: Add IPv6 CIDR block attributes
2. **VPC Flow Logs**: Integrated flow log configuration
3. **DNS Resolution**: Custom DNS resolver options
4. **Multi-Region**: Cross-region VPC peering patterns
5. **Cost Estimation**: VPC-associated cost calculation
6. **Security Analysis**: Automated security assessment integration