# Web Security Group Component

Security group optimized for web servers with intelligent risk assessment and configurable access rules.

## Quick Start

```ruby
# Include the component
include Pangea::Components::WebSecurityGroup

# Create web security group
web_sg = web_security_group(:web_servers, {
  vpc_ref: vpc,
  description: "Security group for web servers"
})

# Use in instances
web_server = aws_instance(:web, {
  vpc_security_group_ids: [web_sg.security_group_id]
})
```

## What It Creates

- ✅ **Security Group** - Web-optimized security group with ingress/egress rules
- ✅ **HTTP/HTTPS Rules** - Configurable web protocol access  
- ✅ **SSH Rules** - Optional administrative access with CIDR restrictions
- ✅ **Custom Ports** - Support for additional application ports
- ✅ **Security Analysis** - Built-in risk assessment and recommendations

## Key Features

- 🔒 **Secure by Default** - HTTPS enabled, SSH restricted to internal networks
- 🧠 **Intelligent Analysis** - Automatic security risk assessment
- 💡 **Smart Recommendations** - Actionable security improvement suggestions  
- 🔧 **Flexible Configuration** - Customizable for various web server patterns
- 📊 **Compliance Ready** - Built-in compliance feature tracking

## Common Usage Patterns

### Production Web Servers
```ruby
production_web_sg = web_security_group(:production_web, {
  vpc_ref: vpc,
  description: "Production web servers security group",
  
  # Security-first configuration
  enable_http: false,          # HTTPS only
  enable_https: true,
  
  # Restricted SSH access
  enable_ssh: true,
  ssh_cidr_blocks: ["10.0.0.0/8"],  # Internal networks only
  
  # Security hardening
  enable_ping: false,          # Disable ping
  security_profile: "strict",
  
  tags: {
    Environment: "production",
    SecurityLevel: "high"
  }
})

# Check security posture
puts "Risk level: #{production_web_sg.security_risk_level}"
puts "Recommendations: #{production_web_sg.security_recommendations}"
```

### Development Environment
```ruby
dev_web_sg = web_security_group(:dev_web, {
  vpc_ref: vpc,
  
  # Both protocols for testing
  enable_http: true,
  enable_https: true,
  
  # SSH for development
  enable_ssh: true,
  ssh_cidr_blocks: ["10.1.0.0/16"],  # Dev VPC only
  
  # Enable ping for troubleshooting
  enable_ping: true,
  
  security_profile: "standard",
  
  tags: {
    Environment: "development"
  }
})
```

### Load Balancer Security Group
```ruby
lb_sg = web_security_group(:load_balancer, {
  vpc_ref: vpc,
  description: "Load balancer security group",
  
  # Web protocols only
  enable_http: true,
  enable_https: true,
  
  # No SSH for load balancers
  enable_ssh: false,
  enable_ping: false,
  
  # Internet-facing access
  allowed_cidr_blocks: ["0.0.0.0/0"],
  
  # Outbound to VPC only (for health checks)
  enable_outbound_internet: false,
  enable_vpc_communication: true
})
```

### Custom Application Ports
```ruby
custom_app_sg = web_security_group(:custom_app, {
  vpc_ref: vpc,
  
  # Standard web ports
  enable_http: true,
  enable_https: true,
  
  # Custom application ports
  custom_ports: [8080, 8443, 9090],
  
  # Internal access only
  allowed_cidr_blocks: ["10.0.0.0/8"],
  
  security_profile: "custom"
})
```

## Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `vpc_ref` | ResourceReference/String | VPC to create security group in |

## Key Configuration Options

### Web Protocol Configuration
```ruby
enable_http: true                   # Enable HTTP (port 80)
enable_https: true                  # Enable HTTPS (port 443)
http_port: 80                       # Custom HTTP port
https_port: 443                     # Custom HTTPS port
custom_ports: [8080, 8443]          # Additional custom ports
```

### SSH Administrative Access
```ruby
enable_ssh: false                   # Enable SSH access
ssh_port: 22                        # SSH port number
ssh_cidr_blocks: ["10.0.0.0/8"]     # SSH access CIDR blocks (restricted by default)
```

### Network Access Control  
```ruby
allowed_cidr_blocks: ["0.0.0.0/0"]  # Web traffic CIDR blocks
enable_ping: false                  # Enable ICMP ping
enable_outbound_internet: true      # Enable outbound internet access
enable_vpc_communication: true      # Enable VPC communication
```

