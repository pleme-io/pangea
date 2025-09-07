# AWS Route Table Association Implementation Documentation

## Overview

This directory contains the implementation for the `aws_route_table_association` resource function, providing type-safe creation and management of AWS Route Table Association resources through terraform-synthesizer integration.

Route Table Associations are critical networking components that determine which route table controls traffic routing for specific subnets or gateways within an AWS VPC. They establish the binding between routing rules and network destinations.

## Implementation Architecture

### Core Components

#### 1. Resource Function (`resource.rb`)
The main `aws_route_table_association` function that:
- Accepts a symbol name and attributes hash
- Validates attributes using dry-struct types with mutual exclusivity logic
- Generates terraform resource blocks via terraform-synthesizer
- Returns ResourceReference with computed outputs and association metadata
- Provides comprehensive inline documentation with usage examples

#### 2. Type Definitions (`types.rb`)
RouteTableAssociationAttributes dry-struct defining:
- **Required attributes**: 
  - `route_table_id`: The ID of the routing table to associate
- **Optional attributes**: 
  - `subnet_id`: The subnet ID to associate (mutually exclusive with gateway_id)
  - `gateway_id`: The gateway ID for edge associations (mutually exclusive with subnet_id)
- **Custom validations**: Ensures exactly one of subnet_id or gateway_id is specified
- **Computed properties**: Association type detection, target identification

#### 3. Documentation
- **CLAUDE.md** (this file): Implementation details for developers
- **README.md**: User-facing documentation with comprehensive examples and troubleshooting

## Technical Implementation Details

### AWS Route Table Association Service

**Purpose**: Route table associations control traffic flow within VPCs by binding route tables to network destinations:
- **Subnet Associations**: Most common - associate route table with subnet for instance traffic routing
- **Gateway Associations**: Edge associations - associate route table with internet/VPN gateways

**Key Constraints**:
- Each subnet can only be associated with one route table at a time
- Subnets without explicit associations use the VPC's default route table
- Gateway associations are used for edge routing scenarios
- Route table and target must be in the same VPC
- No tag support (AWS limitation)

**AWS API Mapping**:
- Resource Type: `aws_route_table_association`
- Required: `route_table_id`
- Target: Either `subnet_id` OR `gateway_id` (never both)

### Type Validation Logic

```ruby
class RouteTableAssociationAttributes < Dry::Struct
  attribute :route_table_id, Types::String
  attribute? :subnet_id, Types::String.optional
  attribute? :gateway_id, Types::String.optional

  def self.new(attributes = {})
    attrs = super(attributes)
    
    # Validation 1: Must specify a target
    if attrs.subnet_id.nil? && attrs.gateway_id.nil?
      raise Dry::Struct::Error, "Must specify either 'subnet_id' or 'gateway_id'"
    end
    
    # Validation 2: Mutual exclusivity
    if attrs.subnet_id && attrs.gateway_id
      raise Dry::Struct::Error, "Cannot specify both 'subnet_id' and 'gateway_id' - they are mutually exclusive"
    end
    
    attrs
  end
end
```

**Validation Rules**:
1. **Target Required**: At least one of `subnet_id` or `gateway_id` must be provided
2. **Mutual Exclusivity**: Cannot specify both `subnet_id` and `gateway_id`
3. **Route Table Required**: `route_table_id` is mandatory

### Terraform Synthesis

The resource function generates terraform JSON through terraform-synthesizer:

```ruby
resource(:aws_route_table_association, name) do
  route_table_id attrs.route_table_id
  
  # Conditional attributes based on association type
  subnet_id attrs.subnet_id if attrs.subnet_id
  gateway_id attrs.gateway_id if attrs.gateway_id
  
  # Note: No tags support in AWS for route table associations
end
```

**Synthesis Process**:
1. Always include `route_table_id` (required)
2. Conditionally include `subnet_id` or `gateway_id` based on validation
3. No tag processing (AWS limitation)
4. Generate clean terraform JSON with only specified attributes

### ResourceReference Return Value

The function returns a ResourceReference providing:

