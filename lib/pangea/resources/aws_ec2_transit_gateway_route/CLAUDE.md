# AWS EC2 Transit Gateway Route Implementation

## Resource Overview

The `aws_ec2_transit_gateway_route` resource creates and manages individual routes within Transit Gateway route tables. This implementation provides comprehensive route analysis, security implications assessment, and intelligent purpose detection based on route characteristics.

## Implementation Details

### Type Safety and Validation

The resource uses `TransitGatewayRouteAttributes` dry-struct for complete validation:

```ruby
class TransitGatewayRouteAttributes < Dry::Struct
  # Route destination
  attribute :destination_cidr_block, Resources::Types::TransitGatewayCidrBlock
  
  # Required route table reference
  attribute :transit_gateway_route_table_id, Resources::Types::String
  
  # Conditional routing behavior (mutually exclusive)
  attribute? :blackhole, Resources::Types::Bool.default(false)
  attribute? :transit_gateway_attachment_id, Resources::Types::String.optional
end
```

### Complex Route Logic Validation

The implementation enforces Transit Gateway routing rules:

```ruby
def self.new(attributes)
  attrs = attributes.is_a?(Hash) ? attributes : {}
  
  # Validate blackhole route logic
  if attrs[:blackhole] == true && attrs[:transit_gateway_attachment_id]
    raise Dry::Struct::Error, "Blackhole routes cannot specify a transit_gateway_attachment_id"
  end
  
  if attrs[:blackhole] != true && !attrs[:transit_gateway_attachment_id]
    raise Dry::Struct::Error, "Non-blackhole routes must specify a transit_gateway_attachment_id"
  end
  
  super(attrs)
end
```

This validation prevents common configuration errors:
- Blackhole routes with target attachments
- Forward routes without target attachments
- Invalid combinations that would fail during Terraform apply

### AWS Resource ID Format Validation

Comprehensive ID format validation for all related resources:

```ruby
# Route table ID validation: tgw-rtb-xxxxxxxx
unless transit_gateway_route_table_id.match?(/\Atgw-rtb-[0-9a-f]{8,17}\z/)
  raise Dry::Struct::Error, "Invalid Transit Gateway Route Table ID format: #{transit_gateway_route_table_id}"
end

# Attachment ID validation: tgw-attach-xxxxxxxx
unless transit_gateway_attachment_id.match?(/\Atgw-attach-[0-9a-f]{8,17}\z/)
  raise Dry::Struct::Error, "Invalid Transit Gateway Attachment ID format: #{transit_gateway_attachment_id}"
end
```

### Intelligent Route Analysis

#### Network Analysis and Classification

Comprehensive network analysis with automatic classification:

```ruby
def network_analysis
  ip, prefix = destination_cidr_block.split('/')
  ip_parts = ip.split('.').map(&:to_i)
  prefix_int = prefix.to_i
  
  analysis = {
    ip_address: ip,
    prefix_length: prefix_int,
    network_size: 2**(32 - prefix_int),                # Calculate addressable hosts
    is_rfc1918_private: is_rfc1918_private?,          # Private address space detection
    is_default_route: is_default_route?,              # Default route detection
    specificity: route_specificity                    # Route specificity classification
  }
  
  # Network class determination (A, B, C, Special)
  if ip_parts[0] >= 1 && ip_parts[0] <= 126
    analysis[:network_class] = 'A'
  elsif ip_parts[0] >= 128 && ip_parts[0] <= 191
    analysis[:network_class] = 'B'
  elsif ip_parts[0] >= 192 && ip_parts[0] <= 223
    analysis[:network_class] = 'C'
  else
    analysis[:network_class] = 'Special'  # Multicast, reserved, etc.
  end
  
  analysis
end
```

#### Route Specificity Classification

Automatic route specificity analysis based on CIDR prefix length:

```ruby
def route_specificity
  prefix_length = destination_cidr_block.split('/')[1].to_i
  
  case prefix_length
  when 0..8
    'very_broad'      # Default routes, large aggregates
  when 9..16
    'broad'          # Typical VPC CIDR blocks
  when 17..24
    'specific'       # Subnet-level routes
  when 25..32
    'very_specific'  # Host routes and small subnets
  end
end
```

This classification enables:
- Automatic impact assessment
- Security risk evaluation
- Operational complexity estimation
- Best practices recommendations

### Security Implications Analysis

Context-aware security analysis based on route characteristics:

