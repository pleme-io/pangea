# AWS Network ACL Rule Implementation Documentation

## Overview

This directory contains the implementation for the `aws_network_acl_rule` resource function, providing type-safe creation and management of AWS Network ACL Rule resources through terraform-synthesizer integration.

## Implementation Architecture

### Core Components

#### 1. Resource Function (`resource.rb`)
The main `aws_network_acl_rule` function that:
- Accepts a symbol name and attributes hash
- Validates attributes using dry-struct types
- Generates terraform resource blocks via terraform-synthesizer
- Returns ResourceReference with computed outputs and properties

#### 2. Type Definitions (`types.rb`)
NetworkAclRuleAttributes dry-struct defining:
- Required attributes: `network_acl_id`, `rule_number`, `protocol`, `rule_action`
- Optional attributes: `egress`, `cidr_block`, `ipv6_cidr_block`, `from_port`, `to_port`, `icmp_type`, `icmp_code`
- Custom validations for protocol-specific requirements
- Computed properties for rule analysis

#### 3. Documentation
- **CLAUDE.md** (this file): Implementation details for developers
- **README.md**: User-facing documentation with examples

## Technical Implementation Details

### AWS Network ACL Rules

Network ACL rules are stateless packet filters that control inbound and outbound traffic at the subnet level. Key characteristics:

- **Stateless**: Unlike security groups, return traffic must be explicitly allowed
- **Rule Priority**: Rules are evaluated in order by rule number (1-32766)
- **Default Action**: Implicit deny if no rules match
- **Subnet Association**: Rules apply to all instances in associated subnets
- **Protocol Support**: TCP, UDP, ICMP, ICMPv6, or custom protocol numbers

### Type Validation Logic

```ruby
class NetworkAclRuleAttributes < Dry::Struct
  # Core validations:
  # 1. Either cidr_block or ipv6_cidr_block must be specified (not both)
  # 2. TCP/UDP protocols require from_port and to_port
  # 3. ICMP protocols use icmp_type and icmp_code (not ports)
  # 4. Protocol -1 (all) cannot have port or ICMP specifications
  # 5. ICMPv6 requires IPv6 CIDR block
  
  # Rule number constraints
  attribute :rule_number, Types::Integer.constrained(gteq: 1, lteq: 32766)
  
  # Protocol validation with number/name support
  attribute :protocol, Types::String  # "tcp", "udp", "icmp", "-1", or protocol number
  
  # IPv6 CIDR validation using complex regex
  attribute? :ipv6_cidr_block, Types::String.optional.constrained(
    format: /\A(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|...)\/\d{1,3}\z/
  )
end
```

### Terraform Synthesis

The resource function generates terraform JSON through terraform-synthesizer:

```ruby
resource(:aws_network_acl_rule, name) do
  # Required attributes always mapped
  network_acl_id attrs.network_acl_id
  rule_number attrs.rule_number
  protocol attrs.protocol
  rule_action attrs.rule_action
  egress attrs.egress  # Always specified, defaults to false
  
  # Conditional mappings based on validation
  cidr_block attrs.cidr_block if attrs.cidr_block
  ipv6_cidr_block attrs.ipv6_cidr_block if attrs.ipv6_cidr_block
  
  # Protocol-specific attributes
  from_port attrs.from_port if attrs.from_port  # TCP/UDP only
  to_port attrs.to_port if attrs.to_port        # TCP/UDP only
  icmp_type attrs.icmp_type if attrs.icmp_type  # ICMP only
  icmp_code attrs.icmp_code if attrs.icmp_code  # ICMP only
end
```

### ResourceReference Return Value

The function returns a ResourceReference providing:

#### Terraform Outputs
- `id`: Composite ID in format `nacl-xxxxx:rule_number:protocol:egress`

#### Computed Properties
- `ingress`: Boolean indicating if rule is for inbound traffic
- `allow`: Boolean indicating if rule allows traffic
- `deny`: Boolean indicating if rule denies traffic
- `ipv6`: Boolean indicating if rule uses IPv6
- `ipv4`: Boolean indicating if rule uses IPv4
- `protocol_name`: Human-readable protocol name (e.g., "tcp" for protocol "6")
- `rule_type`: Description like "allow ingress" or "deny egress"

## Integration Patterns

### 1. Basic Web Server ACL
```ruby
template :web_server_acl do
  nacl = aws_network_acl(:web, { vpc_id: vpc.id })
  
  # Ordered rules for web traffic
  aws_network_acl_rule(:http_in, {
    network_acl_id: nacl.id,
    rule_number: 100,
    protocol: "tcp",
    rule_action: "allow",
    cidr_block: "0.0.0.0/0",
    from_port: 80,
    to_port: 80
  })
  
  # Corresponding egress for responses
  aws_network_acl_rule(:ephemeral_out, {
    network_acl_id: nacl.id,
    rule_number: 100,
    protocol: "tcp",
    rule_action: "allow",
    egress: true,
    cidr_block: "0.0.0.0/0",
    from_port: 1024,
    to_port: 65535
  })
end
```

