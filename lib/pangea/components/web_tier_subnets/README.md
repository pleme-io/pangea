# Web Tier Subnets Component

Public subnets optimized for web tier workloads with Internet Gateway routing and high availability distribution.

## Quick Start

```ruby
# Include the component
include Pangea::Components::WebTierSubnets

# Create web tier subnets  
web_subnets = web_tier_subnets(:web_tier, {
  vpc_ref: vpc,
  subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"],
  availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"]
})

# Deploy load balancer
load_balancer = aws_lb(:web_lb, {
  subnet_ids: web_subnets.subnet_ids,
  scheme: "internet-facing"
})
```

## What It Creates

- ✅ **Public Subnets** - Internet-accessible subnets with public IPs
- ✅ **Internet Gateway** - Direct internet access for web workloads  
- ✅ **Route Table** - Optimized routing for web traffic
- ✅ **AZ Distribution** - Automatic distribution across availability zones
- ✅ **Capacity Planning** - Built-in capacity estimation per subnet/AZ

## Key Features

- 🌐 **Load Balancer Ready** - Pre-configured for ALB/NLB deployment
- 🏗️ **High Availability** - Multi-AZ distribution with even allocation
- 📊 **Capacity Planning** - Automatic instance capacity estimation
- 🔧 **Web Optimized** - Configuration optimized for web workloads
- 📋 **Compliance Ready** - Comprehensive tagging and monitoring support

## Common Usage Patterns

### Production High Availability
```ruby
production_web = web_tier_subnets(:production, {
  vpc_ref: vpc,
  subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"],
  availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
  
  high_availability: {
    multi_az: true,
    min_availability_zones: 3,
    distribute_evenly: true
  },
  
  load_balancing: {
    type: "application",
    scheme: "internet-facing",
    enable_deletion_protection: true
  },
  
  tags: {
    Environment: "production",
    HighAvailability: "true"
  }
})

# Perfect 1:1 subnet-to-AZ distribution
# Total capacity: ~750 instances across 3 AZs
```

### Development Environment
```ruby
dev_web = web_tier_subnets(:development, {
  vpc_ref: vpc,
  subnet_cidrs: ["10.1.1.0/24", "10.1.2.0/24"],
  availability_zones: ["us-east-1a", "us-east-1b"],
  
  tags: {
    Environment: "development",
    CostOptimized: "true",
    AutoShutdown: "enabled"
  }
})
```

### Load Balancer Only (No Instance Public IPs)
```ruby
lb_only_web = web_tier_subnets(:lb_only, {
  vpc_ref: vpc,
  subnet_cidrs: ["10.0.10.0/24", "10.0.20.0/24"],
  availability_zones: ["us-east-1a", "us-east-1b"],
  
  # Instances won't get public IPs - only load balancer needs internet access
  enable_public_ips: false,
  
  load_balancing: {
    type: "application",
    scheme: "internet-facing"
  }
})
```

## Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `vpc_ref` | ResourceReference/String | VPC to create subnets in |
| `subnet_cidrs` | Array[String] | CIDR blocks for web subnets |
| `availability_zones` | Array[String] | AZs for subnet distribution |

## Key Configuration Options

### High Availability
```ruby
high_availability: {
  multi_az: true,                   # Distribute across AZs
  min_availability_zones: 2,        # Minimum AZ count
  distribute_evenly: true           # Even distribution across AZs
}
```

### Load Balancing Integration
```ruby
load_balancing: {
  type: "application",              # ALB, NLB, or gateway
  scheme: "internet-facing",        # Internet-facing or internal  
  enable_deletion_protection: false, # Protect from deletion
  enable_cross_zone: true          # Cross-zone load balancing
}
```

### Public IP Configuration
```ruby
enable_public_ips: true             # Auto-assign public IPs to instances
create_internet_gateway: true       # Create Internet Gateway
enable_ipv6: false                 # IPv6 support (future feature)
```

## Important Outputs

```ruby
# Subnet identifiers
web_subnets.subnet_ids            # Array of subnet IDs for load balancers
web_subnets.subnet_count          # Number of subnets created

# Network infrastructure  
web_subnets.internet_gateway_id   # Internet Gateway ID
web_subnets.route_table_id        # Route table ID
web_subnets.vpc_id                # VPC ID

# Capacity planning
web_subnets.total_estimated_capacity        # Total instance capacity
web_subnets.estimated_capacity_per_subnet   # Per-subnet capacity array

# High availability info
web_subnets.availability_zones     # AZs used
web_subnets.is_highly_available    # HA status
web_subnets.distribution_pattern   # Distribution strategy
web_subnets.az_distribution        # Per-AZ subnet distribution

# Configuration
web_subnets.load_balancer_ready    # Ready for load balancer deployment
web_subnets.web_tier_profile       # Profile level (basic/standard/advanced)
```

## Distribution Patterns

### One Per AZ (Recommended)
```ruby
# Perfect 1:1 subnet to AZ ratio
subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24"]        # 2 subnets
availability_zones: ["us-east-1a", "us-east-1b"]     # 2 AZs
# Result: distribution_pattern = "one_per_az"
```

### Even Distribution
```ruby  
# Evenly divisible subnets across AZs
subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]  # 4 subnets
availability_zones: ["us-east-1a", "us-east-1b"]     # 2 AZs
# Result: 2 subnets per AZ, distribution_pattern = "even_distribution"
```

## Common Integration Patterns

