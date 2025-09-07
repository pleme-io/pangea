# AwsVpnConnection Implementation Documentation

## Overview

This directory contains the implementation for the `aws_vpn_connection` resource function, providing type-safe creation and management of AWS VPN Connection resources through terraform-synthesizer integration.

AWS VPN connections establish secure IPSec tunnels between AWS VPCs and on-premises networks. Each connection creates two redundant tunnels for high availability and supports both BGP and static routing protocols.

## Implementation Architecture

### Core Components

#### 1. Resource Function (`resource.rb`)
The main `aws_vpn_connection` function that:
- Accepts a symbol name and attributes hash
- Validates attributes using dry-struct types
- Generates terraform resource blocks via terraform-synthesizer
- Returns ResourceReference with computed outputs and properties

#### 2. Type Definitions (`types.rb`)
**VpnConnectionAttributes** dry-struct defining:
- **Required attributes**: `customer_gateway_id` (String), `type` (VpnConnectionType)
- **Optional attributes**: `vpn_gateway_id`, `transit_gateway_id`, `static_routes_only`, tunnel configuration options
- **Custom validations**: Gateway ID format validation, mutually exclusive gateway types
- **Computed properties**: Routing type, gateway attachment type, configuration helpers

**VpnTunnelOptions** nested struct defining:
- Tunnel-specific configuration options for advanced IPSec settings
- Phase 1/2 encryption, integrity, and DH group settings
- Tunnel timing and reliability parameters

#### 3. Documentation
- **CLAUDE.md** (this file): Implementation details for developers
- **README.md**: User-facing documentation with examples

## Technical Implementation Details

### AWS VPN Connection Service

**Service Overview**: AWS VPN connections provide secure, encrypted connectivity between AWS VPCs and on-premises networks using industry-standard IPSec VPN tunnels. Each connection establishes two tunnels across different Availability Zones for redundancy.

**Key Features**:
- **Dual Tunnels**: Two IPSec tunnels per connection for high availability
- **Routing Options**: Support for both BGP dynamic routing and static routing
- **Gateway Flexibility**: Works with VPN Gateways (VPC-attached) or Transit Gateways (multi-VPC)
- **Encryption**: Industry-standard IPSec encryption with configurable parameters
- **Monitoring**: CloudWatch metrics for tunnel state, throughput, and latency

**Key Constraints**:
- **Bandwidth Limit**: Each tunnel supports up to 1.25 Gbps throughput
- **Connection Limit**: Maximum 10 VPN connections per VPN Gateway
- **Routing Limitations**: BGP requires compatible customer gateway equipment
- **IP Address Requirements**: Customer gateway must have static public IP address
- **Tunnel Inside CIDRs**: Must be /30 subnets from 169.254.0.0/16 range

**Integration Patterns**:
- **VPC Integration**: Attached via VPN Gateway for single VPC connectivity
- **Transit Gateway**: Attached via Transit Gateway for multi-VPC and cross-region connectivity
- **Hybrid Networking**: Combined with Direct Connect for backup connectivity
- **Site-to-Site**: Multiple customer gateways for multi-site connectivity

### Type Validation Logic

