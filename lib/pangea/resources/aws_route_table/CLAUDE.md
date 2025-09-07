# AWS Route Table Resource Implementation

## Overview

The `aws_route_table` resource creates an AWS Route Table that contains a set of rules (routes) that determine where network traffic from subnets or gateways is directed. Route tables are essential for controlling traffic flow within a VPC.

## Type Safety Implementation

### Attributes Structure

```ruby
class RouteAttributes < Dry::Struct
  # Destination (one required)
  attribute :cidr_block, CidrBlock.optional
  attribute :ipv6_cidr_block, String.optional
  
  # Targets (exactly one required)
  attribute :gateway_id, String.optional
  attribute :nat_gateway_id, String.optional
  attribute :network_interface_id, String.optional
  attribute :transit_gateway_id, String.optional
  attribute :vpc_peering_connection_id, String.optional
  attribute :vpc_endpoint_id, String.optional
  attribute :egress_only_gateway_id, String.optional
end

class RouteTableAttributes < Dry::Struct
  attribute :vpc_id, String                    # Required VPC ID
  attribute :routes, Array.of(RouteAttributes) # Route definitions
  attribute :tags, AwsTags                     # Resource tags
end
```

### Key Design Decisions

1. **Route Validation**: Each route must have:
   - Exactly one destination (CIDR block or IPv6 CIDR block)
   - Exactly one target (gateway, NAT gateway, network interface, etc.)
   - Custom validation ensures these constraints

2. **Flexible Route Targets**: Supports all AWS route target types:
   - Internet Gateway (`gateway_id`)
   - NAT Gateway (`nat_gateway_id`)
   - Network Interface (`network_interface_id`)
   - Transit Gateway (`transit_gateway_id`)
   - VPC Peering Connection (`vpc_peering_connection_id`)
   - VPC Endpoint (`vpc_endpoint_id`)
   - Egress-only Internet Gateway (`egress_only_gateway_id`)

3. **Computed Properties**:
   - `route_count`: Number of routes defined
   - `has_internet_route?`: Checks for 0.0.0.0/0 route via IGW
   - `has_nat_route?`: Checks for NAT gateway routes

## Resource Function Pattern

The `aws_route_table` function follows the standard Pangea resource pattern:

```ruby
def aws_route_table(name, attributes = {})
  # 1. Validate attributes with dry-struct
  rt_attrs = Types::RouteTableAttributes.new(attributes)
  
  # 2. Generate Terraform resource via synthesizer
  resource(:aws_route_table, name) do
    vpc_id rt_attrs.vpc_id
    
    # Add each route as a nested block
    rt_attrs.routes.each do |route_attrs|
      route do
        # Set route attributes conditionally
      end
    end
    
    tags { ... } if rt_attrs.tags.any?
  end
  
  # 3. Return ResourceReference with outputs and computed properties
  ResourceReference.new(
    type: 'aws_route_table',
    name: name,
    resource_attributes: rt_attrs.to_h,
    outputs: { id, arn, owner_id },
    computed_properties: { route_count, has_internet_route, has_nat_route }
  )
end
```

## Integration with Terraform Synthesizer

The resource block generation creates nested route blocks:

```ruby
resource(:aws_route_table, name) do
  vpc_id rt_attrs.vpc_id
  
  rt_attrs.routes.each do |route_attrs|
    route do
      cidr_block route_attrs.cidr_block if route_attrs.cidr_block
      gateway_id route_attrs.gateway_id if route_attrs.gateway_id
      # ... other route attributes
    end
  end
end
```

This generates the equivalent Terraform JSON:

```json
{
  "resource": {
    "aws_route_table": {
      "public": {
        "vpc_id": "${aws_vpc.main.id}",
        "route": [
          {
            "cidr_block": "0.0.0.0/0",
            "gateway_id": "${aws_internet_gateway.main.id}"
          }
        ],
        "tags": {
          "Name": "public-route-table"
        }
      }
    }
  }
}
```

## Common Usage Patterns

### 1. Public Route Table (Internet Gateway)
```ruby
public_rt = aws_route_table(:public, {
  vpc_id: vpc.id,
  routes: [{
    cidr_block: "0.0.0.0/0",
    gateway_id: igw.id
  }],
  tags: { Name: "public-routes" }
})
```

### 2. Private Route Table (NAT Gateway)
```ruby
private_rt = aws_route_table(:private, {
  vpc_id: vpc.id,
  routes: [{
    cidr_block: "0.0.0.0/0",
    nat_gateway_id: nat.id
  }],
  tags: { Name: "private-routes" }
})
```

### 3. VPC Peering Routes
```ruby
peering_rt = aws_route_table(:peering, {
  vpc_id: vpc.id,
  routes: [
    {
      cidr_block: "10.1.0.0/16",
      vpc_peering_connection_id: peering.id
    },
    {
      cidr_block: "0.0.0.0/0",
      gateway_id: igw.id
    }
  ],
  tags: { Name: "peering-routes" }
})
```

### 4. IPv6 Routes
```ruby
ipv6_rt = aws_route_table(:ipv6, {
  vpc_id: vpc.id,
  routes: [{
    ipv6_cidr_block: "::/0",
    egress_only_gateway_id: eigw.id
  }],
  tags: { Name: "ipv6-routes" }
})
```

## Testing Considerations

1. **Type Validation**:
   - Test route validation (one destination, one target)
   - Test invalid route combinations
   - Test empty routes array
   - Test missing vpc_id

2. **Route Validation**:
   - Test multiple targets specified (should fail)
   - Test no destination specified (should fail)
   - Test valid CIDR block formats

3. **Terraform Generation**:
   - Verify correct route block nesting
   - Test multiple routes generation
   - Test conditional attribute inclusion

4. **Computed Properties**:
   - Test route counting
   - Test internet route detection
   - Test NAT route detection

## Future Enhancements

1. **Route Validation**:
   - Validate CIDR block conflicts within routes
   - Validate gateway/NAT ID formats
   - Check for duplicate routes

2. **Additional Computed Properties**:
   - List all route destinations
   - Identify route types (public/private/peering)
   - Calculate route priority

3. **Helper Methods**:
   - Add route after creation
   - Remove specific routes
   - Route table association helpers