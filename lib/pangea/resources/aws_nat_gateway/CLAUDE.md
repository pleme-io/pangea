# AWS NAT Gateway Resource Implementation

## Overview

The `aws_nat_gateway` resource creates an AWS NAT Gateway that enables instances in private subnets to connect to the internet or other AWS services while preventing inbound connections from the internet. NAT Gateways support both public (internet-facing) and private (for accessing AWS services via PrivateLink) connectivity types.

## Type Safety Implementation

### Attributes Structure

```ruby
class NatGatewayAttributes < Dry::Struct
  attribute :subnet_id, String                # Required, must be public subnet for public NAT
  attribute :allocation_id, String.optional   # EIP allocation ID for public NAT
  attribute :connectivity_type, String        # 'public' or 'private'
  attribute :tags, AwsTags                    # Resource tags
end
```

### Key Design Decisions

1. **Connectivity Type Support**: Supports both NAT Gateway types:
   - **Public NAT Gateway**: Requires Elastic IP, provides internet connectivity
   - **Private NAT Gateway**: No EIP needed, for AWS service connectivity via PrivateLink

2. **Allocation ID Validation**:
   - Required for public NAT gateways (unless AWS auto-allocates)
   - Cannot be used with private NAT gateways
   - Validation ensures consistency between `allocation_id` and `connectivity_type`

3. **Subnet Requirements**:
   - Public NAT Gateway must be in a public subnet
   - Private NAT Gateway can be in any subnet
   - Validation doesn't enforce this (requires runtime context)

4. **Computed Properties**:
   - `public?`: Returns true for public NAT gateways
   - `private?`: Returns true for private NAT gateways
   - `requires_elastic_ip?`: Indicates if EIP allocation is needed

## Resource Function Pattern

The `aws_nat_gateway` function follows the standard Pangea resource pattern:

```ruby
def aws_nat_gateway(name, attributes = {})
  # 1. Validate attributes with dry-struct
  nat_attrs = Types::NatGatewayAttributes.new(attributes)
  
  # 2. Generate Terraform resource via synthesizer
  resource(:aws_nat_gateway, name) do
    subnet_id nat_attrs.subnet_id
    allocation_id nat_attrs.allocation_id if nat_attrs.allocation_id
    connectivity_type nat_attrs.connectivity_type if nat_attrs.connectivity_type != 'public'
    tags { ... } if nat_attrs.tags.any?
  end
  
  # 3. Return ResourceReference with outputs and computed properties
  ResourceReference.new(
    type: 'aws_nat_gateway',
    name: name,
    resource_attributes: nat_attrs.to_h,
    outputs: { id, allocation_id, subnet_id, network_interface_id, private_ip, public_ip },
    computed_properties: { public, private, requires_elastic_ip }
  )
end
```

## Integration with Terraform Synthesizer

The resource block generation uses conditional attributes:

```ruby
resource(:aws_nat_gateway, name) do
  subnet_id nat_attrs.subnet_id
  allocation_id nat_attrs.allocation_id if nat_attrs.allocation_id
  connectivity_type nat_attrs.connectivity_type if nat_attrs.connectivity_type != 'public'
  
  if nat_attrs.tags.any?
    tags do
      nat_attrs.tags.each do |key, value|
        public_send(key, value)
      end
    end
  end
end
```

This generates the equivalent Terraform JSON:

```json
{
  "resource": {
    "aws_nat_gateway": {
      "main": {
        "subnet_id": "${aws_subnet.public.id}",
        "allocation_id": "${aws_eip.nat.id}",
        "tags": {
          "Name": "main-nat-gateway",
          "Environment": "production"
        }
      }
    }
  }
}
```

## Common Usage Patterns

### 1. Public NAT Gateway with Elastic IP
```ruby
# Create Elastic IP
eip = aws_eip(:nat_eip, {
  domain: "vpc",
  tags: { Name: "nat-gateway-eip" }
})

# Create NAT Gateway
nat = aws_nat_gateway(:main, {
  subnet_id: public_subnet.id,
  allocation_id: eip.id,
  tags: { Name: "main-nat-gateway" }
})
```

### 2. Private NAT Gateway
```ruby
private_nat = aws_nat_gateway(:private, {
  subnet_id: private_subnet.id,
  connectivity_type: "private",
  tags: { Name: "private-nat-gateway" }
})
```

### 3. Multi-AZ NAT Gateway Setup
```ruby
%w[a b c].each do |az|
  # EIP for each AZ
  eip = aws_eip(:"nat_eip_#{az}", {
    domain: "vpc",
    tags: { Name: "nat-eip-#{az}" }
  })
  
  # NAT Gateway in each AZ
  nat = aws_nat_gateway(:"nat_#{az}", {
    subnet_id: ref(:aws_subnet, :"public_#{az}", :id),
    allocation_id: eip.id,
    tags: { 
      Name: "nat-gateway-#{az}",
      AvailabilityZone: "us-east-1#{az}"
    }
  })
end
```

### 4. NAT Gateway with Route Table Integration
```ruby
# Create NAT Gateway
nat = aws_nat_gateway(:main, {
  subnet_id: public_subnet.id,
  allocation_id: eip.id
})

# Create private route table using NAT Gateway
private_rt = aws_route_table(:private, {
  vpc_id: vpc.id,
  routes: [{
    cidr_block: "0.0.0.0/0",
    nat_gateway_id: nat.id
  }]
})
```

## Testing Considerations

1. **Type Validation**:
   - Test allocation_id with private connectivity type (should fail)
   - Test missing subnet_id (should fail)
   - Test invalid connectivity_type values

2. **Terraform Generation**:
   - Verify connectivity_type only included when not 'public'
   - Test allocation_id conditional inclusion
   - Test tag block generation

3. **Computed Properties**:
   - Test public/private detection
   - Test elastic IP requirement logic

4. **ResourceReference**:
   - Verify all outputs are accessible
   - Test public_ip output for private NAT gateways

## Future Enhancements

1. **Enhanced Validation**:
   - Validate subnet is public for public NAT gateways
   - Validate allocation_id format
   - Add subnet_id reference validation

2. **Additional Computed Properties**:
   - Bandwidth usage estimates
   - Cost estimation based on type
   - AZ information from subnet

3. **Helper Methods**:
   - Multi-AZ NAT Gateway creator
   - Automatic EIP allocation helper
   - Route table association helper