# Web Security Group Component

## Overview

The `web_security_group` component creates a security group specifically optimized for web servers with configurable HTTP/HTTPS access, optional SSH access, and comprehensive security analysis. This component provides intelligent defaults while allowing customization for various web server deployment patterns.

## Purpose

This component addresses the common need for web server security groups that balance accessibility with security. It provides pre-configured rules for web traffic while offering granular control over administrative access, outbound connectivity, and security posture assessment.

## Features

### Web-Optimized Security Rules
- **HTTP/HTTPS Access**: Configurable web protocols with standard or custom ports
- **SSH Administration**: Optional SSH access with restricted CIDR blocks
- **Custom Ports**: Support for custom application ports
- **ICMP Ping**: Configurable ping/ICMP support for monitoring

### Intelligent Security Analysis
- **Risk Assessment**: Automatic security risk level evaluation
- **Compliance Profiling**: Built-in compliance feature analysis
- **Security Recommendations**: Actionable security improvement suggestions
- **Port Analysis**: Detailed analysis of port usage patterns

### Flexible Access Control
- **CIDR Block Management**: Separate CIDR blocks for web traffic and SSH access
- **Outbound Control**: Configurable outbound internet and VPC communication
- **Security Profiles**: Pre-defined security profiles (basic, standard, strict, custom)
- **Administrative Separation**: Separate access controls for web and admin traffic

## Usage

### Basic Web Security Group

```ruby
template :web_security do
  include Pangea::Resources::AWS
  include Pangea::Components::WebSecurityGroup
  
  # Create VPC first
  vpc = aws_vpc(:main, {
    cidr_block: "10.0.0.0/16"
  })
  
  # Create basic web security group
  web_sg = web_security_group(:web_servers, {
    vpc_ref: vpc,
    description: "Security group for web servers"
  })
  
  # Use in web server instances
  web_instance = aws_instance(:web_server, {
    ami: "ami-12345678",
    instance_type: "t3.micro",
    vpc_security_group_ids: [web_sg.security_group_id]
  })
end
```

### Production Web Security Group

```ruby
# Production web security group with enhanced security
production_web_sg = web_security_group(:production_web, {
  vpc_ref: production_vpc,
  description: "Production web servers security group",
  
  # Web protocol configuration
  enable_http: false,          # Disable HTTP, force HTTPS
  enable_https: true,
  https_port: 443,
  
  # Administrative access
  enable_ssh: true,
  ssh_port: 22,
  ssh_cidr_blocks: ["10.0.0.0/8"],  # Restrict SSH to internal networks
  
  # Security configuration
  enable_ping: false,          # Disable ping for security
  enable_outbound_internet: true,
  enable_vpc_communication: true,
  
  # Access control
  allowed_cidr_blocks: ["0.0.0.0/0"],  # Web traffic from anywhere
  security_profile: "strict",
  
  tags: {
    Environment: "production",
    SecurityLevel: "high",
    Compliance: "required",
    Purpose: "web_servers"
  }
})

# Check security posture
puts "Security risk level: #{production_web_sg.security_risk_level}"
puts "Security recommendations:"
production_web_sg.security_recommendations.each { |rec| puts "  - #{rec}" }
```

### Development Web Security Group

```ruby
# Development environment with SSH access
dev_web_sg = web_security_group(:dev_web, {
  vpc_ref: dev_vpc,
  description: "Development web servers security group",
  
  # Enable both HTTP and HTTPS for development
  enable_http: true,
  enable_https: true,
  
  # Enable SSH for development access
  enable_ssh: true,
  ssh_cidr_blocks: ["10.1.0.0/16"],  # Restrict to dev VPC
  
  # Enable ping for troubleshooting
  enable_ping: true,
  
  security_profile: "standard",
  
  tags: {
    Environment: "development",
    SecurityLevel: "standard",
    Purpose: "development_servers"
  }
})
```

### Custom Application Security Group