#### Terraform Outputs
```ruby
{
  id: "${aws_route_table_association.#{name}.id}",
  route_table_id: "${aws_route_table_association.#{name}.route_table_id}",
  subnet_id: "${aws_route_table_association.#{name}.subnet_id}",      # Only if subnet association
  gateway_id: "${aws_route_table_association.#{name}.gateway_id}"     # Only if gateway association
}
```

#### Computed Properties
```ruby
{
  association_type: attrs.association_type,          # :subnet or :gateway
  target_id: attrs.target_id,                        # The subnet_id or gateway_id
  target_type: attrs.target_type,                    # "Subnet" or "Gateway (Internet/VPN)"
  is_subnet_association: attrs.subnet_association?,   # Boolean flags
  is_gateway_association: attrs.gateway_association?
}
```

## Integration Patterns

### 1. Standard VPC Subnet Association
```ruby
template :vpc_networking do
  vpc = aws_vpc(:main, { cidr_block: "10.0.0.0/16" })
  
  custom_rtb = aws_route_table(:private, {
    vpc_id: vpc.id
  })
  
  private_subnet = aws_subnet(:private, {
    vpc_id: vpc.id,
    cidr_block: "10.0.1.0/24"
  })
  
  # Associate subnet with custom route table
  rtb_assoc = aws_route_table_association(:private_subnet_rtb, {
    route_table_id: custom_rtb.id,
    subnet_id: private_subnet.id
  })
  
  # Usage: rtb_assoc.association_type => :subnet
end
```

### 2. Gateway Edge Association
```ruby
template :edge_routing do
  vpc = aws_vpc(:main, { cidr_block: "10.0.0.0/16" })
  igw = aws_internet_gateway(:main, { vpc_id: vpc.id })
  
  edge_rtb = aws_route_table(:edge, {
    vpc_id: vpc.id
  })
  
  # Associate gateway with route table for edge routing
  edge_assoc = aws_route_table_association(:igw_edge, {
    route_table_id: edge_rtb.id,
    gateway_id: igw.id
  })
  
  # Usage: edge_assoc.association_type => :gateway
end
```

### 3. Cross-Reference Integration
```ruby
template :integrated_networking do
  # Create infrastructure
  vpc = aws_vpc(:main, { cidr_block: "10.0.0.0/16" })
  rtb = aws_route_table(:custom, { vpc_id: vpc.id })
  subnet = aws_subnet(:app, {
    vpc_id: vpc.id,
    cidr_block: "10.0.1.0/24"
  })
  
  # Association with cross-references
  assoc = aws_route_table_association(:app_subnet_rtb, {
    route_table_id: rtb.id,    # Reference to route table
    subnet_id: subnet.id       # Reference to subnet
  })
  
  # Use association outputs in other resources
  output :association_info do
    value {
      id: assoc.id,
      type: assoc.target_type,
      target: assoc.target_id
    }
  end
end
```

## Error Handling and Validation

### Common Validation Errors

#### 1. Missing Target Error
```ruby
begin
  aws_route_table_association(:bad, {
    route_table_id: "rtb-12345"
    # Missing both subnet_id and gateway_id
  })
rescue Dry::Struct::Error => e
  # "Must specify either 'subnet_id' or 'gateway_id'"
end
```

#### 2. Mutual Exclusivity Error
```ruby
begin
  aws_route_table_association(:bad, {
    route_table_id: "rtb-12345",
    subnet_id: "subnet-67890",
    gateway_id: "igw-abcdef"  # Cannot specify both
  })
rescue Dry::Struct::Error => e
  # "Cannot specify both 'subnet_id' and 'gateway_id' - they are mutually exclusive"
end
```

#### 3. AWS Provider Errors
- **Route table not found**: Check route_table_id exists and is accessible
- **Subnet not found**: Verify subnet_id is correct and in same region
- **Gateway not found**: Ensure gateway_id is valid and properly attached
- **Already associated**: Subnet may already be associated with another route table
- **VPC mismatch**: Route table and target must be in same VPC

