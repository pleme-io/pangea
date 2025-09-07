# Public Private Subnets Component

Complete two-tier network architecture with public subnets, private subnets, NAT Gateways, and all routing infrastructure.

## Quick Start

```ruby
# Include the component
include Pangea::Components::PublicPrivateSubnets

# Create public-private subnet architecture
subnets = public_private_subnets(:web_tier, {
  vpc_ref: vpc,
  public_cidrs: ["10.0.1.0/24", "10.0.2.0/24"],
  private_cidrs: ["10.0.10.0/24", "10.0.20.0/24"],
  availability_zones: ["us-east-1a", "us-east-1b"]
})

# Use in other resources
load_balancer = aws_lb(:web_lb, {
  subnet_ids: subnets.public_subnet_ids
})
```

## What It Creates

- ✅ **Public Subnets** - Internet-accessible subnets with public IPs
- ✅ **Private Subnets** - Isolated subnets for internal resources  
- ✅ **Internet Gateway** - Direct internet access for public subnets
- ✅ **NAT Gateway(s)** - Outbound internet access for private subnets
- ✅ **Route Tables** - Automatic routing configuration
- ✅ **Elastic IPs** - Static IPs for NAT Gateways

## Architecture Patterns

### Production High Availability
```ruby
production_subnets = public_private_subnets(:production, {
  vpc_ref: vpc,
  public_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"],
  private_cidrs: ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"],
  availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
  
  nat_gateway_type: "per_az",  # NAT Gateway per AZ for redundancy
  
  high_availability: {
    multi_az: true,
    min_availability_zones: 3,
    distribute_evenly: true
  },
  
  tags: {
    Environment: "production",
    HighAvailability: "true"
  }
})

# Estimated cost: $135-180/month (3 NAT Gateways)
```

### Cost-Optimized Development  
```ruby
dev_subnets = public_private_subnets(:development, {
  vpc_ref: vpc,
  public_cidrs: ["10.1.1.0/24", "10.1.2.0/24"],
  private_cidrs: ["10.1.10.0/24", "10.1.20.0/24"],
  
  nat_gateway_type: "single",  # Single NAT Gateway to reduce costs
  
  tags: {
    Environment: "development",
    CostOptimized: "true"
  }
})

# Estimated cost: $45-60/month (1 NAT Gateway)
```

## Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `vpc_ref` | ResourceReference/String | VPC to create subnets in |
| `public_cidrs` | Array[String] | CIDR blocks for public subnets |
| `private_cidrs` | Array[String] | CIDR blocks for private subnets |

## Key Configuration Options

### NAT Gateway Strategy
```ruby
# Single NAT Gateway (cost-effective)
nat_gateway_type: "single"          # ~$45/month

# Per-AZ NAT Gateways (high availability)  
nat_gateway_type: "per_az"          # ~$45/month × AZ count
```

### High Availability Options
```ruby
high_availability: {
  multi_az: true,                   # Distribute across multiple AZs
  min_availability_zones: 2,        # Minimum AZ count (1-6)
  distribute_evenly: true           # Even subnet distribution
}
```

### Tagging Strategy
```ruby
# Global tags for all resources
tags: {
  Environment: "production",
  Project: "web-app"
}

# Public subnet specific tags
public_subnet_tags: {
  Tier: "web",
  Internet: "accessible"
}

# Private subnet specific tags  
private_subnet_tags: {
  Tier: "application", 
  Internet: "nat_only"
}
```

## Important Outputs

```ruby
# Subnet identifiers for other resources
subnets.public_subnet_ids         # Array of public subnet IDs
subnets.private_subnet_ids        # Array of private subnet IDs

# Network infrastructure
subnets.internet_gateway_id       # Internet Gateway ID
subnets.nat_gateway_ids           # Array of NAT Gateway IDs
subnets.nat_eip_ips              # Array of NAT Gateway public IPs

# Routing information
subnets.public_route_table_id     # Public route table ID
subnets.private_route_table_ids   # Array of private route table IDs

# Configuration summary
subnets.subnet_pairs_count        # Number of public-private pairs
subnets.nat_gateway_count         # Number of NAT Gateways
subnets.availability_zones        # AZs used
subnets.estimated_monthly_nat_cost # Monthly NAT Gateway cost estimate
```

## Common Usage Patterns

### Web Application Architecture
```ruby
# Create network foundation
subnets = public_private_subnets(:web_app, {
  vpc_ref: vpc,
  public_cidrs: ["10.0.1.0/24", "10.0.2.0/24"], 
  private_cidrs: ["10.0.10.0/24", "10.0.20.0/24"]
})

# Load balancer in public subnets
alb = aws_lb(:web_lb, {
  subnet_ids: subnets.public_subnet_ids,
  scheme: "internet-facing"
})

# App servers in private subnets  
app_servers = aws_autoscaling_group(:app_servers, {
  vpc_zone_identifier: subnets.private_subnet_ids
})
```

