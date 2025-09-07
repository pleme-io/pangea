# AWS Internet Gateway Resource Implementation

## Overview

The `aws_internet_gateway` resource creates an AWS Internet Gateway (IGW), which enables communication between a VPC and the internet. Internet Gateways are horizontally scaled, redundant, and highly available VPC components.

## Type Safety Implementation

### Attributes Structure

```ruby
class InternetGatewayAttributes < Dry::Struct
  attribute :vpc_id, String.optional.default(nil)  # VPC attachment (optional)
  attribute :tags, AwsTags                          # Resource tags
end
```

### Key Design Decisions

1. **Optional VPC Attachment**: The `vpc_id` is optional because:
   - IGWs can be created without immediate VPC attachment
   - VPC attachment can be done separately via route table configuration
   - Supports more flexible infrastructure patterns

2. **Minimal Required Attributes**: Internet Gateways have very few configuration options:
   - Only tags and optional VPC attachment
   - AWS handles all redundancy and scaling automatically

3. **Computed Properties**:
   - `attached?`: Returns true if VPC ID is present
   - Useful for conditional logic in templates

## Resource Function Pattern

The `aws_internet_gateway` function follows the standard Pangea resource pattern:

```ruby
def aws_internet_gateway(name, attributes = {})
  # 1. Validate attributes with dry-struct
  igw_attrs = Types::InternetGatewayAttributes.new(attributes)
  
  # 2. Generate Terraform resource via synthesizer
  resource(:aws_internet_gateway, name) do
    vpc_id igw_attrs.vpc_id if igw_attrs.vpc_id
    tags { ... } if igw_attrs.tags.any?
  end
  
  # 3. Return ResourceReference with outputs
  ResourceReference.new(
    type: 'aws_internet_gateway',
    name: name,
    resource_attributes: igw_attrs.to_h,
    outputs: { id, arn, owner_id, vpc_id }
  )
end
```

## Integration with Terraform Synthesizer

The resource block generation uses terraform-synthesizer DSL:

```ruby
resource(:aws_internet_gateway, name) do
  vpc_id igw_attrs.vpc_id if igw_attrs.vpc_id
  
  if igw_attrs.tags.any?
    tags do
      igw_attrs.tags.each do |key, value|
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
    "aws_internet_gateway": {
      "main_igw": {
        "vpc_id": "${aws_vpc.main.id}",
        "tags": {
          "Name": "main-igw",
          "Environment": "production"
        }
      }
    }
  }
}
```

## Common Usage Patterns

### 1. Basic Internet Gateway
```ruby
igw = aws_internet_gateway(:main_igw, {
  tags: { Name: "main-igw" }
})
```

### 2. With VPC Attachment
```ruby
vpc = aws_vpc(:main, { cidr_block: "10.0.0.0/16" })

igw = aws_internet_gateway(:main_igw, {
  vpc_id: vpc.id,
  tags: { Name: "main-igw" }
})
```

### 3. For Public Subnet Routing
```ruby
# Create VPC and IGW
vpc = aws_vpc(:main, { cidr_block: "10.0.0.0/16" })
igw = aws_internet_gateway(:main_igw, { vpc_id: vpc.id })

# Create route table with internet route
public_rt = aws_route_table(:public, {
  vpc_id: vpc.id,
  routes: [{
    cidr_block: "0.0.0.0/0",
    gateway_id: igw.id
  }]
})
```

## Testing Considerations

1. **Type Validation**:
   - Test invalid vpc_id format
   - Test tag validation
   - Test empty attributes hash

2. **Terraform Generation**:
   - Verify correct JSON output
   - Test conditional vpc_id inclusion
   - Test tag block generation

3. **ResourceReference**:
   - Verify all outputs are accessible
   - Test output interpolation syntax

## Future Enhancements

1. **Enhanced Validation**:
   - Validate vpc_id format if provided
   - Add vpc_id reference validation

2. **Additional Outputs**:
   - Add computed tags output
   - Add attachment status output

3. **Helper Methods**:
   - Add `attach_to_vpc` helper method
   - Add route table integration helpers