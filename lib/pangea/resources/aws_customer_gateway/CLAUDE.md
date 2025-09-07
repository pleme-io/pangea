# AwsCustomerGateway Implementation Documentation

## Overview

This directory contains the implementation for the `aws_customer_gateway` resource function, providing type-safe creation and management of AWS Customer Gateway resources through terraform-synthesizer integration.

AWS Customer Gateways represent the customer side of site-to-site VPN connections, defining the public IP address, BGP ASN, and authentication method for on-premises VPN devices or software VPN endpoints.

## Implementation Architecture

### Core Components

#### 1. Resource Function (`resource.rb`)
The main `aws_customer_gateway` function that:
- Accepts a symbol name and attributes hash
- Validates attributes using dry-struct types
- Generates terraform resource blocks via terraform-synthesizer
- Returns ResourceReference with computed outputs and properties

#### 2. Type Definitions (`types.rb`)
**CustomerGatewayAttributes** dry-struct defining:
- **Required attributes**: `bgp_asn` (Integer), `ip_address` (String), `type` (String)
- **Optional attributes**: `certificate_arn` (String), `device_name` (String), `tags` (Hash)
- **Custom validations**: BGP ASN range validation, public IP validation, certificate ARN format validation
- **Computed properties**: Authentication method, ASN type detection, device naming status

#### 3. Documentation
- **CLAUDE.md** (this file): Implementation details for developers
- **README.md**: User-facing documentation with examples

## Technical Implementation Details

### AWS Customer Gateway Service

**Service Overview**: AWS Customer Gateways define the customer-side configuration for site-to-site VPN connections. They specify the public IP address and BGP ASN of the customer's VPN device, enabling AWS to establish secure IPSec tunnels.

**Key Features**:
- **BGP Autonomous System**: Support for both 16-bit and 32-bit BGP ASNs
- **Public IP Endpoint**: Static public IP address for VPN tunnel termination
- **Certificate Authentication**: Optional certificate-based authentication via AWS Certificate Manager
- **Device Identification**: Optional device naming for operational clarity
- **Multi-Connection Support**: Single customer gateway can support multiple VPN connections

**Key Constraints**:
- **Public IP Requirement**: IP address must be public and static (no private IPs)
- **BGP ASN Restrictions**: Cannot use AWS reserved ASNs (7224, 9059, 10124, 17943)
- **Certificate Management**: Certificates must be managed through AWS Certificate Manager
- **Device Name Limits**: Device names limited to 255 characters
- **Connection Dependencies**: Customer gateway must exist before creating VPN connections

**Integration Patterns**:
- **Site-to-Site VPN**: Primary use case for connecting on-premises networks to AWS
- **Multi-Site Connectivity**: Multiple customer gateways for different sites
- **Redundant Connectivity**: Multiple customer gateways for high availability
- **Certificate-Based Security**: Enhanced authentication using managed certificates

### Type Validation Logic

