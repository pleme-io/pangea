# Web Tier Subnets Component

## Overview

The `web_tier_subnets` component creates public subnets optimized for web tier workloads, distributed across multiple availability zones with Internet Gateway routing. This component is specifically designed for resources that need direct internet access, such as load balancers, bastion hosts, and web servers.

## Purpose

This component addresses the need for internet-accessible infrastructure in AWS. Unlike the `public_private_subnets` component which creates both public and private tiers, this component focuses solely on creating highly available public subnets optimized for web workloads with comprehensive routing and capacity planning.

## Features

### Internet-Accessible Infrastructure
- **Public Subnets**: Subnets with direct internet access via Internet Gateway
- **Public IP Assignment**: Automatic public IP assignment for instances (configurable)
- **Internet Gateway**: Dedicated Internet Gateway for bidirectional internet connectivity
- **Optimized Routing**: Route table configuration optimized for web traffic patterns

### High Availability Distribution
- **Multi-AZ Distribution**: Automatic distribution of subnets across availability zones
- **Even Distribution**: Configurable even distribution across AZs for balanced load
- **Load Balancer Ready**: Pre-configured for load balancer deployment
- **Capacity Planning**: Built-in capacity estimation per subnet and AZ

### Web Tier Optimization
- **Load Balancer Integration**: Pre-configured for ALB/NLB deployment
- **Web Traffic Routing**: Optimized routing for HTTP/HTTPS traffic
- **Public IP Management**: Configurable public IP assignment policies
- **IPv6 Ready**: Configuration support for IPv6 (future enhancement)

## Usage

### Basic Web Tier Subnets

```ruby
template :web_infrastructure do
  include Pangea::Resources::AWS
  include Pangea::Components::WebTierSubnets
  
  # Create VPC first
  vpc = aws_vpc(:main, {
    cidr_block: "10.0.0.0/16"
  })
  
  # Create web tier subnets
  web_subnets = web_tier_subnets(:web_tier, {
    vpc_ref: vpc,
    subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"],
    availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"]
  })
  
  # Deploy load balancer in web subnets
  load_balancer = aws_lb(:web_lb, {
    subnet_ids: web_subnets.subnet_ids,
    load_balancer_type: "application",
    scheme: "internet-facing"
  })
end
```

### Production High-Availability Web Tier

```ruby
# Production web tier with high availability
production_web = web_tier_subnets(:production_web, {
  vpc_ref: production_vpc,
  subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"],
  availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
  
  # Public IP configuration
  enable_public_ips: true,
  
  # High availability settings
  high_availability: {
    multi_az: true,
    min_availability_zones: 3,
    distribute_evenly: true
  },
  
  # Load balancer optimization
  load_balancing: {
    type: "application",
    scheme: "internet-facing",
    enable_deletion_protection: true,
    enable_cross_zone: true
  },
  
  tags: {
    Environment: "production",
    Tier: "web",
    HighAvailability: "true",
    InternetFacing: "true"
  },
  
  subnet_tags: {
    Purpose: "web_workloads",
    LoadBalancerTarget: "true",
    PublicAccess: "enabled"
  }
})

# Check capacity and distribution
puts "Total estimated capacity: #{production_web.total_estimated_capacity} instances"
puts "Distribution pattern: #{production_web.distribution_pattern}"
```

### Development Web Tier

```ruby
# Simple development web tier
dev_web = web_tier_subnets(:dev_web, {
  vpc_ref: dev_vpc,
  subnet_cidrs: ["10.1.1.0/24", "10.1.2.0/24"],
  availability_zones: ["us-east-1a", "us-east-1b"],
  
  enable_public_ips: true,
  
  high_availability: {
    multi_az: true,
    min_availability_zones: 2
  },
  
  tags: {
    Environment: "development",
    CostOptimized: "true",
    AutoShutdown: "enabled"
  }
})
```

### Custom Port Configuration

```ruby
# Web tier with custom configuration
custom_web = web_tier_subnets(:custom_web, {
  vpc_ref: vpc,
  subnet_cidrs: ["10.0.10.0/24", "10.0.20.0/24"],
  availability_zones: ["us-east-1a", "us-east-1b"],
  
  # Disable public IPs for instances behind load balancer
  enable_public_ips: false,
  
  # Enable IPv6 (future feature)
  enable_ipv6: false,
  
  load_balancing: {
    type: "network",
    scheme: "internet-facing"
  },
  
  tags: {
    CustomConfiguration: "true",
    LoadBalancerOnly: "true"
  }
})
```