```ruby
# Custom web application with non-standard ports
custom_app_sg = web_security_group(:custom_app, {
  vpc_ref: vpc,
  description: "Custom web application security group",
  
  # Standard web protocols
  enable_http: true,
  enable_https: true,
  
  # Custom application ports
  custom_ports: [8080, 8443, 9090],
  
  # Restricted access
  allowed_cidr_blocks: ["10.0.0.0/8", "192.168.0.0/16"],
  
  # No SSH access (managed through bastion)
  enable_ssh: false,
  
  # Custom outbound rules
  enable_outbound_internet: false,  # No internet access
  enable_vpc_communication: true,   # Only VPC communication
  
  security_profile: "custom",
  
  tags: {
    Application: "custom_app",
    SecurityModel: "internal_only"
  }
})
```

### Load Balancer Security Group

```ruby
# Security group for load balancers
lb_sg = web_security_group(:load_balancer, {
  vpc_ref: vpc,
  description: "Load balancer security group",
  
  # Web protocols for load balancer
  enable_http: true,
  enable_https: true,
  
  # No SSH access for load balancers
  enable_ssh: false,
  enable_ping: false,
  
  # Internet-facing access
  allowed_cidr_blocks: ["0.0.0.0/0"],
  
  # Outbound to VPC for health checks
  enable_outbound_internet: false,
  enable_vpc_communication: true,
  
  security_profile: "standard"
})
```

## Attributes

### Required Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `vpc_ref` | ResourceReference/String | VPC to create security group in |

### Optional Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `description` | String | `"Web servers security group"` | Security group description |
| `enable_http` | Boolean | `true` | Enable HTTP access |
| `enable_https` | Boolean | `true` | Enable HTTPS access |
| `enable_ssh` | Boolean | `false` | Enable SSH access |
| `http_port` | Integer | `80` | HTTP port number |
| `https_port` | Integer | `443` | HTTPS port number |
| `ssh_port` | Integer | `22` | SSH port number |
| `custom_ports` | Array[Integer] | `[]` | Additional custom ports |
| `allowed_cidr_blocks` | Array[String] | `["0.0.0.0/0"]` | CIDR blocks for web access |
| `ssh_cidr_blocks` | Array[String] | `["10.0.0.0/8"]` | CIDR blocks for SSH access |
| `enable_ping` | Boolean | `false` | Enable ICMP ping |
| `enable_outbound_internet` | Boolean | `true` | Enable outbound internet access |
| `enable_vpc_communication` | Boolean | `true` | Enable VPC communication |
| `tags` | Hash | `{}` | Tags for the security group |
| `security_profile` | String | `'standard'` | Security profile: `'basic'`, `'standard'`, `'strict'`, `'custom'` |

## Security Profiles

### Basic Profile (`security_profile: 'basic'`)
- HTTP and HTTPS enabled
- SSH typically disabled
- Basic outbound rules
- Minimal security restrictions

### Standard Profile (`security_profile: 'standard'`)
- HTTP and HTTPS enabled
- SSH with restricted access
- Standard outbound rules
- Balanced security and functionality

### Strict Profile (`security_profile: 'strict'`)
- HTTPS only (HTTP disabled)
- SSH with very restricted access
- Limited outbound rules
- Maximum security restrictions

### Custom Profile (`security_profile: 'custom'`)
- Fully customized configuration
- No default assumptions
- User-defined security model

## Resources Created

### Security Group Infrastructure

1. **aws_security_group**: Web server security group
   - Configured ingress rules for web protocols
   - Configured egress rules for outbound access
   - Comprehensive tagging for management

## Ingress Rules Created

### HTTP Traffic (if enabled)
- **Port**: Configurable (default: 80)
- **Protocol**: TCP
- **Source**: Configurable CIDR blocks (default: 0.0.0.0/0)
- **Description**: "HTTP web traffic"

### HTTPS Traffic (if enabled)
- **Port**: Configurable (default: 443)
- **Protocol**: TCP
- **Source**: Configurable CIDR blocks (default: 0.0.0.0/0)
- **Description**: "HTTPS web traffic"

### SSH Access (if enabled)
- **Port**: Configurable (default: 22)
- **Protocol**: TCP
- **Source**: Configurable CIDR blocks (default: 10.0.0.0/8)
- **Description**: "SSH administrative access"

