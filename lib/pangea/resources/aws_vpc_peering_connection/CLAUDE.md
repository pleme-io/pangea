# AwsVpcPeeringConnection Implementation Documentation

## Overview

This directory contains the implementation for the `aws_vpc_peering_connection` resource function, providing type-safe creation and management of AWS VPC Peering Connection resources through terraform-synthesizer integration.

VPC Peering enables private network connectivity between two VPCs, allowing resources to communicate as if they were within the same network. This implementation supports same-account, cross-account, same-region, and cross-region peering scenarios.

## Implementation Architecture

### Core Components

#### 1. Resource Function (`resource.rb`)
The main `aws_vpc_peering_connection` function that:
- Accepts a symbol name and attributes hash
- Validates attributes using dry-struct types
- Generates terraform resource blocks via terraform-synthesizer
- Returns ResourceReference with computed outputs and properties
- Handles nested configuration blocks (accepter/requester)

#### 2. Type Definitions (`types.rb`)
VpcPeeringConnectionAttributes dry-struct defining:
- **Required attributes**: `vpc_id`, `peer_vpc_id`
- **Optional attributes**: `peer_owner_id`, `peer_region`, `auto_accept`, `accepter`, `requester`, `tags`
- **Custom validations**: Cross-account auto-accept restrictions
- **Computed properties**: Connection type analysis, DNS resolution status

#### 3. Documentation
- **CLAUDE.md** (this file): Implementation details for developers
- **README.md**: User-facing documentation with comprehensive examples

## Technical Implementation Details

### AWS VPC Peering Service

**Key Features:**
- Private connectivity between VPCs without internet gateways
- Support for same-account and cross-account peering
- Support for same-region and cross-region peering
- DNS resolution across peered VPCs
- Non-transitive routing (A-B-C requires A-C direct connection)

**Constraints:**
- Non-overlapping CIDR blocks required
- Maximum 125 peering connections per VPC
- Cross-account connections require manual acceptance (unless auto-accept)
- Cross-region peering incurs data transfer costs
- No transitive peering (must create direct connections)

**Integration Patterns:**
- Hub-spoke architecture for multiple VPCs
- Cross-account resource sharing
- Multi-region disaster recovery
- Development/staging environment isolation

### Type Validation Logic

```ruby
class VpcPeeringConnectionAttributes < Dry::Struct
  # Required VPC identifiers
  attribute :vpc_id, Types::String
  attribute :peer_vpc_id, Types::String
  
  # Cross-account/region optional configuration
  attribute? :peer_owner_id, Types::String.optional
  attribute? :peer_region, Types::String.optional
  
  # Auto-acceptance (same account only)
  attribute? :auto_accept, Types::Bool.optional.default(false)
  
  # Nested configuration blocks with typed schemas
  attribute? :accepter, Types::Hash.schema(
    allow_remote_vpc_dns_resolution?: Types::Bool.optional.default(false)
  ).default({})
  
  attribute? :requester, Types::Hash.schema(
    allow_remote_vpc_dns_resolution?: Types::Bool.optional.default(false)
  ).default({})
  
  # Custom validation prevents invalid configurations
  def self.new(attributes = {})
    attrs = super(attributes)
    
    # Prevent auto_accept with cross-account connections
    if attrs.auto_accept && attrs.peer_owner_id
      raise Dry::Struct::Error, "Cannot use 'auto_accept' with cross-account peering connections"
    end
    
    attrs
  end
end
```

### Terraform Synthesis

The resource function generates terraform JSON through terraform-synthesizer:

```ruby
resource(:aws_vpc_peering_connection, name) do
  # Required VPC configuration
  vpc_id attrs.vpc_id
  peer_vpc_id attrs.peer_vpc_id
  
  # Optional cross-account/region configuration
  peer_owner_id attrs.peer_owner_id if attrs.peer_owner_id
  peer_region attrs.peer_region if attrs.peer_region
  auto_accept attrs.auto_accept if attrs.auto_accept
  
  # Nested configuration blocks
  if attrs.accepter.any?
    accepter do
      allow_remote_vpc_dns_resolution attrs.accepter[:allow_remote_vpc_dns_resolution]
    end
  end
  
  if attrs.requester.any?
    requester do
      allow_remote_vpc_dns_resolution attrs.requester[:allow_remote_vpc_dns_resolution]
    end
  end
  
  # Standard tags block
  tags do
    attrs.tags.each { |k, v| public_send(k, v) }
  end if attrs.tags.any?
end
```