### 2. Multi-Protocol Rules
```ruby
template :multi_protocol do
  # All traffic from trusted network
  aws_network_acl_rule(:trust_all, {
    network_acl_id: nacl_id,
    rule_number: 50,
    protocol: "-1",  # All protocols
    rule_action: "allow",
    cidr_block: "10.0.0.0/8"
  })
  
  # ICMP for diagnostics
  aws_network_acl_rule(:icmp_ping, {
    network_acl_id: nacl_id,
    rule_number: 200,
    protocol: "icmp",
    rule_action: "allow",
    cidr_block: "0.0.0.0/0",
    icmp_type: 8,  # Echo request
    icmp_code: 0
  })
end
```

## Error Handling and Validation

### Common Validation Errors

1. **CIDR Block Conflicts**
   - Error: "Cannot specify both 'cidr_block' and 'ipv6_cidr_block'"
   - Solution: Use separate rules for IPv4 and IPv6

2. **Protocol-Specific Attribute Mismatches**
   - Error: "'from_port' and 'to_port' are required for TCP/UDP protocols"
   - Solution: Always specify port range for TCP/UDP
   - Error: "Cannot specify 'from_port' or 'to_port' for ICMP protocol"
   - Solution: Use icmp_type and icmp_code for ICMP

3. **Rule Number Constraints**
   - Error: Rule number must be between 1 and 32766
   - Solution: Use appropriate rule numbers with gaps for future rules

4. **IPv6 Protocol Requirements**
   - Error: "ICMPv6 protocol requires 'ipv6_cidr_block'"
   - Solution: Use ipv6_cidr_block for IPv6-specific protocols

## Testing Strategy

### Unit Tests
```ruby
RSpec.describe Pangea::Resources::AWS do
  describe "#aws_network_acl_rule" do
    it "creates a valid TCP rule" do
      rule = aws_network_acl_rule(:http, {
        network_acl_id: "nacl-12345",
        rule_number: 100,
        protocol: "tcp",
        rule_action: "allow",
        cidr_block: "0.0.0.0/0",
        from_port: 80,
        to_port: 80
      })
      
      expect(rule.outputs[:id]).to include("aws_network_acl_rule.http.id")
      expect(rule.computed_properties[:protocol_name]).to eq("tcp")
    end
    
    it "validates CIDR block requirements" do
      expect {
        aws_network_acl_rule(:invalid, {
          network_acl_id: "nacl-12345",
          rule_number: 100,
          protocol: "tcp",
          rule_action: "allow"
          # Missing CIDR block
        })
      }.to raise_error(Dry::Struct::Error, /Must specify either 'cidr_block' or 'ipv6_cidr_block'/)
    end
    
    it "enforces protocol-specific validations" do
      expect {
        aws_network_acl_rule(:invalid_tcp, {
          network_acl_id: "nacl-12345",
          rule_number: 100,
          protocol: "tcp",
          rule_action: "allow",
          cidr_block: "0.0.0.0/0"
          # Missing ports for TCP
        })
      }.to raise_error(Dry::Struct::Error, /'from_port' and 'to_port' are required/)
    end
  end
end
```

## Security Best Practices

1. **Principle of Least Privilege**
   - Only allow required protocols and ports
   - Use specific CIDR blocks instead of 0.0.0.0/0 when possible
   - Place deny rules before allow rules (lower rule numbers)

2. **Stateless Considerations**
   - Always create corresponding egress rules for return traffic
   - Be explicit about ephemeral port ranges (1024-65535)
   - Remember that NACLs don't track connection state

3. **Defense in Depth**
   - Use NACLs as subnet-level protection
   - Combine with security groups for instance-level protection
   - End rule sets with explicit deny-all rules

4. **Rule Organization**
   - Reserve low rule numbers (1-50) for critical deny rules
   - Group related allow rules (100-900)
   - Leave gaps between rules for future modifications

## Future Enhancements

1. **Rule Set Templates**
   - Pre-built rule sets for common scenarios (web, database, etc.)
   - Function to generate paired ingress/egress rules automatically

2. **Enhanced Validations**
   - Warn about overlapping CIDR blocks
   - Validate rule number uniqueness within a template
   - Check for common security anti-patterns

3. **Protocol Helpers**
   - Constants for common protocols (HTTP, HTTPS, SSH, RDP)
   - Port range helpers for ephemeral ports
   - ICMP type/code constants

4. **Integration Features**
   - Auto-generate return traffic rules for stateless behavior
   - Rule conflict detection and resolution
   - Integration with aws_network_acl_association

## Implementation Notes

### Protocol Number Mapping
The implementation supports both protocol names and numbers:
- TCP: "tcp" or "6"
- UDP: "udp" or "17" 
- ICMP: "icmp" or "1"
- ICMPv6: "icmpv6" or "58"
- All: "-1"

### Rule ID Format
The AWS provider generates rule IDs in the format:
`nacl-xxxxx:rule_number:protocol:egress`

This allows unique identification of rules within a Network ACL.

### Terraform State Considerations
Network ACL rules are managed as separate resources in Terraform state, allowing:
- Independent lifecycle management
- Granular imports of existing rules
- Safe modification without affecting other rules