```ruby
class VpnConnectionAttributes < Dry::Struct
  transform_keys(&:to_sym)
  
  # Required gateway and connection type
  attribute :customer_gateway_id, Types::String
  attribute :type, Types::VpnConnectionType  # 'ipsec.1'
  
  # Mutually exclusive gateway attachments
  attribute? :vpn_gateway_id, Types::String.optional
  attribute? :transit_gateway_id, Types::String.optional
  
  # Routing and network configuration
  attribute? :static_routes_only, Types::Bool.default(false)
  attribute? :local_ipv4_network_cidr, Types::CidrBlock.optional
  attribute? :remote_ipv4_network_cidr, Types::CidrBlock.optional
  
  # Tunnel-specific configuration
  attribute? :tunnel1_inside_cidr, Types::CidrBlock.optional
  attribute? :tunnel2_inside_cidr, Types::CidrBlock.optional
  attribute? :tunnel1_preshared_key, Types::String.optional
  attribute? :tunnel2_preshared_key, Types::String.optional
  
  def self.new(attributes = {})
    attrs = attributes.is_a?(Hash) ? attributes : {}
    
    # Validate AWS resource ID formats
    validate_customer_gateway_id(attrs[:customer_gateway_id])
    validate_vpn_gateway_id(attrs[:vpn_gateway_id]) if attrs[:vpn_gateway_id]
    validate_transit_gateway_id(attrs[:transit_gateway_id]) if attrs[:transit_gateway_id]
    
    # Ensure exactly one gateway type is specified
    validate_gateway_exclusivity(attrs)
    
    super(attrs)
  end
  
  private
  
  def self.validate_customer_gateway_id(cgw_id)
    return unless cgw_id
    unless cgw_id.match(/\\Acgw-[0-9a-f]{8,17}\\z/)
      raise Dry::Struct::Error, "customer_gateway_id must be a valid Customer Gateway ID (cgw-*)"
    end
  end
  
  def self.validate_gateway_exclusivity(attrs)
    has_vpn_gw = attrs[:vpn_gateway_id]
    has_tgw = attrs[:transit_gateway_id]
    
    unless has_vpn_gw || has_tgw
      raise Dry::Struct::Error, "Either vpn_gateway_id or transit_gateway_id must be specified"
    end
    
    if has_vpn_gw && has_tgw
      raise Dry::Struct::Error, "Cannot specify both vpn_gateway_id and transit_gateway_id"
    end
  end
end
```

### Terraform Synthesis

The resource function generates terraform JSON through terraform-synthesizer:

```ruby
resource(:aws_vpn_connection, name) do
  # Required parameters
  customer_gateway_id attrs.customer_gateway_id
  type attrs.type
  
  # Mutually exclusive gateway attachments
  vpn_gateway_id attrs.vpn_gateway_id if attrs.vpn_gateway_id
  transit_gateway_id attrs.transit_gateway_id if attrs.transit_gateway_id
  
  # Optional routing configuration
  static_routes_only attrs.static_routes_only if attrs.static_routes_only != false
  local_ipv4_network_cidr attrs.local_ipv4_network_cidr if attrs.local_ipv4_network_cidr
  remote_ipv4_network_cidr attrs.remote_ipv4_network_cidr if attrs.remote_ipv4_network_cidr
  
  # Tunnel-specific configuration
  tunnel1_inside_cidr attrs.tunnel1_inside_cidr if attrs.tunnel1_inside_cidr
  tunnel2_inside_cidr attrs.tunnel2_inside_cidr if attrs.tunnel2_inside_cidr
  tunnel1_preshared_key attrs.tunnel1_preshared_key if attrs.tunnel1_preshared_key
  tunnel2_preshared_key attrs.tunnel2_preshared_key if attrs.tunnel2_preshared_key
  
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
- **Basic Information**: `id`, `arn`, `state`, `type`, `customer_gateway_id`
- **Gateway Attachments**: `vpn_gateway_id`, `transit_gateway_id`
- **Routing Configuration**: `static_routes_only`
- **Tunnel 1 Details**: `tunnel1_address`, `tunnel1_cgw_inside_address`, `tunnel1_vgw_inside_address`, `tunnel1_preshared_key`, `tunnel1_bgp_asn`, `tunnel1_bgp_holdtime`
- **Tunnel 2 Details**: `tunnel2_address`, `tunnel2_cgw_inside_address`, `tunnel2_vgw_inside_address`, `tunnel2_preshared_key`, `tunnel2_bgp_asn`, `tunnel2_bgp_holdtime`
- **Configuration**: `customer_gateway_configuration` (XML config for customer device)
- **Metadata**: `tags_all`

#### Computed Properties
- **is_static_routing**: Boolean indicating use of static routing vs BGP
- **uses_transit_gateway**: Boolean indicating Transit Gateway attachment
- **uses_vpn_gateway**: Boolean indicating VPN Gateway attachment
- **gateway_attachment_type**: String describing attachment type

## Integration Patterns

### 1. VPN Gateway Integration (Traditional VPC)
```ruby
template :vpc_vpn do
  # VPC and VPN Gateway
  vpc = aws_vpc(:main, { cidr_block: "10.0.0.0/16" })
  vpn_gw = aws_vpn_gateway(:main, { vpc_id: vpc.id })
  
  # Customer Gateway
  customer_gw = aws_customer_gateway(:office, {
    bgp_asn: 65000,
    ip_address: "203.0.113.1",
    type: "ipsec.1"
  })
  
  # VPN Connection
  vpn_conn = aws_vpn_connection(:office_vpn, {
    customer_gateway_id: customer_gw.id,
    type: "ipsec.1",
    vpn_gateway_id: vpn_gw.id,
    static_routes_only: false
  })
  
  # Route propagation
  aws_vpn_gateway_route_propagation(:main, {
    vpn_gateway_id: vpn_gw.id,
    route_table_id: vpc.main_route_table_id
  })