### Database Integration
```ruby
# Use private subnets for database subnet group
db_subnet_group = aws_db_subnet_group(:database, {
  subnet_ids: subnets.private_subnet_ids,
  tags: { Tier: "database" }
})

# RDS instance in private subnets
database = aws_db_instance(:main_db, {
  db_subnet_group_name: db_subnet_group.name
})
```

### Integration with Secure VPC
```ruby
# Create secure VPC foundation
network = secure_vpc(:main, {
  cidr_block: "10.0.0.0/16",
  availability_zones: ["us-east-1a", "us-east-1b"]
})

# Add public-private subnet architecture
subnets = public_private_subnets(:web_tier, {
  vpc_ref: network.vpc,  # Use secure VPC
  public_cidrs: ["10.0.1.0/24", "10.0.2.0/24"],
  private_cidrs: ["10.0.10.0/24", "10.0.20.0/24"],
  availability_zones: network.availability_zones  # Use same AZs
})
```

## Validation Rules

- ✅ Public and private CIDR blocks must not overlap
- ✅ All availability zones must be from same region
- ✅ High availability mode requires sufficient AZ count
- ✅ Even distribution requires subnet count divisible by AZ count
- ✅ Per-AZ NAT Gateway requires at least one private subnet per AZ

## Cost Comparison

| Configuration | AZs | NAT Gateways | Monthly Cost* |
|---------------|-----|--------------|---------------|
| Single AZ | 1 | 1 | $45-60 |
| 2 AZ (single NAT) | 2 | 1 | $45-60 |
| 2 AZ (per-AZ NAT) | 2 | 2 | $90-120 |
| 3 AZ (per-AZ NAT) | 3 | 3 | $135-180 |

*Estimates include NAT Gateway hours + moderate data processing*

## Best Practices

1. **Use per-AZ NAT Gateways** for production high availability
2. **Plan CIDR blocks** to avoid overlaps and allow future growth
3. **Tag comprehensively** for cost allocation and management
4. **Monitor NAT Gateway costs** and data processing charges
5. **Consider VPC endpoints** for AWS services to reduce NAT usage

## Error Examples

```ruby
# ❌ Overlapping CIDR blocks
public_private_subnets(:bad, {
  public_cidrs: ["10.0.1.0/24"],
  private_cidrs: ["10.0.1.0/24"]  # Same CIDR
})

# ✅ Non-overlapping CIDR blocks  
public_private_subnets(:good, {
  public_cidrs: ["10.0.1.0/24"],
  private_cidrs: ["10.0.2.0/24"]  # Different CIDR
})

# ❌ Uneven distribution
public_private_subnets(:bad, {
  public_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"],  # 3 subnets
  availability_zones: ["us-east-1a", "us-east-1b"],  # 2 AZs
  high_availability: { distribute_evenly: true }  # 3 ÷ 2 not even
})

# ✅ Even distribution
public_private_subnets(:good, {
  public_cidrs: ["10.0.1.0/24", "10.0.2.0/24"],  # 2 subnets  
  availability_zones: ["us-east-1a", "us-east-1b"],  # 2 AZs
  high_availability: { distribute_evenly: true }  # 2 ÷ 2 = 1 per AZ
})
```

## Resource Access

```ruby
# Access subnet collections
public_subnets = subnets.resources[:public_subnets]  # Hash of public subnets
private_subnets = subnets.resources[:private_subnets]  # Hash of private subnets

# Access specific resources
internet_gateway = subnets.resources[:internet_gateway]
nat_gateways = subnets.resources[:nat_gateways]  # Hash of NAT Gateways
elastic_ips = subnets.resources[:nat_eips]  # Hash of Elastic IPs

# Access first subnet in each tier
first_public = subnets.resources[:public_subnets][:public_1]
first_private = subnets.resources[:private_subnets][:private_1]
```

## Security Profile

The component automatically assesses security based on enabled features:

- **Basic**: Public and private subnets with basic NAT
- **Enhanced**: Multi-AZ with per-AZ NAT Gateways + monitoring  
- **Maximum**: All security features + high availability + monitoring

Check your deployment's security profile:
```ruby
puts "Security profile: #{subnets.security_profile}"
puts "HA level: #{subnets.high_availability_level}"
```

See [CLAUDE.md](./CLAUDE.md) for complete documentation and advanced configuration options.