```ruby
class CustomerGatewayAttributes < Dry::Struct
  transform_keys(&:to_sym)
  
  # Required configuration
  attribute :bgp_asn, Types::BgpAsn
  attribute :ip_address, Types::PublicIpAddress  
  attribute :type, Types::VpnGatewayType
  
  # Optional authentication and identification
  attribute? :certificate_arn, Types::String.optional
  attribute? :device_name, Types::String.optional
  attribute? :tags, Types::AwsTags.default({})
  
  def self.new(attributes = {})
    attrs = attributes.is_a?(Hash) ? attributes : {}
    
    # Comprehensive BGP ASN validation
    validate_bgp_asn(attrs[:bgp_asn]) if attrs[:bgp_asn]
    
    # Certificate ARN format validation
    validate_certificate_arn(attrs[:certificate_arn]) if attrs[:certificate_arn]
    
    # Device name length validation
    validate_device_name(attrs[:device_name]) if attrs[:device_name]
    
    super(attrs)
  end
  
  private
  
  def self.validate_bgp_asn(asn)
    # AWS reserved ASNs that cannot be used
    aws_reserved = [7224, 9059, 10124, 17943]
    
    if aws_reserved.include?(asn)
      raise Dry::Struct::Error, "BGP ASN #{asn} is reserved by AWS and cannot be used for customer gateways"
    end
    
    # Valid customer ASN ranges
    valid_16bit = (1..65534).include?(asn) && !aws_reserved.include?(asn)
    valid_32bit = (4200000000..4294967294).include?(asn)
    
    unless valid_16bit || valid_32bit
      raise Dry::Struct::Error, "bgp_asn must be in range 1-65534 (excluding AWS reserved) or 4200000000-4294967294"
    end
  end
  
  def self.validate_certificate_arn(arn)
    # AWS Certificate Manager ARN pattern
    acm_pattern = /\\Aarn:aws:acm:[a-z0-9-]+:[0-9]{12}:certificate\\/[a-f0-9-]{36}\\z/
    
    unless arn.match(acm_pattern)
      raise Dry::Struct::Error, "certificate_arn must be a valid AWS Certificate Manager ARN"
    end
  end
  
  def self.validate_device_name(name)
    if name.length > 255
      raise Dry::Struct::Error, "device_name must be 255 characters or less"
    end
  end
end
```

### Terraform Synthesis

The resource function generates terraform JSON through terraform-synthesizer:

```ruby
resource(:aws_customer_gateway, name) do
  # Required customer gateway configuration
  bgp_asn attrs.bgp_asn
  ip_address attrs.ip_address
  type attrs.type
  
  # Optional certificate authentication
  certificate_arn attrs.certificate_arn if attrs.certificate_arn
  
  # Optional device identification
  device_name attrs.device_name if attrs.device_name
  
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
- **Network Configuration**: `bgp_asn`, `ip_address`
- **Authentication**: `certificate_arn` (if configured)
- **Device Information**: `device_name` (if configured)
- **Metadata**: `tags_all` (all tags including provider defaults)

#### Computed Properties
- **uses_certificate_authentication**: Boolean indicating certificate-based auth
- **has_device_name**: Boolean indicating device name presence
- **is_16bit_asn**: Boolean indicating 16-bit BGP ASN usage
- **is_32bit_asn**: Boolean indicating 32-bit BGP ASN usage
- **gateway_type**: String describing the gateway type

## Integration Patterns

### 1. Basic Customer Gateway for VPN Connection
```ruby
template :basic_customer_gateway do
  # Customer gateway for headquarters
  hq_gateway = aws_customer_gateway(:headquarters, {
    bgp_asn: 65000,
    ip_address: "203.0.113.10",
    type: "ipsec.1",
    device_name: "HQ-Main-Router",
    tags: { Name: "headquarters-gateway" }
  })
  
  # VPN Gateway
  vpn_gw = aws_vpn_gateway(:main, {
    vpc_id: ref(:aws_vpc, :main, :id)
  })
  
  # VPN Connection
  vpn_conn = aws_vpn_connection(:hq_connection, {
    customer_gateway_id: hq_gateway.id,
    type: "ipsec.1",
    vpn_gateway_id: vpn_gw.id,
    static_routes_only: false
  })
end
```

### 2. High-Availability Multi-Gateway Setup
```ruby
template :ha_customer_gateways do
  # Primary customer gateway
  primary_gw = aws_customer_gateway(:primary, {
    bgp_asn: 65000,
    ip_address: "203.0.113.10",
    type: "ipsec.1",
    device_name: "Primary-VPN-Router",
    tags: { Name: "primary-gateway", Role: "primary" }
  })
  
  # Secondary customer gateway for redundancy
  secondary_gw = aws_customer_gateway(:secondary, {
    bgp_asn: 65000,  # Same ASN for seamless BGP
    ip_address: "203.0.113.11",
    type: "ipsec.1",
    device_name: "Secondary-VPN-Router",
    tags: { Name: "secondary-gateway", Role: "secondary" }
  })
  
  # VPN connections for both gateways
  primary_vpn = aws_vpn_connection(:primary_vpn, {
    customer_gateway_id: primary_gw.id,
    type: "ipsec.1",
    vpn_gateway_id: ref(:aws_vpn_gateway, :main, :id)
  })
  
  secondary_vpn = aws_vpn_connection(:secondary_vpn, {
    customer_gateway_id: secondary_gw.id,
    type: "ipsec.1",
    vpn_gateway_id: ref(:aws_vpn_gateway, :main, :id)
  })
