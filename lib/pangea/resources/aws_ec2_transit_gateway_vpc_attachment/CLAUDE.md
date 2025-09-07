# AWS EC2 Transit Gateway VPC Attachment Implementation

## Resource Overview

The `aws_ec2_transit_gateway_vpc_attachment` resource creates and manages VPC attachments to AWS Transit Gateways. This implementation provides comprehensive validation, routing analysis, and high availability considerations for production deployments.

## Implementation Details

### Type Safety and Validation

The resource uses `TransitGatewayVpcAttachmentAttributes` dry-struct for complete type safety:

```ruby
class TransitGatewayVpcAttachmentAttributes < Dry::Struct
  # Required connectivity components
  attribute :transit_gateway_id, Resources::Types::String
  attribute :vpc_id, Resources::Types::String  
  attribute :subnet_ids, Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1)
  
  # Optional feature toggles
  attribute? :appliance_mode_support, Resources::Types::TransitGatewayVpcAttachmentApplianceModeSupport
  attribute? :dns_support, Resources::Types::TransitGatewayVpcAttachmentDnsSupport
  attribute? :ipv6_support, Resources::Types::TransitGatewayVpcAttachmentIpv6Support
  
  # Route table behavior control
  attribute? :transit_gateway_default_route_table_association, Resources::Types::Bool.optional
  attribute? :transit_gateway_default_route_table_propagation, Resources::Types::Bool.optional
end
```

### AWS Resource ID Validation

The implementation validates AWS resource ID formats:

```ruby
# VPC ID validation: vpc-xxxxxxxx
unless vpc_id.match?(/\Avpc-[0-9a-f]{8,17}\z/)
  raise Dry::Struct::Error, "Invalid VPC ID format: #{vpc_id}. Expected format: vpc-xxxxxxxx"
end

# Transit Gateway ID validation: tgw-xxxxxxxx  
unless transit_gateway_id.match?(/\Atgw-[0-9a-f]{8,17}\z/)
  raise Dry::Struct::Error, "Invalid Transit Gateway ID format: #{transit_gateway_id}. Expected format: tgw-xxxxxxxx"
end

# Subnet ID validation: subnet-xxxxxxxx
subnet_ids.each do |subnet_id|
  unless subnet_id.match?(/\Asubnet-[0-9a-f]{8,17}\z/)
    raise Dry::Struct::Error, "Invalid subnet ID format: #{subnet_id}. Expected format: subnet-xxxxxxxx"
  end
end
```

### High Availability Analysis

The resource provides sophisticated availability analysis:

```ruby
def is_highly_available?
  # Multiple subnets provide high availability across AZs
  subnet_ids.length > 1
end

def availability_zones_count
  # Estimate AZ count based on subnet count (assuming best practices)
  case subnet_ids.length
  when 1 then 1  # Single AZ - no HA
  when 2 then 2  # Dual AZ - basic HA  
  when 3 then 3  # Triple AZ - full HA
  else subnet_ids.length # More than 3 AZs possible in some regions
  end
end
```

### Routing Behavior Analysis

The implementation provides detailed routing behavior analysis:

```ruby
def routing_behavior
  behavior = {
    default_route_table_association: transit_gateway_default_route_table_association,
    default_route_table_propagation: transit_gateway_default_route_table_propagation,
    dns_resolution: dns_support == 'enable',
    appliance_mode: appliance_mode_support == 'enable'
  }
  
  # Determine routing pattern based on configuration
  if transit_gateway_default_route_table_association && transit_gateway_default_route_table_propagation
    behavior[:pattern] = 'full_mesh'     # All-to-all connectivity
  elsif transit_gateway_default_route_table_association && !transit_gateway_default_route_table_propagation
    behavior[:pattern] = 'hub_and_spoke_receiver'  # Receives traffic, doesn't send routes
  elsif !transit_gateway_default_route_table_association && transit_gateway_default_route_table_propagation
    behavior[:pattern] = 'hub_and_spoke_sender'    # Sends routes, doesn't receive traffic
  else
    behavior[:pattern] = 'isolated'      # No default connectivity
  end
  
  behavior
end
```

### Security Analysis

Comprehensive security considerations analysis:

```ruby
def security_considerations
  considerations = []
  
  # High availability warnings
  unless is_highly_available?
    considerations << "Single subnet attachment - no high availability. Consider adding subnets in additional AZs"
  end
  
  # Appliance mode implications
  if appliance_mode_support == 'enable'
    considerations << "Appliance mode support is enabled - traffic will be directed to a single network appliance"
  end
  
  # DNS resolution impact
  if dns_support == 'disable'
    considerations << "DNS support is disabled - DNS resolution across the Transit Gateway will not work"
  end
  
  # Route table management warnings
  if transit_gateway_default_route_table_association == false
    considerations << "Default route table association is disabled - ensure custom route table is associated"
  end
  
  if transit_gateway_default_route_table_propagation == false
    considerations << "Default route table propagation is disabled - routes will not be automatically propagated"
  end
  
  considerations
end
```

## Terraform Resource Synthesis

The resource generates clean Terraform configuration with conditional attributes:

```ruby
resource(:aws_ec2_transit_gateway_vpc_attachment, name) do
  # Always required
  transit_gateway_id attachment_attrs.transit_gateway_id
  vpc_id attachment_attrs.vpc_id
  subnet_ids attachment_attrs.subnet_ids
  
  # Conditional optional attributes
  if attachment_attrs.appliance_mode_support
    appliance_mode_support attachment_attrs.appliance_mode_support
  end
  
  if attachment_attrs.dns_support
    dns_support attachment_attrs.dns_support
  end
  
  # Boolean attributes with explicit nil checking
  if !attachment_attrs.transit_gateway_default_route_table_association.nil?
    transit_gateway_default_route_table_association attachment_attrs.transit_gateway_default_route_table_association
  end
  
  # ... other optional attributes
end
```