### Custom Ports (if configured)
- **Ports**: User-defined custom ports
- **Protocol**: TCP
- **Source**: Same as web traffic CIDR blocks
- **Description**: "Custom port {port_number}"

### ICMP Ping (if enabled)
- **Port**: -1 (all ICMP)
- **Protocol**: ICMP
- **Source**: Same as web traffic CIDR blocks
- **Description**: "ICMP ping"

## Egress Rules Created

### Outbound Internet Access (if enabled)
- **Ports**: 0-65535
- **Protocols**: TCP and UDP
- **Destination**: 0.0.0.0/0
- **Description**: "All outbound traffic to internet"

### VPC Communication (if enabled and outbound internet disabled)
- **Ports**: 0-65535
- **Protocol**: TCP
- **Destination**: VPC CIDR block
- **Description**: "All TCP traffic within VPC"

## Outputs

### Security Group Information
- `security_group_id`: Security group identifier
- `security_group_arn`: Security group ARN
- `security_group_name`: Security group name
- `vpc_id`: VPC identifier

### Port Configuration
- `enabled_ports`: Array of all enabled ports
- `web_ports`: Array of web-specific ports (HTTP, HTTPS, custom web ports)
- `admin_ports`: Array of administrative ports (SSH, RDP, etc.)

### Security Analysis
- `security_risk_level`: Risk level assessment (`'low'`, `'medium'`, `'high'`)
- `security_profile`: Applied security profile
- `security_recommendations`: Array of security improvement recommendations
- `compliance_profile`: Compliance feature analysis

### Rule Information
- `inbound_rules_summary`: Detailed inbound rules analysis
- `outbound_rules_summary`: Detailed outbound rules analysis
- `ingress_rule_count`: Number of ingress rules created
- `egress_rule_count`: Number of egress rules created

### Access Configuration
- `http_enabled`: Whether HTTP is enabled
- `https_enabled`: Whether HTTPS is enabled
- `ssh_enabled`: Whether SSH is enabled
- `ping_enabled`: Whether ICMP ping is enabled
- `outbound_internet_enabled`: Whether outbound internet access is enabled
- `vpc_communication_enabled`: Whether VPC communication is enabled

### Network Access
- `allowed_cidr_blocks`: CIDR blocks allowed for web access
- `ssh_cidr_blocks`: CIDR blocks allowed for SSH access
- `internet_accessible`: Whether accessible from the internet

### Port Analysis
- `port_usage_analysis`: Detailed port usage analysis

## Component Reference Usage

```ruby
# Access security group resource
security_group = web_sg.resources[:security_group]

# Use security group in other resources
web_server = aws_instance(:web, {
  vpc_security_group_ids: [web_sg.security_group_id]
})

load_balancer = aws_lb(:web_lb, {
  security_groups: [web_sg.security_group_id]
})

# Check security posture
if web_sg.security_risk_level == 'high'
  puts "Security risk detected!"
  web_sg.security_recommendations.each do |recommendation|
    puts "  - #{recommendation}"
  end
end

# Analyze port usage
analysis = web_sg.port_usage_analysis
puts "Web ports: #{analysis[:web_ports]} ports"
puts "Admin ports: #{analysis[:admin_ports]} ports"
puts "Internet accessible: #{analysis[:internet_accessible]}"

# Check compliance
compliance = web_sg.compliance_profile
puts "Compliance level: #{compliance[:level]}"
puts "Features: #{compliance[:features].join(', ')}"
```

## Security Risk Assessment

The component automatically evaluates security risks:

### Low Risk
- HTTPS enabled
- SSH restricted to internal networks
- No unnecessary open ports
- Outbound access controlled

### Medium Risk
- HTTP enabled alongside HTTPS
- SSH with some restrictions
- Some wide-open access patterns
- Ping enabled

### High Risk
- SSH open to internet (0.0.0.0/0)
- HTTP only (no HTTPS)
- Wide-open access from anywhere
- Multiple risk factors combined

## Security Recommendations

The component provides actionable security recommendations:

### Common Recommendations
1. **Restrict SSH access** to specific IP ranges or use a bastion host
2. **Enable HTTPS** and consider redirecting HTTP to HTTPS
3. **Limit wide-open access** to specific IP ranges when possible
4. **Disable ping** if not required for monitoring
5. **Review outbound access** to ensure instances can reach required services

### Example Security Analysis
```ruby
web_sg = web_security_group(:example, {
  vpc_ref: vpc,
  enable_ssh: true,
  ssh_cidr_blocks: ["0.0.0.0/0"],  # High risk
  enable_http: true,               # Medium risk
  enable_https: false              # High risk
})

puts web_sg.security_risk_level
# Output: "high"

puts web_sg.security_recommendations
# Output: [
#   "Restrict SSH access to specific IP ranges or use a bastion host",
#   "Enable HTTPS and consider redirecting HTTP to HTTPS"
# ]
```

## Validation and Constraints

### Port Conflict Validation
- Custom ports cannot conflict with enabled standard ports
- Duplicate ports in custom port list are not allowed

### CIDR Block Validation
- All CIDR blocks must be in valid CIDR notation format
- Invalid CIDR blocks will trigger validation errors

### Security Configuration Validation
- At least one web protocol (HTTP, HTTPS) or custom port must be enabled
- SSH CIDR blocks are validated for security risk patterns

### Protocol Validation
- Port numbers must be within valid range (0-65535)
- Standard ports are validated against their protocols

## Integration Patterns

### With Web Tier Subnets

```ruby
# Create web subnets
web_subnets = web_tier_subnets(:web_tier, {
  vpc_ref: vpc,
  subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24"]
})

# Create security group for web tier
web_sg = web_security_group(:web_servers, {
  vpc_ref: vpc,
  description: "Web servers in web tier subnets"
})

# Deploy instances in web subnets with security group
web_instances = aws_autoscaling_group(:web_servers, {
  vpc_zone_identifier: web_subnets.subnet_ids,
  security_groups: [web_sg.security_group_id]
})
```

### With Load Balancer

```ruby
# Load balancer security group
lb_sg = web_security_group(:load_balancer, {
  vpc_ref: vpc,
  description: "Load balancer security group",
  enable_ssh: false,  # No SSH for load balancers
  allowed_cidr_blocks: ["0.0.0.0/0"]
})

# Application server security group  
app_sg = web_security_group(:app_servers, {
  vpc_ref: vpc,
  description: "Application servers behind load balancer",
  enable_ssh: true,
  ssh_cidr_blocks: ["10.0.0.0/8"],  # Internal SSH only
  allowed_cidr_blocks: [lb_sg.security_group_id]  # Only from load balancer
})

# Create load balancer
lb = aws_lb(:web_lb, {
  security_groups: [lb_sg.security_group_id]
})
```

### With Database Tier

```ruby
# Web tier security group
web_sg = web_security_group(:web_servers, {
  vpc_ref: vpc,
  allowed_cidr_blocks: ["0.0.0.0/0"]
})

# Database security group (separate component)
db_sg = aws_security_group(:database, {
  vpc_id: vpc.id,
  ingress_rules: [{
    from_port: 3306,
    to_port: 3306,
    protocol: "tcp",
    source_security_group_id: web_sg.security_group_id,
    description: "MySQL access from web servers"
  }]
})
```

## Advanced Configuration Examples

### Multi-Tier Application

```ruby
# Public load balancer security group
public_lb_sg = web_security_group(:public_lb, {
  vpc_ref: vpc,
  description: "Public load balancer",
  allowed_cidr_blocks: ["0.0.0.0/0"],
  enable_ssh: false
})

# Internal application security group
app_sg = web_security_group(:app_servers, {
  vpc_ref: vpc,
  description: "Application servers", 
  allowed_cidr_blocks: [public_lb_sg.security_group_id],  # Only from LB
  enable_ssh: true,
  ssh_cidr_blocks: ["10.0.0.0/16"]  # Internal SSH
})

# Internal load balancer for backend services
internal_lb_sg = web_security_group(:internal_lb, {
  vpc_ref: vpc,
  description: "Internal load balancer",
  allowed_cidr_blocks: [app_sg.security_group_id],  # Only from app servers
  enable_outbound_internet: false,  # No internet access
  enable_vpc_communication: true
})
```