end
```

### 3. Certificate-Based Authentication
```ruby
template :secure_customer_gateway do
  # Customer gateway with certificate authentication
  secure_gw = aws_customer_gateway(:secure, {
    bgp_asn: 65100,
    ip_address: "192.0.2.50",
    type: "ipsec.1",
    certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
    device_name: "Secure-VPN-Appliance",
    tags: {
      Name: "secure-gateway",
      Security: "high",
      AuthMethod: "certificate"
    }
  })
  
  # Transit Gateway for scalable connectivity
  tgw = aws_ec2_transit_gateway(:main, {
    description: "Main Transit Gateway"
  })
  
  # VPN connection to Transit Gateway
  secure_vpn = aws_vpn_connection(:secure_vpn, {
    customer_gateway_id: secure_gw.id,
    type: "ipsec.1",
    transit_gateway_id: tgw.id,
    static_routes_only: false
  })
end
```

## Error Handling and Validation

### Common Validation Errors

**Invalid BGP ASN - AWS Reserved**:
```ruby
aws_customer_gateway(:reserved_asn, {
  bgp_asn: 7224,  # AWS reserved
  ip_address: "203.0.113.10",
  type: "ipsec.1"
})
# Error: BGP ASN 7224 is reserved by AWS and cannot be used for customer gateways
```

**Invalid IP Address - Private Range**:
```ruby
aws_customer_gateway(:private_ip, {
  bgp_asn: 65000,
  ip_address: "10.0.0.1",  # Private IP
  type: "ipsec.1"
})
# Error: Customer Gateway IP cannot be in private range 10.0.0.0/8
```

**Invalid Certificate ARN**:
```ruby
aws_customer_gateway(:bad_cert, {
  bgp_asn: 65000,
  ip_address: "203.0.113.10",
  type: "ipsec.1",
  certificate_arn: "invalid-arn"
})
# Error: certificate_arn must be a valid AWS Certificate Manager ARN
```

### Runtime Validation

**Network Connectivity Requirements**:
- Customer gateway IP must be reachable from AWS
- No NAT devices should be between customer gateway and internet
- Firewall must allow IPSec traffic (ESP protocol, UDP 500, UDP 4500)

**BGP Configuration Requirements**:
- Customer device must support the specified BGP ASN
- BGP authentication settings must match if configured
- Route filtering should be configured appropriately

## Testing Strategy

### Unit Tests
```ruby
RSpec.describe Pangea::Resources::AWS do
  describe "#aws_customer_gateway" do
    it "creates customer gateway with valid parameters" do
      gw = aws_customer_gateway(:test, {
        bgp_asn: 65000,
        ip_address: "203.0.113.10",
        type: "ipsec.1",
        device_name: "Test-Router"
      })
      
      expect(gw.bgp_asn).to include("65000")
      expect(gw.is_16bit_asn).to be true
      expect(gw.has_device_name).to be true
    end
    
    it "creates customer gateway with 32-bit ASN" do
      gw = aws_customer_gateway(:large_asn, {
        bgp_asn: 4200000001,
        ip_address: "203.0.113.10",
        type: "ipsec.1"
      })
      
      expect(gw.is_32bit_asn).to be true
      expect(gw.is_16bit_asn).to be false
    end
    
    it "validates BGP ASN restrictions" do
      expect {
        aws_customer_gateway(:invalid, {
          bgp_asn: 7224,  # AWS reserved
          ip_address: "203.0.113.10",
          type: "ipsec.1"
        })
      }.to raise_error(Dry::Struct::Error, /reserved by AWS/)
    end
    
    it "validates public IP requirement" do
      expect {
        aws_customer_gateway(:private, {
          bgp_asn: 65000,
          ip_address: "192.168.1.1",  # Private IP
          type: "ipsec.1"
        })
      }.to raise_error(Dry::Types::ConstraintError, /private range/)
    end
    
    it "validates certificate ARN format" do
      expect {
        aws_customer_gateway(:bad_cert, {
          bgp_asn: 65000,
          ip_address: "203.0.113.10",
          type: "ipsec.1",
          certificate_arn: "not-an-arn"
        })
      }.to raise_error(Dry::Struct::Error, /valid AWS Certificate Manager ARN/)
    end
  end