```ruby
def security_implications
  implications = []
  
  # Default route analysis
  if is_default_route?
    if is_blackhole_route?
      implications << "Default route blackhole - all unmatched traffic will be dropped"
    else
      implications << "Default route - all unmatched traffic will be forwarded to specified attachment"
      implications << "Default routes have security implications - ensure target attachment is properly secured"
    end
  end
  
  # Blackhole route analysis
  if is_blackhole_route?
    implications << "Blackhole route - traffic to #{destination_cidr_block} will be silently dropped"
    implications << "Blackhole routes are useful for security but may cause connectivity issues if misconfigured"
  end
  
  # Address space analysis
  if is_rfc1918_private?
    implications << "Route targets private address space (RFC 1918)"
  else
    implications << "Route targets public/special address space - verify this is intended"
  end
  
  # Specificity-based implications
  case route_specificity
  when 'very_broad'
    implications << "Very broad route (#{destination_cidr_block}) - affects large address ranges"
  when 'very_specific'
    implications << "Very specific route (#{destination_cidr_block}) - targets small address range or host"
  end
  
  implications
end
```

### Purpose Analysis Engine

Intelligent route purpose detection based on characteristics:

```ruby
def route_purpose_analysis
  purposes = []
  
  # Route type analysis
  if is_default_route?
    purposes << (is_blackhole_route? ? 'default_deny' : 'default_gateway')
  end
  
  # Address space analysis
  purposes << (is_rfc1918_private? ? 'private_network_routing' : 'public_network_routing')
  
  # Traffic action analysis
  purposes << (is_blackhole_route? ? 'traffic_blocking' : 'traffic_forwarding')
  
  # Specificity-based purposes
  case route_specificity
  when 'very_specific'
    purposes << 'host_routing'
  when 'specific'
    purposes << 'subnet_routing'
  when 'broad'
    purposes << 'network_routing'
  when 'very_broad'
    purposes << 'aggregate_routing'
  end
  
  purposes
end
```

### Dynamic Best Practices

Context-aware best practices recommendations:

```ruby
def best_practices
  practices = []
  
  # Default route specific practices
  if is_default_route?
    practices << "Default routes should be carefully managed and documented"
    practices << "Consider using specific routes instead of default when possible"
    if !is_blackhole_route?
      practices << "Ensure default route target can handle all unmatched traffic"
    end
  end
  
  # Blackhole route practices
  if is_blackhole_route?
    practices << "Document blackhole routes for operational clarity"
    practices << "Monitor traffic that hits blackhole routes for troubleshooting"
    practices << "Consider logging dropped traffic for security analysis"
  end
  
  # Specificity-based practices
  case route_specificity
  when 'very_broad'
    practices << "Very broad routes should be used sparingly and with careful consideration"
  when 'very_specific'
    practices << "Host-specific routes may indicate routing inefficiency or special requirements"
  end
  
  # Universal practices
  practices.concat([
    "Use descriptive resource names to indicate route purpose",
    "Document route dependencies and expected traffic patterns", 
    "Implement route change management processes for production environments"
  ])
  
  practices
end
```

## Terraform Resource Synthesis

Clean conditional resource generation:

```ruby
resource(:aws_ec2_transit_gateway_route, name) do
  # Always required
  destination_cidr_block route_attrs.destination_cidr_block
  transit_gateway_route_table_id route_attrs.transit_gateway_route_table_id
  
  # Conditional routing behavior
  if route_attrs.is_blackhole_route?
    blackhole route_attrs.blackhole  # Traffic dropping
  else
    transit_gateway_attachment_id route_attrs.transit_gateway_attachment_id  # Traffic forwarding
  end
end
```

The conditional logic ensures:
- Blackhole routes only set the `blackhole` attribute
- Forward routes only set the `transit_gateway_attachment_id` attribute
- No invalid attribute combinations are generated

## Output Handling

Transit Gateway routes have unique output characteristics:

```ruby
outputs: {
  # Routes don't have standard id/arn outputs
  # They're identified by the combination of route table + CIDR
  route_table_id: "${aws_ec2_transit_gateway_route.#{name}.transit_gateway_route_table_id}",
  destination_cidr_block: "${aws_ec2_transit_gateway_route.#{name}.destination_cidr_block}",
  state: "${aws_ec2_transit_gateway_route.#{name}.state}"  # Route operational state
}
```

Route identification is composite rather than single ID-based, which affects:
- Cross-resource references
- State management
- Import operations

## Architecture Pattern Support

### 1. Hub and Spoke Routing
```ruby
# Hub route table: specific routes to each spoke
spoke_cidrs.each do |spoke_cidr, attachment|
  aws_ec2_transit_gateway_route(:"to_#{spoke_name}", {
    destination_cidr_block: spoke_cidr,
    transit_gateway_route_table_id: hub_rt.id,
    transit_gateway_attachment_id: attachment.id
  })
end

# Spoke route table: default route to hub
aws_ec2_transit_gateway_route(:to_hub, {
  destination_cidr_block: "0.0.0.0/0",
  transit_gateway_route_table_id: spoke_rt.id,
  transit_gateway_attachment_id: hub_attachment.id
})
```

