# AwsVpcPeeringConnectionAccepter Implementation Documentation

## Overview

This directory contains the implementation for the `aws_vpc_peering_connection_accepter` resource function, providing type-safe acceptance and management of VPC peering connections through terraform-synthesizer integration.

VPC peering connection accepters are used on the receiving side of cross-account or cross-region VPC peering relationships. The requester creates the initial peering connection, and the accepter uses this resource to accept the connection.

## Implementation Architecture

### Core Components

#### 1. Resource Function (`resource.rb`)
The main `aws_vpc_peering_connection_accepter` function that:
- Accepts a symbol name and attributes hash
- Validates attributes using dry-struct types
- Generates terraform resource blocks via terraform-synthesizer
- Returns ResourceReference with computed outputs and properties

#### 2. Type Definitions (`types.rb`)
VpcPeeringConnectionAccepterAttributes dry-struct defining:
- **Required attributes**: `vpc_peering_connection_id` (String)
- **Optional attributes**: `auto_accept` (Boolean, default: false), `tags` (Hash)
- **Custom validations**: Validates peering connection ID format (pcx-*)
- **Computed properties**: `is_auto_accept_enabled?`, `peering_connection_region`

#### 3. Documentation
- **CLAUDE.md** (this file): Implementation details for developers
- **README.md**: User-facing documentation with examples

## Technical Implementation Details

### AWS VPC Peering Connection Accepter Service

**Service Overview**: AWS VPC Peering Connection Accepter allows you to accept VPC peering connection requests from other AWS accounts or regions. This enables private network connectivity between VPCs without internet gateways or VPN connections.

**Key Features**:
- **Cross-Account Peering**: Accept peering requests from different AWS accounts
- **Cross-Region Peering**: Accept connections from VPCs in different regions
- **Automatic Acceptance**: Optionally auto-accept connections (same account only)
- **Status Monitoring**: Track acceptance status and connection state