## Attributes

### Required Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `vpc_ref` | ResourceReference/String | VPC to create subnets in |
| `subnet_cidrs` | Array[String] | CIDR blocks for web subnets |
| `availability_zones` | Array[String] | Availability zones for subnet distribution |

### Optional Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `enable_public_ips` | Boolean | `true` | Enable automatic public IP assignment |
| `enable_ipv6` | Boolean | `false` | Enable IPv6 support (future feature) |
| `create_internet_gateway` | Boolean | `true` | Create Internet Gateway for internet access |
| `create_nat_gateway` | Boolean | `false` | Create NAT Gateway (usually false for web tier) |
| `tags` | Hash | `{}` | Tags applied to all resources |
| `subnet_tags` | Hash | `{}` | Additional tags for subnets |
| `high_availability` | Hash | See below | High availability configuration |
| `load_balancing` | Hash | See below | Load balancing configuration |

### High Availability Configuration

```ruby
high_availability: {
  multi_az: true,                    # Distribute across multiple AZs
  min_availability_zones: 2,         # Minimum AZ count (1-6)
  distribute_evenly: true            # Distribute subnets evenly across AZs
}
```

### Load Balancing Configuration

```ruby
load_balancing: {
  type: "application",               # Load balancer type
  scheme: "internet-facing",         # Internet-facing or internal
  enable_deletion_protection: false, # Protect from accidental deletion
  enable_cross_zone: true,          # Cross-zone load balancing
  idle_timeout: 60                  # Connection idle timeout (seconds)
}
```

## Resources Created

### Network Infrastructure

1. **aws_internet_gateway**: Internet Gateway for direct internet access
   - Attached to the specified VPC
   - Enables bidirectional internet connectivity

2. **aws_subnet** (Web): Public subnets for web workloads
   - `map_public_ip_on_launch` configurable (default: enabled)
   - Distributed across specified availability zones
   - Tagged for web tier identification

### Routing Infrastructure

3. **aws_route_table**: Web tier route table
   - Single route table for all web subnets
   - Optimized for web traffic patterns

4. **aws_route**: Route to Internet Gateway
   - Default route (0.0.0.0/0) to Internet Gateway
   - Enables internet access for all subnets

5. **aws_route_table_association**: Subnet associations
   - Associates each web subnet with the web route table
   - Automatic association for all created subnets

## Outputs

### Subnet Information
- `subnet_ids`: Array of web subnet IDs
- `subnet_cidrs`: Array of subnet CIDR blocks
- `subnet_count`: Total number of subnets created

### Availability Zone Information
- `availability_zones`: Array of availability zones used
- `az_count`: Number of availability zones
- `az_distribution`: Distribution of subnets per AZ with capacity estimates
- `subnets_per_az`: Average subnets per availability zone

### Network Configuration
- `vpc_id`: VPC identifier
- `internet_gateway_id`: Internet Gateway identifier
- `route_table_id`: Web route table identifier

### Feature Configuration
- `public_ips_enabled`: Whether public IP assignment is enabled
- `ipv6_enabled`: Whether IPv6 support is enabled
- `internet_gateway_created`: Whether Internet Gateway was created

### High Availability Information
- `is_highly_available`: Whether deployment meets HA requirements
- `distribution_pattern`: Subnet distribution strategy used
- `load_balancer_ready`: Whether subnets are ready for load balancer deployment

### Capacity Planning
- `estimated_capacity_per_subnet`: Array of estimated instance capacity per subnet
- `total_estimated_capacity`: Total estimated instance capacity across all subnets

### Configuration Summary
- `tier_configuration`: Complete tier configuration analysis
- `web_tier_profile`: Web tier profile level (`'basic'`, `'standard'`, `'advanced'`, `'enterprise'`)
- `compliance_features`: Array of enabled compliance features

## Component Reference Usage

