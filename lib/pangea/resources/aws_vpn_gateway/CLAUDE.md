# AwsVpnGateway Implementation Documentation

## Overview

This directory contains the implementation for the `aws_vpn_gateway` resource function, providing type-safe creation and management of AWS VPN Gateway resources through terraform-synthesizer integration.

AWS VPN Gateways serve as the AWS-side endpoint for site-to-site VPN connections, enabling secure connectivity between VPCs and on-premises networks. They support multiple VPN connections and can be deployed across multiple Availability Zones for high availability.

## Implementation Architecture

### Core Components

#### 1. Resource Function (`resource.rb`)
The main `aws_vpn_gateway` function that:
- Accepts a symbol name and attributes hash
- Validates attributes using dry-struct types
- Generates terraform resource blocks via terraform-synthesizer
- Returns ResourceReference with computed outputs and properties

#### 2. Type Definitions (`types.rb`)
**VpnGatewayAttributes** dry-struct defining:
- **Optional attributes**: All attributes are optional with sensible defaults
- **VPC Attachment**: `vpc_id` for immediate VPC attachment
- **Placement Control**: `availability_zone` for single-AZ deployment (default: multi-AZ)
- **BGP Configuration**: `amazon_side_asn` for custom Amazon-side BGP ASN
- **Custom validations**: VPC ID format validation, ASN range validation
- **Computed properties**: Attachment status, ASN usage, multi-AZ capability

#### 3. Documentation
- **CLAUDE.md** (this file): Implementation details for developers
- **README.md**: User-facing documentation with examples

## Technical Implementation Details

### AWS VPN Gateway Service

**Service Overview**: AWS VPN Gateways provide the AWS-side termination point for site-to-site IPSec VPN connections. They can be attached to VPCs to enable secure communication with on-premises networks through customer gateways.

**Key Features**:
- **Multi-AZ Deployment**: Automatic deployment across multiple Availability Zones for high availability
- **Multiple Connections**: Support for up to 10 VPN connections per gateway
- **BGP Support**: Dynamic routing via BGP with configurable Amazon-side ASN
- **Route Propagation**: Automatic route propagation to VPC route tables
- **Elastic Scaling**: Automatic scaling to handle VPN connection load

**Key Constraints**:
- **VPC Limitation**: One VPN Gateway per VPC (1:1 relationship)
- **Connection Limit**: Maximum 10 VPN connections per VPN Gateway
- **Bandwidth**: Aggregate bandwidth shared across all connections
- **BGP ASN Range**: Limited to specific ranges for Amazon-side ASN
- **Route Limits**: Maximum 100 propagated routes per route table

**Integration Patterns**:
- **Single VPC**: Direct attachment to VPC for site-to-site connectivity
- **Hub-and-Spoke**: Central VPC with VPN Gateway serving multiple sites
- **Hybrid Cloud**: Integration with on-premises networks for hybrid architectures
- **Disaster Recovery**: Backup connectivity for primary Direct Connect links

### Type Validation Logic

```ruby
class VpnGatewayAttributes < Dry::Struct
  transform_keys(&:to_sym)
  
  # Optional VPC attachment
  attribute? :vpc_id, Types::String.optional
  
  # Optional single-AZ placement (default: multi-AZ)
  attribute? :availability_zone, Types::AwsAvailabilityZone.optional
  
  # Gateway type (currently only ipsec.1 supported)
  attribute? :type, Types::VpnGatewayType.default('ipsec.1')
  
  # Optional custom Amazon-side BGP ASN
  attribute? :amazon_side_asn, Types::BgpAsn.optional
  
  # Resource tags
  attribute? :tags, Types::AwsTags.default({})
  
  def self.new(attributes = {})
    attrs = attributes.is_a?(Hash) ? attributes : {}
    
    # Validate VPC ID format if provided
    validate_vpc_id(attrs[:vpc_id]) if attrs[:vpc_id]
    
    # Validate Amazon-side ASN if provided
    validate_amazon_side_asn(attrs[:amazon_side_asn]) if attrs[:amazon_side_asn]
    
    super(attrs)
  end
  
  private
  
  def self.validate_vpc_id(vpc_id)
    unless vpc_id.match(/\\Avpc-[0-9a-f]{8,17}\\z/)
      raise Dry::Struct::Error, "vpc_id must be a valid VPC ID (vpc-*)"
    end
  end
  
  def self.validate_amazon_side_asn(asn)
    # Amazon-side ASN must be in specific ranges
    valid_16bit = (64512..65534).include?(asn)
    valid_32bit = (4200000000..4294967294).include?(asn)
    
    unless valid_16bit || valid_32bit
      raise Dry::Struct::Error, "amazon_side_asn must be in range 64512-65534 or 4200000000-4294967294"
    end
  end
end
```

### Terraform Synthesis

The resource function generates terraform JSON through terraform-synthesizer:

```ruby
resource(:aws_vpn_gateway, name) do
  # Optional VPC attachment
  vpc_id attrs.vpc_id if attrs.vpc_id
  
  # Optional single-AZ placement
  availability_zone attrs.availability_zone if attrs.availability_zone
  
  # Gateway type (defaults to ipsec.1)
  type attrs.type
  
  # Optional custom Amazon-side BGP ASN
  amazon_side_asn attrs.amazon_side_asn if attrs.amazon_side_asn
  
  # Resource tags
  if attrs.tags.any?
    tags do
      attrs.tags.each { |key, value| public_send(key, value) }
    end
  end
end
```

### ResourceReference Return Value

The function returns a ResourceReference providing:

#### Terraform Outputs
- **Identity**: `id`, `arn`, `type`
- **State Information**: `state` (available, pending, deleting, deleted)
- **Network Configuration**: `vpc_id` (if attached), `availability_zone` (if single-AZ)
- **BGP Configuration**: `amazon_side_asn` (Amazon-side ASN)
- **Metadata**: `tags_all` (all tags including provider defaults)

#### Computed Properties
- **has_vpc_attachment**: Boolean indicating VPC attachment status
- **uses_custom_asn**: Boolean indicating custom BGP ASN usage
- **is_multi_az_capable**: Boolean indicating multi-AZ deployment capability
- **attachment_type**: String describing attachment type ('vpc' or 'detached')

## Integration Patterns

### 1. Basic VPC-Attached Gateway
```ruby
template :basic_vpn do
  # VPC for the gateway
  vpc = aws_vpc(:main, { cidr_block: "10.0.0.0/16" })
  
  # VPN Gateway attached to VPC
  vpn_gw = aws_vpn_gateway(:main, {
    vpc_id: vpc.id,
    tags: { Name: "main-vpn-gateway" }
  })
  
  # Enable route propagation
  aws_vpn_gateway_route_propagation(:main_propagation, {
    vpn_gateway_id: vpn_gw.id,
    route_table_id: vpc.main_route_table_id
  })
end
```

### 2. High Availability Multi-AZ Gateway
```ruby
template :ha_vpn do
  vpc = aws_vpc(:ha_vpc, { cidr_block: "172.16.0.0/16" })
  
  # Multi-AZ VPN Gateway (no AZ specified)
  vpn_gw = aws_vpn_gateway(:ha_gateway, {
    vpc_id: vpc.id,
    amazon_side_asn: 64512,  # Custom ASN
    tags: {
      Name: "ha-vpn-gateway",
      HighAvailability: "true"
    }
  })
  
  # Multiple customer gateways for redundancy
  hq_primary = aws_customer_gateway(:hq_primary, {
    bgp_asn: 65000,
    ip_address: "203.0.113.10",
    type: "ipsec.1"
  })
  
  hq_backup = aws_customer_gateway(:hq_backup, {
    bgp_asn: 65000,
    ip_address: "203.0.113.11", 
    type: "ipsec.1"
  })
  
  # Primary and backup VPN connections
  primary_vpn = aws_vpn_connection(:primary, {
    customer_gateway_id: hq_primary.id,
    type: "ipsec.1",
    vpn_gateway_id: vpn_gw.id
  })
  
  backup_vpn = aws_vpn_connection(:backup, {
    customer_gateway_id: hq_backup.id,
    type: "ipsec.1", 
    vpn_gateway_id: vpn_gw.id
  })
end
```

### 3. Detached Gateway for Flexible Deployment
```ruby
template :flexible_vpn do
  # Create detached gateway first
  vpn_gw = aws_vpn_gateway(:flexible, {
    type: "ipsec.1",
    amazon_side_asn: 65100,
    tags: { Name: "flexible-gateway", Status: "detached" }
  })
  
  # VPC attachment would be managed separately
  # This allows for dynamic VPC attachment based on conditions
  
  output :gateway_id do
    value vpn_gw.id
    description "VPN Gateway ID for dynamic attachment"
  end
end
```

## Error Handling and Validation

### Common Validation Errors

**Invalid VPC ID Format**:
```ruby
aws_vpn_gateway(:invalid_vpc, {
  vpc_id: "invalid-vpc-id"  # Wrong format
})
# Error: vpc_id must be a valid VPC ID (vpc-*)
```

**Invalid Amazon-side ASN Range**:
```ruby
aws_vpn_gateway(:bad_asn, {
  amazon_side_asn: 65535  # Outside valid range
})
# Error: amazon_side_asn must be in range 64512-65534 or 4200000000-4294967294
```

**AWS Reserved ASN**:
```ruby
aws_vpn_gateway(:reserved, {
  amazon_side_asn: 7224  # AWS reserved ASN
})
# Error: ASN 7224 is reserved by AWS
```

### Runtime Validation

**VPC Attachment Constraints**:
- VPC must exist and be in 'available' state
- VPC cannot already have a VPN Gateway attached
- VPC must have DNS resolution and DNS hostnames enabled for proper BGP operation

**Availability Zone Constraints**:
- Specified AZ must exist and be available in the current region
- Single-AZ deployment reduces high availability but may be required for specific network designs

## Testing Strategy