### ResourceReference Return Value

The function returns a ResourceReference providing:

#### Terraform Outputs
- `id`: Peering connection identifier
- `arn`: AWS ARN for the peering connection
- `status`: Connection status (pending-acceptance, active, etc.)
- `accept_status`: Acceptance status for the connection
- `vpc_id`: Requester VPC ID
- `peer_vpc_id`: Peer VPC ID
- `peer_owner_id`: Peer account ID (cross-account)
- `peer_region`: Peer region (cross-region)
- `accepter`: Accepter configuration block
- `requester`: Requester configuration block
- `tags_all`: All applied tags including default provider tags

#### Computed Properties
- `cross_account?`: Boolean indicating cross-account peering
- `cross_region?`: Boolean indicating cross-region peering
- `accepter_dns_resolution?`: Boolean for accepter DNS resolution
- `requester_dns_resolution?`: Boolean for requester DNS resolution
- `connection_type`: Symbol describing connection type (`:same_account_same_region`, etc.)
- `connection_type_description`: Human-readable connection type description

## Integration Patterns

### 1. Same-Account Basic Peering
```ruby
template :basic_peering do
  web_vpc = aws_vpc(:web, { cidr_block: "10.0.0.0/16" })
  db_vpc = aws_vpc(:database, { cidr_block: "10.1.0.0/16" })
  
  peering = aws_vpc_peering_connection(:web_to_db, {
    vpc_id: web_vpc.id,
    peer_vpc_id: db_vpc.id,
    auto_accept: true,
    requester: { allow_remote_vpc_dns_resolution: true },
    accepter: { allow_remote_vpc_dns_resolution: true }
  })
end
```

### 2. Cross-Account Peering
```ruby
template :cross_account_peering do
  # Requires manual acceptance in peer account
  cross_account_peering = aws_vpc_peering_connection(:cross_account, {
    vpc_id: ref(:aws_vpc, :main, :id),
    peer_vpc_id: "vpc-12345678",
    peer_owner_id: "123456789012",
    # Note: auto_accept cannot be used
    requester: { allow_remote_vpc_dns_resolution: true }
  })
end
```

### 3. Hub-Spoke Architecture
```ruby
template :hub_spoke do
  hub = aws_vpc(:hub, { cidr_block: "10.0.0.0/16" })
  
  spokes = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
  
  spokes.each_with_index do |cidr, i|
    spoke = aws_vpc("spoke_#{i}".to_sym, { cidr_block: cidr })
    
    aws_vpc_peering_connection("hub_to_spoke_#{i}".to_sym, {
      vpc_id: hub.id,
      peer_vpc_id: spoke.id,
      auto_accept: true,
      requester: { allow_remote_vpc_dns_resolution: true },
      accepter: { allow_remote_vpc_dns_resolution: true }
    })
  end
end
```

## Error Handling and Validation

### Common Validation Errors

**1. Cross-Account Auto-Accept**
```ruby
# This will raise Dry::Struct::Error
aws_vpc_peering_connection(:invalid, {
  vpc_id: "vpc-12345",
  peer_vpc_id: "vpc-67890",
  peer_owner_id: "123456789012",
  auto_accept: true  # Invalid with peer_owner_id
})
```

**2. Missing Required Attributes**
```ruby
# This will raise Dry::Struct::Error: :vpc_id is missing
aws_vpc_peering_connection(:invalid, {
  peer_vpc_id: "vpc-67890"
  # vpc_id is required!
})
```

**3. Invalid Nested Block Configuration**
```ruby
# This will raise an error due to schema validation
aws_vpc_peering_connection(:invalid, {
  vpc_id: "vpc-12345",
  peer_vpc_id: "vpc-67890",
  accepter: {
    invalid_key: true  # Not in schema
  }
})
```

## Testing Strategy

