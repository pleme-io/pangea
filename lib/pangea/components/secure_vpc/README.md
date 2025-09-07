# Secure VPC Component

A production-ready AWS VPC component with enhanced security monitoring and compliance features.

## Quick Start

```ruby
# Include the component in your template
include Pangea::Components::SecureVpc

# Create a secure VPC
network = secure_vpc(:main, {
  cidr_block: "10.0.0.0/16",
  availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"]
})

# Use the VPC in other resources
web_subnet = aws_subnet(:web, {
  vpc_id: network.vpc_id,
  cidr_block: "10.0.1.0/24"
})
```

## Key Features

- ✅ **DNS Resolution Enabled** - Proper hostname resolution for instances
- ✅ **CloudWatch Monitoring** - Dedicated log group for VPC monitoring
- ✅ **Security Validation** - RFC 1918 private CIDR validation
- ✅ **Compliance Ready** - Automatic security and compliance tagging
- 🔄 **Flow Logs Ready** - Infrastructure prepared for VPC Flow Logs (pending implementation)

## Basic Usage

### Production VPC
```ruby
production_vpc = secure_vpc(:production, {
  cidr_block: "10.0.0.0/16",
  availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
  instance_tenancy: "dedicated",
  
  security_config: {
    enable_flow_logs: true,
    encryption_at_rest: true
  },
  
  monitoring_config: {
    log_retention_days: 90,
    enable_detailed_monitoring: true
  },
  
  tags: {
    Environment: "production",
    SecurityLevel: "high"
  }
})
```

### Development VPC
```ruby
dev_vpc = secure_vpc(:development, {
  cidr_block: "10.1.0.0/16",
  availability_zones: ["us-east-1a", "us-east-1b"],
  
  monitoring_config: {
    log_retention_days: 7,
    enable_detailed_monitoring: false
  },
  
  tags: {
    Environment: "development",
    AutoShutdown: "true"
  }
})
```

## Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `cidr_block` | String | VPC CIDR block (/16 to /28) |
| `availability_zones` | Array[String] | List of AZs (1-6 zones) |

## Important Outputs

```ruby
# VPC identifiers
network.vpc_id                    # VPC ID for subnet creation
network.vpc_arn                   # VPC ARN
network.default_security_group_id # Default security group ID

# Security information
network.is_private_cidr           # true if RFC 1918 private
network.security_level            # 'basic', 'enhanced', or 'maximum'
network.compliance_features       # Array of enabled features

# Geographic info
network.region                    # AWS region
network.availability_zones        # List of AZs
network.estimated_subnet_capacity # Estimated /24 subnets that fit
```

## Integration with Other Components

```ruby
# Create secure VPC foundation
network = secure_vpc(:main, {
  cidr_block: "10.0.0.0/16",
  availability_zones: ["us-east-1a", "us-east-1b"]
})

# Add subnet components
subnets = public_private_subnets(:web_tier, {
  vpc_ref: network.vpc,
  public_cidrs: ["10.0.1.0/24", "10.0.2.0/24"]
})

# Add security group components  
web_sg = web_security_group(:web_servers, {
  vpc_ref: network.vpc
})
```

## Configuration Options

### Security Configuration
```ruby
security_config: {
  enable_flow_logs: true,           # Prepare for flow logs
  flow_log_destination: 'cloud-watch-logs',  # or 's3'
  encryption_at_rest: true,         # Enable encryption
  encryption_in_transit: true       # Enable transit encryption
}
```

### Monitoring Configuration
```ruby
monitoring_config: {
  enable_cloudwatch: true,          # Enable monitoring
  log_retention_days: 30,           # 1-3653 days
  enable_detailed_monitoring: false, # Detailed metrics
  create_alarms: true               # Create alarms
}
```

## Validation

- ✅ CIDR blocks must be /16 to /28
- ✅ All availability zones must be from same region  
- ✅ Validates RFC 1918 private address space
- ✅ Compatible configuration options

## Best Practices

1. **Use private CIDR blocks** (10.x.x.x, 172.16-31.x.x, 192.168.x.x)
2. **Enable monitoring** in production environments
3. **Plan subnet allocation** using `estimated_subnet_capacity`
4. **Tag resources** for compliance and cost tracking
5. **Use dedicated tenancy** for compliance-sensitive workloads

## Future Enhancements

When `aws_flow_log` resource is implemented, this component will automatically:
- Enable VPC Flow Logs for network traffic monitoring  
- Support both CloudWatch Logs and S3 destinations
- Provide complete network security visibility

## Error Handling

Common errors and solutions:

```ruby
# Error: CIDR too small
secure_vpc(:test, { cidr_block: "10.0.0.0/29" })
# Solution: Use /16 to /28 (e.g., "10.0.0.0/24")

# Error: Mixed regions  
secure_vpc(:test, { 
  availability_zones: ["us-east-1a", "us-west-2a"] 
})
# Solution: Use zones from same region

# Error: Invalid CIDR
secure_vpc(:test, { cidr_block: "300.0.0.0/16" })
# Solution: Use valid IP address format
```

See [CLAUDE.md](./CLAUDE.md) for complete documentation and advanced usage patterns.