### Security Profiles
```ruby
security_profile: "standard"        # Security profile: basic/standard/strict/custom
```

## Security Profiles

| Profile | HTTP | HTTPS | SSH | Outbound | Use Case |
|---------|------|--------|-----|----------|----------|
| **basic** | ✅ | ✅ | ❌ | ✅ | Simple web servers |
| **standard** | ✅ | ✅ | ⚠️ Restricted | ✅ | Production web servers |
| **strict** | ❌ | ✅ | ⚠️ Very restricted | ⚠️ Limited | High-security environments |
| **custom** | 🔧 User-defined | 🔧 User-defined | 🔧 User-defined | 🔧 User-defined | Custom configurations |

## Important Outputs

```ruby
# Security group information
web_sg.security_group_id          # Security group ID
web_sg.security_group_arn         # Security group ARN  
web_sg.security_group_name        # Security group name

# Security analysis
web_sg.security_risk_level        # Risk level: low/medium/high
web_sg.security_recommendations   # Array of security recommendations
web_sg.compliance_profile         # Compliance feature analysis

# Port configuration
web_sg.enabled_ports              # All enabled ports
web_sg.web_ports                  # Web-specific ports (80, 443, etc.)
web_sg.admin_ports                # Administrative ports (22, 3389, etc.)

# Access configuration
web_sg.http_enabled               # HTTP enabled status
web_sg.https_enabled              # HTTPS enabled status
web_sg.ssh_enabled                # SSH enabled status
web_sg.internet_accessible       # Internet accessibility status

# Rule information
web_sg.inbound_rules_summary      # Detailed inbound rules
web_sg.outbound_rules_summary     # Detailed outbound rules
web_sg.ingress_rule_count         # Number of ingress rules
web_sg.egress_rule_count          # Number of egress rules
```

## Security Risk Assessment

The component automatically evaluates security risks:

### 🟢 Low Risk
- HTTPS enabled  
- SSH restricted to internal networks
- No unnecessary open ports
- Controlled outbound access

### 🟡 Medium Risk  
- HTTP enabled alongside HTTPS
- SSH with some restrictions
- Ping enabled
- Wide access patterns

### 🔴 High Risk
- SSH open to internet (0.0.0.0/0)
- HTTP only, no HTTPS
- Multiple risk factors
- Wide-open access from anywhere

### Example Security Check
```ruby
web_sg = web_security_group(:example, {
  enable_ssh: true,
  ssh_cidr_blocks: ["0.0.0.0/0"],  # ⚠️ High risk
  enable_https: false              # ⚠️ High risk  
})

puts web_sg.security_risk_level
# Output: "high"

puts web_sg.security_recommendations
# Output: [
#   "Restrict SSH access to specific IP ranges or use a bastion host",
#   "Enable HTTPS and consider redirecting HTTP to HTTPS"
# ]
```

## Integration Patterns

### Multi-Tier Application
```ruby
# Public load balancer
public_lb_sg = web_security_group(:public_lb, {
  vpc_ref: vpc,
  allowed_cidr_blocks: ["0.0.0.0/0"],
  enable_ssh: false
})

# Application servers (internal only)
app_sg = web_security_group(:app_servers, {
  vpc_ref: vpc,
  allowed_cidr_blocks: [public_lb_sg.security_group_id],  # Only from LB
  enable_ssh: true,
  ssh_cidr_blocks: ["10.0.0.0/16"]                       # Internal SSH
})
```

### With Auto Scaling Group
```ruby
# Create security group
web_sg = web_security_group(:web_servers, {
  vpc_ref: vpc,
  enable_https: true,
  enable_ssh: true,
  ssh_cidr_blocks: ["10.0.0.0/8"]
})

# Use in Auto Scaling Group
asg = aws_autoscaling_group(:web_servers, {
  vpc_zone_identifier: subnet_ids,
  security_groups: [web_sg.security_group_id],
  min_size: 2,
  max_size: 10
})
```

### With Load Balancer
```ruby
# Load balancer security group
lb_sg = web_security_group(:lb, {
  vpc_ref: vpc,
  allowed_cidr_blocks: ["0.0.0.0/0"],
  enable_ssh: false
})

# Create load balancer
alb = aws_lb(:web_lb, {
  security_groups: [lb_sg.security_group_id],
  subnet_ids: public_subnet_ids
})
```