### Custom Application Ports

```ruby
# Microservice with custom ports
microservice_sg = web_security_group(:microservice, {
  vpc_ref: vpc,
  description: "Microservice security group",
  
  # Disable standard web ports
  enable_http: false,
  enable_https: false,
  
  # Custom application ports
  custom_ports: [8080, 8443, 9000, 9001],
  
  # Internal access only
  allowed_cidr_blocks: ["10.0.0.0/8"],
  
  # No outbound internet
  enable_outbound_internet: false,
  enable_vpc_communication: true,
  
  security_profile: "custom"
})
```

## Best Practices

### Security Best Practices
1. **Use HTTPS** whenever possible, disable HTTP in production
2. **Restrict SSH access** to bastion hosts or specific IP ranges
3. **Apply principle of least privilege** - only open required ports
4. **Use separate security groups** for different tiers (web, app, db)
5. **Regular security review** using the built-in risk assessment

### Operational Best Practices
1. **Tag comprehensively** for security group management
2. **Use descriptive names** for easy identification
3. **Document custom ports** and their purposes
4. **Monitor security group changes** for compliance
5. **Regular security posture assessment** using component outputs

### Network Design Best Practices
1. **Layer security groups** for defense in depth
2. **Use security group references** instead of CIDR blocks for internal communication
3. **Separate public and private security groups**
4. **Implement bastion host patterns** for administrative access
5. **Regular review of outbound rules** to prevent data exfiltration

## Error Handling

Common configuration errors and solutions:

### Port Conflict Errors
```ruby
# Error: Custom port conflicts with enabled standard port
web_security_group(:test, {
  enable_http: true,
  http_port: 80,
  custom_ports: [80, 8080]  # 80 conflicts with HTTP port
})
# Solution: Remove conflicting port from custom_ports or change standard port
```

### Invalid CIDR Errors
```ruby
# Error: Invalid CIDR block format
web_security_group(:test, {
  allowed_cidr_blocks: ["10.0.0.0/33"]  # Invalid subnet mask
})
# Solution: Use valid CIDR notation (0-32 for IPv4)
```

### No Enabled Protocols Error
```ruby
# Error: No web protocols enabled
web_security_group(:test, {
  enable_http: false,
  enable_https: false,
  custom_ports: []  # No ports enabled
})
# Solution: Enable at least one protocol or add custom ports
```

## Testing

```ruby
RSpec.describe Pangea::Components::WebSecurityGroup do
  describe "#web_security_group" do
    it "creates web security group with default configuration" do
      vpc = double('vpc', id: 'vpc-12345')
      
      sg = web_security_group(:test, {
        vpc_ref: vpc
      })
      
      expect(sg).to be_a(ComponentReference)
      expect(sg.type).to eq('web_security_group')
      expect(sg.resources[:security_group]).to be_present
      expect(sg.http_enabled).to be true
      expect(sg.https_enabled).to be true
      expect(sg.ssh_enabled).to be false
    end
    
    it "validates port conflicts" do
      expect {
        web_security_group(:test, {
          enable_http: true,
          http_port: 80,
          custom_ports: [80, 8080]
        })
      }.to raise_error(Dry::Struct::Error, /conflict/)
    end
    
    it "assesses security risk correctly" do
      high_risk_sg = web_security_group(:test, {
        enable_ssh: true,
        ssh_cidr_blocks: ["0.0.0.0/0"],
        enable_http: true,
        enable_https: false
      })
      
      expect(high_risk_sg.security_risk_level).to eq('high')
      expect(high_risk_sg.security_recommendations).to include(/SSH access/)
    end
    
    it "provides security recommendations" do
      sg = web_security_group(:test, {
        enable_ssh: true,
        ssh_cidr_blocks: ["0.0.0.0/0"]
      })
      
      expect(sg.security_recommendations).to include(
        "Restrict SSH access to specific IP ranges or use a bastion host"
      )
    end
  end
end
```

This web security group component provides comprehensive, secure-by-default web server security groups with intelligent risk assessment and actionable security recommendations.