### Unit Tests
```ruby
RSpec.describe Pangea::Resources::AWS do
  describe "#aws_vpn_gateway" do
    it "creates VPN gateway with VPC attachment" do
      gw = aws_vpn_gateway(:test, {
        vpc_id: "vpc-12345678",
        amazon_side_asn: 65000
      })
      
      expect(gw.has_vpc_attachment).to be true
      expect(gw.uses_custom_asn).to be true
      expect(gw.attachment_type).to eq("vpc")
    end
    
    it "creates detached VPN gateway" do
      gw = aws_vpn_gateway(:detached, {
        type: "ipsec.1"
      })
      
      expect(gw.has_vpc_attachment).to be false
      expect(gw.attachment_type).to eq("detached")
      expect(gw.is_multi_az_capable).to be true
    end
    
    it "validates VPC ID format" do
      expect {
        aws_vpn_gateway(:invalid, {
          vpc_id: "invalid-format"
        })
      }.to raise_error(Dry::Struct::Error, /valid VPC ID/)
    end
    
    it "validates Amazon-side ASN range" do
      expect {
        aws_vpn_gateway(:bad_asn, {
          amazon_side_asn: 99999  # Invalid range
        })
      }.to raise_error(Dry::Struct::Error, /range 64512-65534/)
    end
  end
end
```

### Integration Tests
```ruby
RSpec.describe "VPN Gateway Integration" do
  it "integrates with VPC and VPN connections" do
    template = Pangea::Template.new(:vpn_integration) do
      vpc = aws_vpc(:test_vpc, { cidr_block: "10.0.0.0/16" })
      
      vpn_gw = aws_vpn_gateway(:test_gw, {
        vpc_id: vpc.id,
        amazon_side_asn: 64512
      })
      
      customer_gw = aws_customer_gateway(:test_cgw, {
        bgp_asn: 65000,
        ip_address: "203.0.113.1",
        type: "ipsec.1"
      })
      
      vpn_conn = aws_vpn_connection(:test_conn, {
        customer_gateway_id: customer_gw.id,
        type: "ipsec.1",
        vpn_gateway_id: vpn_gw.id
      })
      
      expect(vpn_gw.vpc_id).to include("vpc")
      expect(vpn_conn.vpn_gateway_id).to eq(vpn_gw.id)
    end
  end
end
```

## Security Best Practices

### Network Security
- **Route Table Isolation**: Use separate route tables for different security zones
- **Least Privilege Routing**: Enable route propagation only where necessary
- **Network ACL Defense**: Implement network ACLs for additional traffic filtering
- **VPC Flow Logs**: Enable flow logs to monitor VPN traffic patterns

### BGP Security
- **ASN Planning**: Coordinate BGP ASNs across your organization to avoid conflicts
- **Route Filtering**: Implement route filtering at customer gateways
- **BGP Authentication**: Use BGP authentication where supported by customer equipment
- **Route Monitoring**: Monitor BGP route advertisements for unexpected changes

### Operational Security
- **Access Control**: Restrict VPN Gateway management to authorized personnel
- **Change Management**: Implement change approval processes for VPN configurations
- **Backup Procedures**: Document VPN Gateway recovery procedures
- **Monitoring**: Set up CloudWatch alarms for gateway state changes

## Future Enhancements

### Planned Improvements
- **Enhanced BGP Options**: Support for more granular BGP configuration
- **Connection Health Monitoring**: Automatic health checks for attached VPN connections
- **Cost Optimization**: Analysis of VPN Gateway vs Transit Gateway cost-effectiveness
- **Multi-Region Support**: Enhanced support for cross-region VPN Gateway scenarios

### Integration Possibilities
- **Service Mesh Integration**: Integration with AWS App Mesh for hybrid service connectivity
- **Container Networking**: Enhanced support for EKS/ECS hybrid networking
- **Serverless Integration**: VPN connectivity for Lambda functions in VPCs
- **Multi-Cloud**: VPN Gateway integration with other cloud providers

### Performance Enhancements
- **Load Balancing**: Intelligent load balancing across multiple VPN connections
- **Bandwidth Optimization**: Dynamic bandwidth allocation based on connection usage
- **Route Optimization**: Intelligent route selection for optimal performance
- **Connection Pooling**: Efficient management of multiple VPN connections per gateway

## Migration Considerations

### From Classic VPN to VPN Gateway
- **Gradual Migration**: Plan phased migration from older VPN implementations
- **Route Table Updates**: Update route tables during migration
- **Connection Testing**: Thorough testing of each migrated connection
- **Rollback Planning**: Prepare rollback procedures for migration issues

### To Transit Gateway
- **Assessment**: Evaluate when to migrate from VPN Gateway to Transit Gateway
- **Connection Mapping**: Map existing VPN connections to Transit Gateway attachments
- **Route Propagation**: Migrate route propagation settings
- **Cost Analysis**: Compare ongoing costs between VPN Gateway and Transit Gateway

This VPN Gateway implementation provides a robust foundation for site-to-site VPN connectivity with comprehensive validation, flexible deployment options, and strong integration capabilities within the Pangea infrastructure management framework.