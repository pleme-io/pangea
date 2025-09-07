# Secure VPC Component

## Overview

The `secure_vpc` component creates an AWS VPC with enhanced security monitoring and best-practice defaults. It serves as the foundation for secure, compliant network architectures by providing DNS resolution, CloudWatch monitoring, and preparation for VPC Flow Logs.

## Purpose

This component addresses the common need for VPCs that meet security and compliance requirements out of the box. Rather than manually configuring security features for each VPC, the component provides a standardized, secure VPC configuration with monitoring and compliance features built-in.

## Features

### Core VPC Configuration
- **DNS Resolution**: Enables both DNS hostnames and DNS support for proper name resolution
- **Private CIDR Validation**: Ensures CIDR blocks follow RFC 1918 private addressing standards
- **Instance Tenancy Control**: Configurable instance tenancy with secure defaults
- **Security-First Defaults**: All security features enabled by default

### Enhanced Monitoring
- **CloudWatch Log Group**: Creates dedicated log group for VPC monitoring and flow logs
- **Configurable Retention**: Log retention policies from 1 day to 10 years
- **Compliance Tracking**: Automatic tagging for compliance and security auditing
- **Security Level Assessment**: Automatic evaluation of security posture

### Future-Ready Security
- **Flow Logs Preparation**: Infrastructure ready for VPC Flow Logs when resource is implemented
- **Multi-Destination Support**: Supports both CloudWatch Logs and S3 destinations
- **Encryption Support**: Configuration for encryption at rest and in transit

## Usage

### Basic Secure VPC

```ruby
template :secure_infrastructure do
  include Pangea::Resources::AWS
  include Pangea::Components::SecureVpc
  
  # Create a secure VPC with default security features
  network = secure_vpc(:main, {
    cidr_block: "10.0.0.0/16",
    availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"]
  })
  
  # Access VPC resources
  output :vpc_id do
    value network.vpc_id
  end
  
  output :security_features do
    value network.compliance_features
    description "Enabled security and compliance features"
  end
end
```

### Production VPC with Enhanced Security

```ruby
# High-security production VPC
production_vpc = secure_vpc(:production, {
  cidr_block: "10.0.0.0/16",
  availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
  enable_flow_logs: true,
  flow_log_destination: "cloud-watch-logs",
  instance_tenancy: "dedicated",
  
  security_config: {
    enable_flow_logs: true,
    flow_log_destination: "cloud-watch-logs",
    restrict_default_sg: true,
    encryption_at_rest: true,
    encryption_in_transit: true
  },
  
  monitoring_config: {
    enable_cloudwatch: true,
    enable_detailed_monitoring: true,
    create_alarms: true,
    log_retention_days: 90
  },
  
  tags: {
    Environment: "production",
    SecurityLevel: "high",
    Compliance: "required",
    DataClassification: "confidential"
  }
})
```

### Development VPC with Cost Optimization

```ruby
# Cost-optimized development VPC
dev_vpc = secure_vpc(:development, {
  cidr_block: "10.1.0.0/16",
  availability_zones: ["us-east-1a", "us-east-1b"],
  instance_tenancy: "default",
  
  security_config: {
    enable_flow_logs: false,  # Reduce costs in dev
    encryption_at_rest: true
  },
  
  monitoring_config: {
    enable_cloudwatch: true,
    enable_detailed_monitoring: false,
    log_retention_days: 7
  },
  
  tags: {
    Environment: "development",
    AutoShutdown: "true",
    CostCenter: "engineering"
  }
})
```

## Attributes

### Required Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `cidr_block` | String | VPC CIDR block (must be valid CIDR, /16 to /28) |
| `availability_zones` | Array[String] | List of availability zones for the VPC (1-6 zones) |