end
```

### 2. Transit Gateway Integration (Multi-VPC)
```ruby
template :tgw_vpn do
  # Transit Gateway
  tgw = aws_ec2_transit_gateway(:main, {
    description: "Main TGW for VPN connectivity"
  })
  
  # Customer Gateway
  customer_gw = aws_customer_gateway(:hq, {
    bgp_asn: 65100,
    ip_address: "198.51.100.1",
    type: "ipsec.1"
  })
  
  # VPN Connection
  vpn_conn = aws_vpn_connection(:hq_vpn, {
    customer_gateway_id: customer_gw.id,
    type: "ipsec.1",
    transit_gateway_id: tgw.id,
    static_routes_only: true,
    local_ipv4_network_cidr: "10.0.0.0/8",
    remote_ipv4_network_cidr: "192.168.0.0/16"
  })
  
  # Static routes would be managed separately via aws_vpn_connection_route
end
```

### 3. High-Security Configuration
```ruby
template :secure_vpn do
  vpn_conn = aws_vpn_connection(:secure_vpn, {
    customer_gateway_id: "cgw-secure123",
    type: "ipsec.1",
    vpn_gateway_id: "vgw-secure456",
    
    # Custom tunnel configuration for security
    tunnel1_inside_cidr: "169.254.100.0/30",
    tunnel2_inside_cidr: "169.254.101.0/30",
    tunnel1_preshared_key: SecureRandom.hex(32),
    tunnel2_preshared_key: SecureRandom.hex(32),
    
    tags: {
      Environment: "production",
      Security: "high",
      Compliance: "sox"
    }
  })
end
```

## Error Handling and Validation

### Common Validation Errors

**Invalid Customer Gateway ID Format**:
```ruby
aws_vpn_connection(:invalid_cgw, {
  customer_gateway_id: "gateway-123",  # Wrong format
  type: "ipsec.1",
  vpn_gateway_id: "vgw-12345678"
})
# Error: customer_gateway_id must be a valid Customer Gateway ID (cgw-*)
```

**Missing Gateway Attachment**:
```ruby
aws_vpn_connection(:no_gateway, {
  customer_gateway_id: "cgw-12345678",
  type: "ipsec.1"
  # Error: Either vpn_gateway_id or transit_gateway_id must be specified
})
```

**Conflicting Gateway Attachments**:
```ruby
aws_vpn_connection(:both_gateways, {
  customer_gateway_id: "cgw-12345678",
  type: "ipsec.1",
  vpn_gateway_id: "vgw-12345678",
  transit_gateway_id: "tgw-87654321"  # Cannot have both
})
# Error: Cannot specify both vpn_gateway_id and transit_gateway_id
```

### Runtime Validation

**Tunnel Configuration Conflicts**:
- Tunnel inside CIDRs must be /30 subnets in 169.254.0.0/16 range
- Pre-shared keys should be 8-64 characters for compatibility
- Network CIDRs should not overlap with VPC or existing routes

## Testing Strategy

### Unit Tests
```ruby
RSpec.describe Pangea::Resources::AWS do
  describe "#aws_vpn_connection" do
    it "creates VPN connection with VPN Gateway" do
      conn = aws_vpn_connection(:test, {
        customer_gateway_id: "cgw-12345678",
        type: "ipsec.1",
        vpn_gateway_id: "vgw-87654321"
      })
      
      expect(conn.type).to eq("ipsec.1")
      expect(conn.uses_vpn_gateway).to be true
      expect(conn.uses_transit_gateway).to be false
    end
    
    it "creates VPN connection with Transit Gateway" do
      conn = aws_vpn_connection(:tgw_test, {
        customer_gateway_id: "cgw-12345678",
        type: "ipsec.1",
        transit_gateway_id: "tgw-12345678"
      })
      
      expect(conn.uses_transit_gateway).to be true
      expect(conn.gateway_attachment_type).to eq("transit_gateway")
    end
    
    it "validates customer gateway ID format" do
      expect {
        aws_vpn_connection(:invalid, {
          customer_gateway_id: "invalid-id",
          type: "ipsec.1",
          vpn_gateway_id: "vgw-12345678"
        })
      }.to raise_error(Dry::Struct::Error, /valid Customer Gateway ID/)
    end
    
    it "requires exactly one gateway attachment" do
      expect {
        aws_vpn_connection(:no_gw, {
          customer_gateway_id: "cgw-12345678",
          type: "ipsec.1"
        })
      }.to raise_error(Dry::Struct::Error, /Either vpn_gateway_id or transit_gateway_id/)
    end
  end