### 2. Security Inspection Routing
```ruby
# Pre-inspection: all traffic to security appliance
aws_ec2_transit_gateway_route(:to_firewall, {
  destination_cidr_block: "0.0.0.0/0",
  transit_gateway_route_table_id: pre_inspection_rt.id,
  transit_gateway_attachment_id: firewall_attachment.id
})

# Post-inspection: specific routes after security validation
approved_networks.each do |network, attachment|
  aws_ec2_transit_gateway_route(:"approved_#{network}", {
    destination_cidr_block: network,
    transit_gateway_route_table_id: post_inspection_rt.id,
    transit_gateway_attachment_id: attachment.id
  })
end

# Block known bad networks
blocked_networks.each do |network|
  aws_ec2_transit_gateway_route(:"block_#{network.tr('./', '_')}", {
    destination_cidr_block: network,
    transit_gateway_route_table_id: post_inspection_rt.id,
    blackhole: true
  })
end
```

### 3. Network Segmentation
```ruby
# Production: only shared services access
aws_ec2_transit_gateway_route(:prod_to_shared, {
  destination_cidr_block: "10.100.0.0/16",  # Shared services CIDR
  transit_gateway_route_table_id: prod_rt.id,
  transit_gateway_attachment_id: shared_services_attachment.id
})

# Block production access to other environments
other_environment_cidrs.each do |cidr|
  aws_ec2_transit_gateway_route(:"block_prod_#{cidr.tr('./', '_')}", {
    destination_cidr_block: cidr,
    transit_gateway_route_table_id: prod_rt.id,
    blackhole: true
  })
end
```

## Integration Patterns

### Route Table Relationship
```ruby
# Routes depend on route tables
route_table = aws_ec2_transit_gateway_route_table(:custom, {
  transit_gateway_id: tgw.id
})

# Routes reference the route table
route = aws_ec2_transit_gateway_route(:to_vpc, {
  transit_gateway_route_table_id: route_table.id,  # Dependency
  destination_cidr_block: "10.1.0.0/16",
  transit_gateway_attachment_id: vpc_attachment.id
})
```

### Attachment Dependency
```ruby
# Forward routes depend on attachments
vpc_attachment = aws_ec2_transit_gateway_vpc_attachment(:app_vpc, {
  transit_gateway_id: tgw.id,
  vpc_id: app_vpc.id,
  subnet_ids: [subnet.id]
})

# Route references the attachment
route = aws_ec2_transit_gateway_route(:to_app, {
  transit_gateway_route_table_id: route_table.id,
  destination_cidr_block: "10.1.0.0/16",
  transit_gateway_attachment_id: vpc_attachment.id  # Dependency
})
```

## Validation Strategy

### Static Validation
- CIDR block format validation using custom type
- AWS resource ID format validation
- Blackhole vs forward route logic validation

### Configuration Validation
- Mutually exclusive attribute checking
- Required attribute presence validation
- Route table and attachment compatibility

### Runtime Validation
- AWS resource existence (handled by Terraform)
- Route conflicts and duplicates (handled by AWS)
- Attachment state validation (handled by AWS)

## Error Handling

Comprehensive error messages for common issues:

```ruby
# Route logic errors
raise Dry::Struct::Error, "Blackhole routes cannot specify a transit_gateway_attachment_id. Set blackhole: true without attachment_id for traffic drop."

raise Dry::Struct::Error, "Non-blackhole routes must specify a transit_gateway_attachment_id for traffic forwarding."

# Resource ID format errors  
raise Dry::Struct::Error, "Invalid Transit Gateway Route Table ID format: #{transit_gateway_route_table_id}. Expected format: tgw-rtb-xxxxxxxx"

raise Dry::Struct::Error, "Invalid Transit Gateway Attachment ID format: #{transit_gateway_attachment_id}. Expected format: tgw-attach-xxxxxxxx"
```

## Testing Considerations

### Unit Tests
- CIDR block validation and parsing
- Route specificity classification accuracy
- Security implications analysis
- Purpose detection logic
- Best practices recommendation relevance

### Integration Tests
- Terraform resource generation validation
- Cross-resource dependency resolution
- Route conflict detection
- Blackhole vs forward route behavior

## Performance Characteristics

### Resource Creation
- Fast route creation (~10-30 seconds)
- Immediate traffic impact once active
- State propagation across Transit Gateway

### Route Evaluation
- Routes evaluated in order of specificity (longest prefix match)
- Static routes override propagated routes
- Blackhole routes processed before forward routes

This implementation provides a production-ready foundation for Transit Gateway route management with comprehensive analysis, security assessment, and intelligent configuration guidance for complex routing scenarios.