### Unit Tests
```ruby
RSpec.describe Pangea::Resources::AWS do
  describe "#aws_vpc_peering_connection" do
    it "creates basic same-account peering connection" do
      connection = aws_vpc_peering_connection(:test, {
        vpc_id: "vpc-12345",
        peer_vpc_id: "vpc-67890",
        auto_accept: true
      })
      
      expect(connection.type).to eq('aws_vpc_peering_connection')
      expect(connection.cross_account?).to be_false
      expect(connection.connection_type).to eq(:same_account_same_region)
    end
    
    it "validates cross-account restrictions" do
      expect {
        aws_vpc_peering_connection(:invalid, {
          vpc_id: "vpc-12345",
          peer_vpc_id: "vpc-67890",
          peer_owner_id: "123456789012",
          auto_accept: true
        })
      }.to raise_error(Dry::Struct::Error, /Cannot use 'auto_accept' with cross-account/)
    end
    
    it "supports DNS resolution configuration" do
      connection = aws_vpc_peering_connection(:dns_test, {
        vpc_id: "vpc-12345",
        peer_vpc_id: "vpc-67890",
        requester: { allow_remote_vpc_dns_resolution: true },
        accepter: { allow_remote_vpc_dns_resolution: true }
      })
      
      expect(connection.requester_dns_resolution?).to be_true
      expect(connection.accepter_dns_resolution?).to be_true
    end
  end
end
```

### Integration Tests
```ruby
# Test terraform synthesis output
RSpec.describe "VPC Peering Terraform Generation" do
  it "generates correct terraform for cross-region peering" do
    synthesizer = TerraformSynthesizer.new
    
    synthesizer.instance_eval do
      aws_vpc_peering_connection(:cross_region, {
        vpc_id: "vpc-12345",
        peer_vpc_id: "vpc-67890",
        peer_region: "eu-west-1",
        requester: { allow_remote_vpc_dns_resolution: true }
      })
    end
    
    tf_json = synthesizer.synthesis
    expect(tf_json[:resource][:aws_vpc_peering_connection][:cross_region]).to include(
      vpc_id: "vpc-12345",
      peer_vpc_id: "vpc-67890",
      peer_region: "eu-west-1"
    )
  end
end
```

## Security Best Practices

### Network Segmentation
- **Minimal Peering**: Only peer VPCs that require direct communication
- **Route Table Control**: Update route tables to control allowed traffic paths
- **Security Groups**: Create specific rules for cross-VPC communication
- **Network ACLs**: Add subnet-level controls for additional security

### Access Control
- **Cross-Account Validation**: Verify peer account identity before acceptance
- **Least Privilege**: Limit peering to specific subnets when possible
- **Monitoring**: Enable VPC Flow Logs for traffic analysis
- **Tagging**: Use consistent tagging for resource management

### Compliance Considerations
- **Data Residency**: Be aware of cross-region data transfer regulations
- **Audit Trails**: Maintain logs of peering connection changes
- **Encryption**: Ensure data encryption in transit between VPCs
- **Access Reviews**: Regularly review and audit peering connections

## Performance Considerations

### Network Optimization
- **Placement Groups**: Use for high-performance computing workloads
- **Enhanced Networking**: Enable SR-IOV for improved performance
- **Instance Types**: Choose appropriate instance types for network performance
- **Bandwidth Planning**: Understand cross-region bandwidth limitations

### Cost Optimization
- **Regional Strategy**: Minimize cross-region data transfer costs
- **Traffic Analysis**: Monitor and optimize data transfer patterns
- **Connection Lifecycle**: Remove unused peering connections
- **Hub-Spoke vs Full Mesh**: Choose architecture based on traffic patterns

## Future Enhancements

### Potential Improvements
1. **Automatic Route Table Updates**: Integration with route table management
2. **Connection Health Monitoring**: Built-in health checks and alerting
3. **Cost Analysis Integration**: Automated cost tracking and optimization
4. **Security Group Integration**: Automatic security group rule creation
5. **Template Validation**: Pre-deployment CIDR conflict detection
6. **Multi-Region Templates**: Enhanced support for global architectures

### AWS Service Evolution
- **Transit Gateway Integration**: Migration paths from VPC peering to Transit Gateway
- **IPv6 Support**: Enhanced IPv6 peering capabilities
- **PrivateLink Integration**: Hybrid connectivity patterns
- **Network Manager**: Integration with AWS Network Manager for global networks