end
```

### Integration Tests
```ruby
RSpec.describe "VPN Connection Integration" do
  it "integrates with customer gateway and VPN gateway" do
    template = Pangea::Template.new(:vpn_test) do
      customer_gw = aws_customer_gateway(:test_cgw, {
        bgp_asn: 65000,
        ip_address: "203.0.113.1",
        type: "ipsec.1"
      })
      
      vpn_gw = aws_vpn_gateway(:test_vgw, {
        vpc_id: "vpc-12345678"
      })
      
      vpn_conn = aws_vpn_connection(:test_vpn, {
        customer_gateway_id: customer_gw.id,
        type: "ipsec.1",
        vpn_gateway_id: vpn_gw.id
      })
      
      expect(vpn_conn.customer_gateway_id).to include("cgw")
      expect(vpn_conn.vpn_gateway_id).to include("vgw")
    end
  end
end
```

## Security Best Practices

### Connection Security
- **Strong Pre-Shared Keys**: Use cryptographically secure random keys of maximum length
- **Custom Tunnel CIDRs**: Avoid predictable tunnel inside IP addresses
- **Monitor Connection State**: Set up CloudWatch alarms for tunnel state changes
- **Regular Key Rotation**: Implement automated key rotation for long-term connections

### Network Security
- **Least Privilege Routing**: Only advertise/accept necessary routes via BGP
- **Firewall Rules**: Restrict traffic at customer gateway to required protocols/ports
- **Network Segmentation**: Use security groups and NACLs to control cross-VPC traffic
- **Encryption in Transit**: Ensure all traffic uses IPSec encryption

### Operational Security
- **Configuration Management**: Store customer gateway configuration securely
- **Access Control**: Restrict who can modify VPN connection settings
- **Audit Logging**: Enable CloudTrail for VPN connection changes
- **Backup Connectivity**: Plan for redundant connectivity options

## Future Enhancements

### Planned Improvements
- **Advanced Tunnel Options**: Support for all IPSec phase 1/2 parameters
- **Connection Health Monitoring**: Automatic tunnel health checks and alerting
- **Configuration Templates**: Pre-built configurations for common customer gateway vendors
- **Cost Optimization**: Analysis of VPN vs Direct Connect cost-effectiveness

### Integration Possibilities
- **Site-to-Site Mesh**: Automated mesh connectivity between multiple sites
- **SD-WAN Integration**: Integration with software-defined WAN solutions
- **Multi-Cloud VPN**: VPN connectivity to other cloud providers
- **Network Automation**: Automated route management and failover scenarios

### Performance Enhancements
- **Multi-Tunnel Bonding**: Aggregate bandwidth across multiple VPN connections
- **Dynamic Routing Optimization**: Intelligent route selection based on performance metrics
- **Connection Pooling**: Efficient management of multiple VPN connections
- **Bandwidth Monitoring**: Real-time bandwidth utilization and throttling detection