## Common Access Patterns

### Internet-Facing Web Server
```ruby
web_sg = web_security_group(:public_web, {
  vpc_ref: vpc,
  allowed_cidr_blocks: ["0.0.0.0/0"],  # Internet access
  enable_ssh: true,
  ssh_cidr_blocks: ["203.0.113.0/24"]  # Office IP only
})
```

### Internal Web Application  
```ruby
internal_sg = web_security_group(:internal_app, {
  vpc_ref: vpc,
  allowed_cidr_blocks: ["10.0.0.0/8"],     # Internal network only
  enable_outbound_internet: false,         # No internet access
  enable_vpc_communication: true           # VPC access only
})
```

### Bastion Host Pattern
```ruby
bastion_sg = web_security_group(:bastion, {
  vpc_ref: vpc,
  enable_http: false,                    # No web protocols
  enable_https: false,
  enable_ssh: true,                      # SSH only
  ssh_cidr_blocks: ["203.0.113.0/24"],  # Office IP
  custom_ports: []                       # No custom ports
})
```

## Port Analysis

```ruby
# Check port usage
analysis = web_sg.port_usage_analysis

puts "Web ports: #{analysis[:web_ports]} ports enabled"
puts "Admin ports: #{analysis[:admin_ports]} ports enabled"  
puts "Total ports: #{analysis[:total_ports]} ports"
puts "Has SSL: #{analysis[:has_ssl]}"
puts "Has admin access: #{analysis[:has_admin_access]}"
puts "Internet accessible: #{analysis[:internet_accessible]}"
```

## Best Practices

### Security Best Practices
1. **Enable HTTPS** - Always use HTTPS in production, consider disabling HTTP
2. **Restrict SSH** - Use bastion hosts or specific IP ranges, never 0.0.0.0/0
3. **Least privilege** - Only open ports that are absolutely necessary
4. **Layer security** - Use separate security groups for different tiers
5. **Regular reviews** - Use built-in risk assessment for security audits

### Configuration Best Practices
1. **Use descriptive names** - Clear security group names and descriptions
2. **Tag comprehensively** - Include Environment, SecurityLevel, Purpose tags
3. **Document custom ports** - Clearly document what custom ports are for
4. **Monitor changes** - Track security group modifications for compliance
5. **Test configurations** - Validate security groups in development first

## Error Examples

```ruby
# ❌ Port conflict
web_security_group(:bad, {
  enable_http: true,
  http_port: 80,
  custom_ports: [80, 8080]  # 80 conflicts with HTTP
})

# ✅ No conflict
web_security_group(:good, {
  enable_http: true,
  http_port: 80,  
  custom_ports: [8080, 9000]  # Different ports
})

# ❌ No protocols enabled
web_security_group(:bad, {
  enable_http: false,
  enable_https: false,
  custom_ports: []  # Nothing enabled
})

# ✅ At least one protocol
web_security_group(:good, {
  enable_https: true  # HTTPS enabled
})

# ❌ Invalid CIDR
web_security_group(:bad, {
  allowed_cidr_blocks: ["10.0.0.0/33"]  # Invalid mask
})

# ✅ Valid CIDR  
web_security_group(:good, {
  allowed_cidr_blocks: ["10.0.0.0/24"]  # Valid mask
})
```

## Security Recommendations Examples

Based on your configuration, the component provides specific recommendations:

```ruby
# High-risk configuration
risky_sg = web_security_group(:risky, {
  enable_ssh: true,
  ssh_cidr_blocks: ["0.0.0.0/0"],    # ⚠️ SSH from anywhere
  enable_http: true,                  # ⚠️ Unencrypted HTTP
  enable_https: false                 # ⚠️ No HTTPS
})

puts risky_sg.security_recommendations
# Output:
# [
#   "Restrict SSH access to specific IP ranges or use a bastion host",
#   "Enable HTTPS and consider redirecting HTTP to HTTPS"
# ]
```

## Resource Access

```ruby
# Access the underlying security group resource  
sg_resource = web_sg.resources[:security_group]

# Get specific attributes
sg_id = web_sg.security_group_id
sg_arn = web_sg.security_group_arn
sg_name = web_sg.security_group_name

# Use in other resources
web_instance = aws_instance(:web, {
  vpc_security_group_ids: [web_sg.security_group_id]
})
```

See [CLAUDE.md](./CLAUDE.md) for complete documentation and advanced configuration options.