### Error Recovery Patterns
```ruby
template :error_resilient do
  begin
    # Try to create association
    assoc = aws_route_table_association(:subnet_rtb, {
      route_table_id: route_table_ref.id,
      subnet_id: subnet_ref.id
    })
    
    # Log success
    output :association_status do
      value "Successfully associated #{assoc.target_type} with route table"
    end
    
  rescue Dry::Struct::Error => validation_error
    # Handle validation errors at compile time
    raise "Route table association validation failed: #{validation_error.message}"
  end
end
```

## Testing Strategy

### Unit Tests
```ruby
RSpec.describe Pangea::Resources::AWS do
  describe "#aws_route_table_association" do
    it "creates subnet association with valid attributes" do
      attrs = {
        route_table_id: "rtb-12345",
        subnet_id: "subnet-67890"
      }
      
      result = aws_route_table_association(:test, attrs)
      
      expect(result.association_type).to eq(:subnet)
      expect(result.is_subnet_association).to be true
      expect(result.is_gateway_association).to be false
    end
    
    it "creates gateway association with valid attributes" do
      attrs = {
        route_table_id: "rtb-12345",
        gateway_id: "igw-abcdef"
      }
      
      result = aws_route_table_association(:test, attrs)
      
      expect(result.association_type).to eq(:gateway)
      expect(result.target_type).to eq("Gateway (Internet/VPN)")
    end
    
    it "raises error when both subnet_id and gateway_id specified" do
      attrs = {
        route_table_id: "rtb-12345",
        subnet_id: "subnet-67890",
        gateway_id: "igw-abcdef"
      }
      
      expect {
        aws_route_table_association(:test, attrs)
      }.to raise_error(Dry::Struct::Error, /mutually exclusive/)
    end
    
    it "raises error when neither target specified" do
      attrs = {
        route_table_id: "rtb-12345"
      }
      
      expect {
        aws_route_table_association(:test, attrs)
      }.to raise_error(Dry::Struct::Error, /Must specify either/)
    end
  end
end
```

### Integration Tests
```ruby
RSpec.describe "Route Table Association Integration" do
  it "integrates with VPC resources" do
    template = build_template do
      vpc = aws_vpc(:test, { cidr_block: "10.0.0.0/16" })
      rtb = aws_route_table(:test, { vpc_id: vpc.id })
      subnet = aws_subnet(:test, {
        vpc_id: vpc.id,
        cidr_block: "10.0.1.0/24"
      })
      
      assoc = aws_route_table_association(:test, {
        route_table_id: rtb.id,
        subnet_id: subnet.id
      })
    end
    
    expect(template.synthesize).to include_terraform_resource(
      "aws_route_table_association",
      "test"
    )
  end
end
```

## Security Best Practices

### 1. Network Segmentation
- Use separate route tables for different security zones (public, private, database)
- Never associate production subnets with development route tables
- Implement least-privilege routing - only routes that are actually needed

### 2. Route Table Isolation
- Avoid sharing route tables across security boundaries
- Use dedicated route tables for sensitive workloads
- Regularly audit associations to ensure proper segmentation

### 3. Gateway Association Security
- Only use gateway associations when necessary for edge routing
- Document why gateway associations exist
- Monitor for unauthorized gateway associations

### 4. Access Control
- Implement IAM policies that restrict route table association permissions
- Use resource-based policies where possible
- Log all route table association changes

## Performance Considerations

### 1. Association Limits
- AWS has limits on route table associations per VPC
- Plan association strategy to stay within limits
- Consider using fewer, shared route tables when routing requirements are identical

### 2. Route Table Efficiency
- Minimize the number of route tables when possible
- Group subnets with identical routing requirements
- Avoid creating unnecessary route tables

## Future Enhancements

### 1. Enhanced Validation
- Cross-validate that route_table_id and target are in the same VPC
- Validate that target resources exist and are accessible
- Add warnings for common misconfigurations

### 2. Automation Features
- Auto-detect appropriate route table for subnet based on naming conventions
- Bulk association operations for multiple subnets
- Template-level association validation

### 3. Monitoring Integration
- Built-in CloudWatch metrics for association health
- Automatic alerts for association changes
- Integration with AWS Config for compliance monitoring

### 4. Advanced Patterns
- Support for transit gateway associations when AWS adds support
- Integration with network ACL associations
- Cross-region association patterns for global networks