end
```

### Integration Tests
```ruby
RSpec.describe "Customer Gateway Integration" do
  it "integrates with VPN connection and VPN gateway" do
    template = Pangea::Template.new(:cgw_integration) do
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
      
      expect(customer_gw.id).to include("cgw")
      expect(vpn_conn.customer_gateway_id).to eq(customer_gw.id)
    end
  end
end
```

## Security Best Practices

### Network Security
- **Static Public IP**: Ensure customer gateway IP is static and dedicated
- **Firewall Configuration**: Properly configure firewalls to allow IPSec traffic
- **Access Control**: Restrict physical and logical access to customer gateway devices
- **Network Monitoring**: Monitor customer gateway connectivity and performance

### Authentication Security
- **Certificate Management**: Use AWS Certificate Manager for certificate lifecycle
- **Certificate Rotation**: Implement regular certificate rotation procedures
- **Strong Pre-Shared Keys**: Use cryptographically strong pre-shared keys
- **BGP Authentication**: Enable BGP authentication where supported

### Operational Security
- **Device Hardening**: Harden customer gateway devices according to security best practices
- **Configuration Backup**: Maintain secure backups of device configurations
- **Change Management**: Implement change control for customer gateway modifications
- **Incident Response**: Prepare incident response procedures for connectivity issues

## Future Enhancements

### Planned Improvements
- **Enhanced BGP Support**: Support for more advanced BGP features and communities
- **Certificate Automation**: Automated certificate provisioning and renewal
- **Device Configuration Templates**: Pre-built configurations for common VPN devices
- **Health Monitoring**: Advanced monitoring and alerting for customer gateway health

### Integration Possibilities
- **SD-WAN Integration**: Enhanced support for software-defined WAN solutions
- **Multi-Cloud Connectivity**: Customer gateways for connections to other cloud providers
- **Network Automation**: API-driven customer gateway configuration management
- **Dynamic Routing**: Enhanced support for dynamic routing protocols beyond BGP

### Management Enhancements
- **Bulk Operations**: Support for bulk customer gateway creation and management
- **Template-Based Deployment**: Infrastructure templates for common customer gateway patterns
- **Cost Optimization**: Analysis and recommendations for customer gateway cost optimization
- **Compliance Reporting**: Automated compliance reporting for customer gateway configurations

## Deployment Considerations

### Pre-Deployment Planning
- **ASN Coordination**: Coordinate BGP ASN assignments across the organization
- **IP Address Management**: Plan and document public IP address assignments
- **Device Selection**: Choose customer gateway devices that meet security and performance requirements
- **Network Design**: Design network topology considering redundancy and performance

### Device Configuration
- **Standard Templates**: Develop standard configuration templates for different device types
- **Security Hardening**: Apply security hardening configurations to all devices
- **Monitoring Setup**: Configure SNMP, logging, and other monitoring capabilities
- **Backup Configuration**: Ensure device configurations are backed up securely

This Customer Gateway implementation provides a comprehensive foundation for managing the customer side of AWS VPN connections with strong validation, flexible configuration options, and robust security considerations within the Pangea infrastructure management framework.