### With Application Load Balancer
```ruby
# Create web subnets
web_subnets = web_tier_subnets(:web, {
  vpc_ref: vpc,
  subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24"],
  availability_zones: ["us-east-1a", "us-east-1b"]
})

# Deploy ALB in web subnets
alb = aws_lb(:web_lb, {
  subnet_ids: web_subnets.subnet_ids,
  load_balancer_type: "application",
  scheme: "internet-facing"
})

# Create target group
targets = aws_lb_target_group(:web_targets, {
  vpc_id: web_subnets.vpc_id,
  port: 80,
  protocol: "HTTP"
})
```

### With Auto Scaling Group  
```ruby
# Deploy ASG across web subnets
web_asg = aws_autoscaling_group(:web_servers, {
  vpc_zone_identifier: web_subnets.subnet_ids,
  min_size: 2,
  max_size: 10,
  target_group_arns: [target_group.arn]
})
```

### With Secure VPC
```ruby
# Create secure VPC foundation
network = secure_vpc(:main, {
  cidr_block: "10.0.0.0/16",
  availability_zones: ["us-east-1a", "us-east-1b"]
})

# Add web tier subnets
web_subnets = web_tier_subnets(:web, {
  vpc_ref: network.vpc,             # Use secure VPC
  subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24"],
  availability_zones: network.availability_zones  # Same AZs
})
```

### Bastion Host Deployment
```ruby
# Deploy bastion in first web subnet
bastion = aws_instance(:bastion, {
  subnet_id: web_subnets.subnet_ids.first,
  ami: "ami-12345678",
  instance_type: "t3.micro",
  associate_public_ip_address: true
})
```

## Capacity Planning

```ruby
# Check total capacity
puts "Total web tier capacity: #{web_subnets.total_estimated_capacity} instances"

# Per-subnet capacity
web_subnets.estimated_capacity_per_subnet.each_with_index do |capacity, i|
  puts "Subnet #{i+1}: ~#{capacity} instances"
end

# Per-AZ distribution
web_subnets.az_distribution.each do |az, info|
  puts "#{az}: #{info[:subnet_count]} subnets, #{info[:estimated_capacity]} capacity"
end
```

## Validation Rules

- ✅ Even distribution requires subnet count = AZ count
- ✅ High availability requires minimum AZ count
- ✅ All availability zones must be from same region  
- ✅ Internet-facing load balancers require Internet Gateway
- ✅ IPv6 subnets require public IP capability

## Configuration Profiles

The component automatically assesses your configuration:

```ruby
puts "Web tier profile: #{web_subnets.web_tier_profile}"
# Profiles: 'basic', 'standard', 'advanced', 'enterprise'

puts "Distribution: #{web_subnets.distribution_pattern}"
# Patterns: 'one_per_az', 'even_distribution', 'uneven_distribution'

puts "Load balancer ready: #{web_subnets.load_balancer_ready}"
puts "Highly available: #{web_subnets.is_highly_available}"
```

## Best Practices

1. **Use one subnet per AZ** for optimal load balancer distribution
2. **Size subnets appropriately** - /24 provides ~250 IPs per subnet
3. **Enable public IPs selectively** - only when instances need direct internet access
4. **Plan for growth** - consider future capacity requirements
5. **Tag comprehensively** for cost allocation and management

## Error Examples

```ruby
# ❌ Uneven distribution when even required
web_tier_subnets(:bad, {
  subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"],  # 3 subnets
  availability_zones: ["us-east-1a", "us-east-1b"],             # 2 AZs
  high_availability: { distribute_evenly: true }                # Requires even split
})

# ✅ Even distribution 
web_tier_subnets(:good, {
  subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24"],    # 2 subnets
  availability_zones: ["us-east-1a", "us-east-1b"]  # 2 AZs
})

# ❌ Internet-facing LB without Internet Gateway
web_tier_subnets(:bad, {
  create_internet_gateway: false,
  load_balancing: { scheme: "internet-facing" }
})

# ✅ Consistent configuration
web_tier_subnets(:good, {
  create_internet_gateway: true,        # Enable Internet Gateway
  load_balancing: { scheme: "internet-facing" }
})
```

## Resource Access

```ruby
# Access subnet resources
web_subnets_hash = web_subnets.resources[:web_subnets]  
first_subnet = web_subnets.resources[:web_subnets][:web_1]
internet_gateway = web_subnets.resources[:internet_gateway]
route_table = web_subnets.resources[:web_route_table]

# Access individual subnet by index
subnet_1_id = web_subnets.subnet_ids[0]
subnet_2_id = web_subnets.subnet_ids[1]
```

## Capacity Examples

### Subnet Size Planning

| CIDR Block | Total IPs | AWS Reserved | Available for Instances |
|------------|-----------|--------------|------------------------|
| /28 | 16 | 5 | ~6 instances |
| /27 | 32 | 5 | ~22 instances |
| /26 | 64 | 5 | ~54 instances |
| /25 | 128 | 5 | ~118 instances |
| /24 | 256 | 5 | ~246 instances |

### High Availability Examples

```ruby
# 3-AZ production setup
production = web_tier_subnets(:prod, {
  subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"],  # ~750 total capacity
  availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"]
})

# 2-AZ development setup  
dev = web_tier_subnets(:dev, {
  subnet_cidrs: ["10.1.1.0/25", "10.1.2.0/25"],  # ~240 total capacity
  availability_zones: ["us-east-1a", "us-east-1b"]
})
```

See [CLAUDE.md](./CLAUDE.md) for complete documentation and advanced configuration options.