### Optional Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `enable_dns_hostnames` | Boolean | `true` | Enable DNS hostname resolution |
| `enable_dns_support` | Boolean | `true` | Enable DNS support |
| `enable_flow_logs` | Boolean | `true` | Enable VPC Flow Logs (preparation for future implementation) |
| `flow_log_destination` | String | `'cloud-watch-logs'` | Flow log destination: `'cloud-watch-logs'` or `'s3'` |
| `instance_tenancy` | String | `'default'` | Instance tenancy: `'default'`, `'dedicated'`, or `'host'` |
| `tags` | Hash | `{}` | Additional tags for the VPC |
| `security_config` | Hash | See below | Security configuration options |
| `monitoring_config` | Hash | See below | Monitoring and logging configuration |

### Security Configuration

```ruby
security_config: {
  enable_flow_logs: true,           # Enable flow logs (Boolean)
  flow_log_destination: 'cloud-watch-logs',  # Destination type (String)
  restrict_default_sg: true,        # Restrict default security group (Boolean)
  enable_nacl_logging: false,       # Enable NACL logging (Boolean) 
  encryption_at_rest: true,         # Enable encryption at rest (Boolean)
  encryption_in_transit: true       # Enable encryption in transit (Boolean)
}
```

### Monitoring Configuration

```ruby
monitoring_config: {
  enable_cloudwatch: true,          # Enable CloudWatch monitoring (Boolean)
  enable_detailed_monitoring: false, # Enable detailed monitoring (Boolean)
  create_alarms: true,              # Create CloudWatch alarms (Boolean)
  log_retention_days: 30,           # Log retention period in days (Integer, 1-3653)
  enable_xray: false                # Enable X-Ray tracing (Boolean)
}
```

## Resources Created

### Primary Resources

1. **aws_vpc**: The main VPC resource with security-enhanced configuration
   - DNS resolution enabled by default
   - Compliance and security tags
   - Configurable instance tenancy

2. **aws_cloudwatch_log_group**: Dedicated log group for VPC monitoring
   - Configurable retention policies
   - Structured naming convention
   - Ready for flow logs integration

### Future Resources (When Implemented)

1. **aws_flow_log**: VPC Flow Logs for network traffic monitoring
   - All traffic types captured
   - Multiple destination support
   - Automatic log group integration

## Outputs

### VPC Information
- `vpc_id`: VPC identifier
- `vpc_arn`: VPC ARN
- `vpc_cidr_block`: VPC CIDR block
- `default_security_group_id`: Default security group ID
- `default_route_table_id`: Default route table ID
- `default_network_acl_id`: Default network ACL ID
- `main_route_table_id`: Main route table ID

### Security and Compliance
- `is_private_cidr`: Whether CIDR block is RFC 1918 private
- `security_level`: Assessed security level (`'basic'`, `'enhanced'`, `'maximum'`)
- `compliance_features`: Array of enabled compliance features
- `estimated_subnet_capacity`: Estimated number of /24 subnets that can fit

### Geographic Information
- `region`: AWS region derived from availability zones
- `availability_zones`: List of configured availability zones

### Monitoring Information
- `log_group_name`: CloudWatch log group name
- `log_group_arn`: CloudWatch log group ARN
- `monitoring_enabled`: Whether CloudWatch monitoring is enabled

## Component Reference Usage

```ruby
# Access VPC resource directly
vpc_resource = network.vpc
subnet_vpc_id = vpc_resource.id

# Access computed outputs
region = network.region
security_level = network.security_level
compliance_features = network.compliance_features

# Check if monitoring is enabled
if network.monitoring_enabled
  puts "CloudWatch monitoring is active"
  puts "Log group: #{network.log_group_name}"
end

# Use VPC ID in other resources
web_subnet = aws_subnet(:web, {
  vpc_id: network.vpc_id,
  cidr_block: "10.0.1.0/24",
  availability_zone: network.availability_zones.first
})
```

## Validation and Constraints

### CIDR Block Validation
- Must be valid CIDR notation
- Prefix must be between /16 and /28
- Automatically validates RFC 1918 compliance
- Estimates subnet capacity