```ruby
# Access subnet resources
web_subnets = subnets.resources[:web_subnets]
first_subnet = subnets.resources[:web_subnets][:web_1]
internet_gateway = subnets.resources[:internet_gateway]

# Use computed outputs in other resources
load_balancer = aws_lb(:web_lb, {
  subnet_ids: subnets.subnet_ids,
  load_balancer_type: "application"
})

bastion = aws_instance(:bastion, {
  subnet_id: subnets.subnet_ids.first,
  ami: "ami-12345678",
  associate_public_ip_address: true
})

# Check capacity and distribution
if subnets.is_highly_available
  puts "High availability web tier deployed"
  puts "Total capacity: #{subnets.total_estimated_capacity} instances"
  
  subnets.az_distribution.each do |az, info|
    puts "#{az}: #{info[:subnet_count]} subnets, #{info[:estimated_capacity]} capacity"
  end
end

# Access configuration information
puts "Web tier profile: #{subnets.web_tier_profile}"
puts "Distribution pattern: #{subnets.distribution_pattern}"
puts "Load balancer ready: #{subnets.load_balancer_ready}"
```

## Distribution Patterns

### One Per AZ (`'one_per_az'`)
Perfect 1:1 subnet to AZ ratio for maximum simplicity and even distribution.

```ruby
web_tier_subnets(:example, {
  subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24"],     # 2 subnets
  availability_zones: ["us-east-1a", "us-east-1b"]   # 2 AZs
})
# Result: 1 subnet per AZ, perfect distribution
```

### Even Distribution (`'even_distribution'`)
Subnet count is evenly divisible by AZ count, enabling balanced load distribution.

```ruby
web_tier_subnets(:example, {
  subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"],  # 4 subnets
  availability_zones: ["us-east-1a", "us-east-1b"]   # 2 AZs
})
# Result: 2 subnets per AZ, even distribution
```

### Uneven Distribution (`'uneven_distribution'`)
More subnets than AZs, but not evenly divisible - some AZs get more subnets.

```ruby
web_tier_subnets(:example, {
  subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"],  # 3 subnets
  availability_zones: ["us-east-1a", "us-east-1b"]   # 2 AZs
})
# Result: AZ-a gets 2 subnets, AZ-b gets 1 subnet
```

## Validation and Constraints

### Subnet and AZ Validation
- Even distribution requires subnet count to equal AZ count
- High availability mode requires minimum AZ and subnet counts
- All availability zones must be from the same region

### Load Balancer Configuration Validation
- Internet-facing load balancers require public IPs and Internet Gateway
- Internal load balancers don't require Internet Gateway

### IPv6 Configuration Validation
- IPv6 subnets typically require public IP assignment capability
- IPv6 validation will be enhanced when AWS resource support is added

## Integration Patterns

### With Secure VPC Component

```ruby
# Create secure VPC foundation
network = secure_vpc(:main, {
  cidr_block: "10.0.0.0/16",
  availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"]
})

# Add web tier subnets
web_subnets = web_tier_subnets(:web_tier, {
  vpc_ref: network.vpc,
  subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"],
  availability_zones: network.availability_zones
})
```

### With Application Load Balancer

```ruby
# Create Application Load Balancer in web subnets
alb = aws_lb(:web_lb, {
  name: "web-load-balancer",
  load_balancer_type: "application",
  scheme: "internet-facing",
  subnet_ids: web_subnets.subnet_ids,
  
  tags: {
    Tier: "web",
    Purpose: "public_load_balancer"
  }
})

# Create target group for load balancer
target_group = aws_lb_target_group(:web_targets, {
  name: "web-targets",
  port: 80,
  protocol: "HTTP",
  vpc_id: web_subnets.vpc_id,
  target_type: "instance"
})
```

### With Auto Scaling Group

```ruby
# Create Auto Scaling Group using web subnets
web_asg = aws_autoscaling_group(:web_servers, {
  name: "web-servers",
  vpc_zone_identifier: web_subnets.subnet_ids,
  min_size: 2,
  max_size: 10,
  desired_capacity: 4,
  target_group_arns: [target_group.arn],
  
  tags: [{
    key: "Name",
    value: "web-server",
    propagate_at_launch: true
  }]
})
```

### With Bastion Host

```ruby
# Deploy bastion host in first web subnet
bastion = aws_instance(:bastion, {
  ami: "ami-12345678",
  instance_type: "t3.micro",
  subnet_id: web_subnets.subnet_ids.first,
  associate_public_ip_address: true,
  
  tags: {
    Name: "bastion-host",
    Purpose: "ssh_access"
  }
})
```

## Capacity Planning

The component provides detailed capacity planning information:

### Per-Subnet Capacity
```ruby
# Get capacity estimates for each subnet
web_subnets.estimated_capacity_per_subnet.each_with_index do |capacity, index|
  puts "Subnet #{index + 1}: ~#{capacity} instances"
end
```

### Per-AZ Capacity
```ruby
# Get capacity distribution per AZ
web_subnets.az_distribution.each do |az, info|
  puts "#{az}:"
  puts "  Subnets: #{info[:subnet_count]}"
  puts "  Estimated capacity: #{info[:estimated_capacity]} instances"
  puts "  Subnet names: #{info[:subnets].join(', ')}"
end
```

### Total Capacity
```ruby
puts "Total web tier capacity: #{web_subnets.total_estimated_capacity} instances"
```

## Best Practices

### Design Principles
1. **Use one subnet per AZ** for simple, balanced load distribution
2. **Enable public IPs** only when instances need direct internet access
3. **Plan CIDR blocks** to accommodate expected instance growth
4. **Tag comprehensively** for resource management and cost allocation

### High Availability
1. **Deploy across multiple AZs** for fault tolerance
2. **Use even distribution** when possible for balanced load
3. **Size subnets appropriately** for expected instance counts
4. **Monitor capacity utilization** to plan for growth

### Security Considerations
1. **Consider disabling public IPs** for instances behind load balancers
2. **Use security groups** to control access to instances
3. **Monitor internet-facing resources** for security compliance
4. **Implement least privilege access** patterns

### Cost Optimization
1. **Right-size subnet CIDR blocks** to avoid waste
2. **Use appropriate instance types** for workload requirements
3. **Monitor and optimize** load balancer costs
4. **Tag resources** for cost allocation and monitoring

## Error Handling

Common validation errors and solutions:

### Subnet-AZ Mismatch Errors
```ruby
# Error: Uneven distribution when even required
web_tier_subnets(:test, {
  subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"],  # 3 subnets
  availability_zones: ["us-east-1a", "us-east-1b"],  # 2 AZs  
  high_availability: { distribute_evenly: true }  # Requires even distribution
})
# Solution: Make subnet count equal to AZ count or disable even distribution
```

### High Availability Errors
```ruby
# Error: Insufficient AZs for HA
web_tier_subnets(:test, {
  availability_zones: ["us-east-1a"],  # Only 1 AZ
  high_availability: {
    multi_az: true,
    min_availability_zones: 2  # Requires 2 AZs
  }
})
# Solution: Provide sufficient availability zones
```

### Load Balancer Configuration Errors
```ruby
# Error: Internet-facing LB without Internet Gateway
web_tier_subnets(:test, {
  create_internet_gateway: false,
  load_balancing: { scheme: "internet-facing" }
})
# Solution: Enable Internet Gateway or use internal scheme
```

## Testing

```ruby
RSpec.describe Pangea::Components::WebTierSubnets do
  describe "#web_tier_subnets" do
    it "creates web tier subnets with internet access" do
      vpc = double('vpc', id: 'vpc-12345')
      
      subnets = web_tier_subnets(:test, {
        vpc_ref: vpc,
        subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24"],
        availability_zones: ["us-east-1a", "us-east-1b"]
      })
      
      expect(subnets).to be_a(ComponentReference)
      expect(subnets.type).to eq('web_tier_subnets')
      expect(subnets.resources[:web_subnets]).to have(2).items
      expect(subnets.resources[:internet_gateway]).to be_present
      expect(subnets.is_highly_available).to be true
      expect(subnets.distribution_pattern).to eq('one_per_az')
    end
    
    it "validates even distribution requirements" do
      expect {
        web_tier_subnets(:test, {
          subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"],
          availability_zones: ["us-east-1a", "us-east-1b"],
          high_availability: { distribute_evenly: true }
        })
      }.to raise_error(Dry::Struct::Error, /Even distribution/)
    end
    
    it "calculates capacity correctly" do
      subnets = web_tier_subnets(:test, {
        subnet_cidrs: ["10.0.1.0/24", "10.0.2.0/24"],  # /24 = ~250 IPs each
        availability_zones: ["us-east-1a", "us-east-1b"]
      })
      
      expect(subnets.estimated_capacity_per_subnet).to all(be > 240)
      expect(subnets.total_estimated_capacity).to be > 480
    end
  end
end
```

This web tier subnets component provides a robust, highly available foundation for internet-facing workloads with comprehensive capacity planning and integration capabilities.