**Key Constraints**:
- Cannot auto-accept cross-account peering connections
- VPC CIDR blocks cannot overlap
- Peering is not transitive (A-B, B-C doesn't create A-C connectivity)
- Maximum 125 peering connections per VPC
- Cross-region peering incurs data transfer costs

**Integration Patterns**:
- Typically paired with `aws_vpc_peering_connection` on requester side
- Requires route table updates for traffic flow
- Often combined with security group rules for access control

### Type Validation Logic

```ruby
class VpcPeeringConnectionAccepterAttributes < Dry::Struct
  transform_keys(&:to_sym)
  
  # Required VPC peering connection ID with format validation
  attribute :vpc_peering_connection_id, Types::String
  
  # Optional auto-accept flag (false by default)
  attribute? :auto_accept, Types::Bool.default(false)
  
  # Optional resource tags
  attribute? :tags, Types::AwsTags.default({})
  
  # Custom validation ensures peering connection ID format
  def self.new(attributes = {})
    attrs = attributes.is_a?(Hash) ? attributes : {}
    
    if attrs[:vpc_peering_connection_id]
      unless attrs[:vpc_peering_connection_id].match(/\Apcx-[0-9a-f]{8,17}\z/)
        raise Dry::Struct::Error, "vpc_peering_connection_id must be a valid VPC peering connection ID (pcx-*)"
      end
    end
    
    super(attrs)
  end
end
```

### Terraform Synthesis

The resource function generates terraform JSON through terraform-synthesizer:

```ruby
resource(:aws_vpc_peering_connection_accepter, name) do
  # Required peering connection ID
  vpc_peering_connection_id attrs.vpc_peering_connection_id
  
  # Optional auto-accept (only for same-account peering)
  auto_accept attrs.auto_accept if attrs.auto_accept != false
  
  # Resource tags
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
- `id`: The accepter resource identifier
- `vpc_peering_connection_id`: The VPC peering connection ID
- `accept_status`: Current status of the peering connection
- `peer_owner_id`: AWS account ID of the peer VPC owner
- `peer_region`: Region of the peer VPC
- `peer_vpc_id`: ID of the peer VPC
- `requester`: Information about the requester VPC
- `accepter`: Information about the accepter VPC
- `tags_all`: All tags including provider defaults

#### Computed Properties
- `is_auto_accept_enabled`: Boolean indicating if auto-accept is enabled
- `peering_connection_region`: Region information for the peering connection

## Integration Patterns

### 1. Cross-Account Peering Acceptance
```ruby
template :cross_account_peering do
  # Accept peering connection from external account
  peer_accepter = aws_vpc_peering_connection_accepter(:external_peer, {
    vpc_peering_connection_id: "pcx-1a2b3c4d5e6f7g8h9",
    auto_accept: true,  # Only works for same-account
    tags: {
      Name: "external-account-peer",
      Environment: "production"
    }
  })
  
  # Create routes to enable traffic flow
  aws_route(:to_peer_vpc, {
    route_table_id: ref(:aws_route_table, :main, :id),
    destination_cidr_block: "10.1.0.0/16",
    vpc_peering_connection_id: peer_accepter.vpc_peering_connection_id
  })
end
```

## Error Handling and Validation

### Common Validation Errors

**Invalid Peering Connection ID Format**:
```ruby
aws_vpc_peering_connection_accepter(:invalid, {
  vpc_peering_connection_id: "vpc-12345"  # Wrong prefix
})
# Error: vpc_peering_connection_id must be a valid VPC peering connection ID (pcx-*)
```

**Missing Required Parameters**:
```ruby
aws_vpc_peering_connection_accepter(:incomplete, {
  auto_accept: true  # Missing vpc_peering_connection_id
})
# Error: vpc_peering_connection_id is missing
```

**Cross-Account Auto-Accept Limitation**:
```ruby
# This will not auto-accept if peering is cross-account
aws_vpc_peering_connection_accepter(:cross_account, {
  vpc_peering_connection_id: "pcx-external123",
  auto_accept: true  # Ignored for cross-account peering
})
# No error, but auto_accept has no effect
```

## Testing Strategy

### Unit Tests
```ruby
RSpec.describe Pangea::Resources::AWS do
  describe "#aws_vpc_peering_connection_accepter" do
    it "creates accepter with valid peering connection ID" do
      accepter = aws_vpc_peering_connection_accepter(:test, {
        vpc_peering_connection_id: "pcx-12345678",
        auto_accept: true
      })
      
      expect(accepter.vpc_peering_connection_id).to include("pcx-12345678")
      expect(accepter.is_auto_accept_enabled).to be true
    end
    
    it "raises error for invalid peering connection ID" do
      expect {
        aws_vpc_peering_connection_accepter(:invalid, {
          vpc_peering_connection_id: "invalid-id"
        })
      }.to raise_error(Dry::Struct::Error, /valid VPC peering connection ID/)
    end
    
    it "applies tags correctly" do
      accepter = aws_vpc_peering_connection_accepter(:tagged, {
        vpc_peering_connection_id: "pcx-abcdef123",
        tags: { Environment: "test", Owner: "devops" }
      })
      
      expect(accepter.resource_attributes[:tags]).to include(
        Environment: "test", Owner: "devops"
      )
    end
  end
end
```

## Security Best Practices

### Access Control
- **Verify Requester Identity**: Always validate the peer_owner_id matches expected AWS account
- **Use Resource-Based Policies**: Implement VPC endpoint policies to control cross-VPC access
- **Monitor Peering Changes**: Set up CloudTrail logging for peering connection modifications

### Network Security
- **Implement Least Privilege**: Use security groups to restrict cross-VPC traffic to necessary ports/protocols
- **Avoid Broad CIDR Routing**: Create specific routes rather than routing entire VPC CIDR blocks
- **Network ACLs**: Consider additional network ACL rules for defense in depth

### Operational Security
- **Automate Validation**: Use infrastructure testing to verify peering connections work as expected
- **Document Relationships**: Maintain inventory of all peering connections and their purposes
- **Regular Audits**: Periodically review active peering connections and remove unused ones

## Future Enhancements

### Planned Improvements
- **Enhanced Validation**: Add CIDR overlap detection before acceptance
- **Route Management**: Integrate automatic route table updates for accepted peering
- **Cost Estimation**: Calculate data transfer costs for cross-region peering
- **Health Checks**: Add connectivity validation after peering acceptance

### Integration Possibilities
- **Service Discovery**: Integrate with AWS Cloud Map for cross-VPC service discovery
- **Transit Gateway**: Migration path from VPC peering to Transit Gateway
- **Network Insights**: Integration with VPC Reachability Analyzer
- **Automation**: Terraform data sources for dynamic peering connection discovery