### Availability Zone Validation
- All zones must be from the same region
- Supports 1-6 availability zones
- Validates zone format and existence

### Configuration Validation
- S3 flow log destination requires flow logs enabled
- Detailed monitoring requires CloudWatch enabled
- Log retention must be 1-3653 days

## Security Features

### Current Implementation
- **DNS Resolution**: Proper hostname resolution for instances
- **Private CIDR Validation**: Ensures use of private address space
- **Security Tagging**: Automatic compliance and security tags
- **CloudWatch Integration**: Monitoring and log aggregation

### Future Implementation (Pending aws_flow_log)
- **VPC Flow Logs**: Complete network traffic logging
- **Multi-Destination Support**: CloudWatch Logs and S3 destinations
- **Traffic Analysis**: All, accept, or reject traffic filtering
- **Security Monitoring**: Integration with security tools

## Best Practices

### Security
1. **Always use private CIDR blocks** for internal networks
2. **Enable flow logs in production** environments
3. **Use dedicated tenancy** for compliance-sensitive workloads
4. **Apply comprehensive tagging** for compliance tracking

### Cost Optimization
1. **Adjust log retention** based on compliance requirements
2. **Disable detailed monitoring** in development environments
3. **Use default tenancy** unless compliance requires dedicated
4. **Consider S3 destinations** for long-term log storage

### Operational Excellence
1. **Include environment tags** for resource management
2. **Enable CloudWatch monitoring** for operational visibility
3. **Plan subnet allocation** using estimated capacity
4. **Document security configurations** for compliance audits

## Integration with Other Components

The secure_vpc component is designed to work seamlessly with other networking components:

```ruby
# Create secure VPC
network = secure_vpc(:main, {
  cidr_block: "10.0.0.0/16",
  availability_zones: ["us-east-1a", "us-east-1b"]
})

# Add public/private subnets
subnets = public_private_subnets(:web_tier, {
  vpc_ref: network.vpc,
  public_cidrs: ["10.0.1.0/24", "10.0.2.0/24"],
  private_cidrs: ["10.0.10.0/24", "10.0.20.0/24"]
})

# Add web security group
web_sg = web_security_group(:web_servers, {
  vpc_ref: network.vpc,
  description: "Security group for web servers"
})
```

## Error Handling

The component provides comprehensive error handling and validation:

- **CIDR Validation**: Clear errors for invalid CIDR blocks
- **Zone Validation**: Errors for mixed regions or invalid zones
- **Configuration Validation**: Errors for incompatible option combinations
- **Resource Creation**: Proper error propagation from underlying resources

## Testing

```ruby
RSpec.describe Pangea::Components::SecureVpc do
  describe "#secure_vpc" do
    it "creates VPC with security enhancements" do
      vpc = secure_vpc(:test, {
        cidr_block: "10.0.0.0/16",
        availability_zones: ["us-east-1a", "us-east-1b"]
      })
      
      expect(vpc).to be_a(ComponentReference)
      expect(vpc.type).to eq('secure_vpc')
      expect(vpc.resources[:vpc]).to be_present
      expect(vpc.resources[:log_group]).to be_present
      expect(vpc.security_level).to eq('enhanced')
      expect(vpc.is_private_cidr).to be true
    end
    
    it "validates CIDR block constraints" do
      expect {
        secure_vpc(:test, {
          cidr_block: "10.0.0.0/29",  # Too small
          availability_zones: ["us-east-1a"]
        })
      }.to raise_error(Dry::Struct::Error, /too small/)
    end
    
    it "validates availability zone regions" do
      expect {
        secure_vpc(:test, {
          cidr_block: "10.0.0.0/16",
          availability_zones: ["us-east-1a", "us-west-2a"]  # Different regions
        })
      }.to raise_error(Dry::Struct::Error, /same region/)
    end
  end
end
```

This secure VPC component provides a robust foundation for secure AWS networking with comprehensive monitoring, validation, and future-ready architecture for enhanced security features.