## Architecture Pattern Support

### 1. Full Mesh Connectivity
Default configuration with all attachments associated and propagating:
```ruby
transit_gateway_default_route_table_association: true,
transit_gateway_default_route_table_propagation: true
```

### 2. Hub and Spoke Architecture
- **Hub**: Receives traffic from spokes, doesn't propagate its routes
- **Spoke**: Sends traffic to hub, propagates routes to hub

```ruby
# Hub configuration
hub_attachment = aws_ec2_transit_gateway_vpc_attachment(:hub, {
  transit_gateway_default_route_table_association: true,  # Receives traffic
  transit_gateway_default_route_table_propagation: false  # Doesn't propagate
})

# Spoke configuration  
spoke_attachment = aws_ec2_transit_gateway_vpc_attachment(:spoke, {
  transit_gateway_default_route_table_association: true,  # Can reach hub
  transit_gateway_default_route_table_propagation: true   # Advertises routes
})
```

### 3. Network Segmentation
Complete isolation with custom route table management:
```ruby
isolated_attachment = aws_ec2_transit_gateway_vpc_attachment(:isolated, {
  transit_gateway_default_route_table_association: false,  # Custom route tables only
  transit_gateway_default_route_table_propagation: false   # Manual route control
})
```

### 4. Appliance Mode for Security Inspection
Traffic flows through network security appliances:
```ruby
firewall_attachment = aws_ec2_transit_gateway_vpc_attachment(:firewall, {
  appliance_mode_support: "enable",                       # Single appliance routing
  transit_gateway_default_route_table_association: false, # Custom routing required
  transit_gateway_default_route_table_propagation: false  # Manual control
})
```

## Cost Analysis

Detailed cost breakdown with operational insights:

```ruby
def estimated_monthly_cost
  # VPC attachment base cost: $36.50 per month per attachment
  base_cost = 36.50
  
  {
    monthly_attachment_cost: base_cost,
    currency: 'USD',
    note: 'Fixed monthly cost per VPC attachment. Data processing charges apply separately.'
  }
end
```

Additional cost considerations:
- Data processing: ~$0.02/GB for inter-AZ traffic through Transit Gateway
- No additional cost for multiple subnets within same attachment
- Cross-region data transfer charges apply for multi-region connectivity

## Output References

The resource provides standard AWS outputs plus computed insights:

```ruby
outputs: {
  id: "${aws_ec2_transit_gateway_vpc_attachment.#{name}.id}",
  vpc_owner_id: "${aws_ec2_transit_gateway_vpc_attachment.#{name}.vpc_owner_id}",
  tags_all: "${aws_ec2_transit_gateway_vpc_attachment.#{name}.tags_all}"
},
computed_attributes: {
  is_highly_available: attachment_attrs.is_highly_available?,
  supports_appliance_mode_inspection: attachment_attrs.supports_appliance_mode_inspection?,
  routing_behavior: attachment_attrs.routing_behavior,
  security_considerations: attachment_attrs.security_considerations
}
```

## Integration Patterns

### VPC Resource Integration
```ruby
# Reference VPC and subnet resources
vpc_attachment = aws_ec2_transit_gateway_vpc_attachment(:app_vpc, {
  transit_gateway_id: tgw_ref.id,           # Reference from Transit Gateway resource
  vpc_id: app_vpc_ref.id,                   # Reference from VPC resource
  subnet_ids: [                             # References from subnet resources
    private_subnet_1a_ref.id,
    private_subnet_1b_ref.id,
    private_subnet_1c_ref.id
  ]
})
```

### Route Table Integration
The attachment can be referenced by route table associations:
```ruby
# Custom route table association (when default is disabled)
route_table_association = aws_ec2_transit_gateway_route_table_association(:custom, {
  transit_gateway_attachment_id: vpc_attachment.id,  # Reference attachment
  transit_gateway_route_table_id: custom_rt_ref.id
})
```

## Validation Strategy

### Input Validation
- AWS resource ID format validation using regex patterns
- Subnet count minimum enforcement (at least 1 required)
- Boolean attribute explicit handling (nil vs false distinction)

### Configuration Validation
- Appliance mode and routing configuration compatibility
- IPv6 requirements validation
- High availability best practice warnings

### Runtime Validation
- Cross-resource reference resolution
- Subnet-to-VPC ownership validation (handled by AWS)
- Transit Gateway capacity and limits (handled by AWS)

## Error Handling

Comprehensive error messages for common issues:

```ruby
# Resource ID format errors
raise Dry::Struct::Error, "Invalid VPC ID format: #{vpc_id}. Expected format: vpc-xxxxxxxx"

# Configuration dependency errors  
raise Dry::Struct::Error, "Appliance mode requires custom route table configuration"

# High availability warnings (not errors, but flagged in security_considerations)
"Single subnet attachment - no high availability. Consider adding subnets in additional AZs"
```

## Testing Considerations

### Unit Tests
- AWS resource ID format validation
- High availability detection logic
- Routing behavior analysis
- Security considerations generation

### Integration Tests
- Terraform resource generation validation
- Cross-resource reference resolution
- Multi-attachment routing behavior
- Cost calculation accuracy

This implementation provides a production-ready foundation for Transit Gateway VPC attachment management with comprehensive validation, security analysis, and operational insights for complex network architectures.