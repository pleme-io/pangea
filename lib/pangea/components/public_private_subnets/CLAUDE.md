# Public Private Subnets Component

## Overview

The `public_private_subnets` component creates a complete two-tier network architecture with public subnets (for web tiers), private subnets (for application tiers), NAT Gateways for outbound internet access from private subnets, and all necessary routing infrastructure.

## Purpose

This component addresses the fundamental networking pattern in AWS where applications need both publicly accessible components (load balancers, bastion hosts) and privately secured components (application servers, databases) with controlled internet access. It provides a production-ready, highly available network foundation.

## Features

### Complete Two-Tier Architecture
- **Public Subnets**: Internet-accessible subnets with public IP assignment
- **Private Subnets**: Isolated subnets for internal resources
- **Internet Gateway**: Direct internet access for public subnets
- **NAT Gateway**: Controlled outbound internet access for private subnets

### High Availability Options
- **Multi-AZ Distribution**: Automatic distribution of subnets across availability zones
- **NAT Gateway Redundancy**: Single NAT Gateway or per-AZ NAT Gateways for failover
- **Even Distribution**: Automatically distribute subnets evenly across AZs

### Advanced Routing
- **Public Route Table**: Routes public subnet traffic to Internet Gateway
- **Private Route Tables**: Routes private subnet traffic through NAT Gateway
- **Automatic Associations**: All subnet-to-route-table associations created automatically
- **AZ-Specific Routing**: Separate route tables per AZ for maximum isolation

### Cost Optimization
- **Flexible NAT Strategy**: Choose single NAT (cost-effective) or per-AZ NAT (highly available)
- **Cost Estimation**: Built-in monthly cost estimation for NAT Gateways
- **Resource Tagging**: Comprehensive tagging for cost allocation

## Usage

### Basic Public-Private Architecture

```ruby
template :network_infrastructure do
  include Pangea::Resources::AWS
  include Pangea::Components::PublicPrivateSubnets
  
  # Create VPC first
  vpc = aws_vpc(:main, {
    cidr_block: "10.0.0.0/16"
  })
  
  # Create public-private subnet pair
  subnets = public_private_subnets(:web_tier, {
    vpc_ref: vpc,
    public_cidrs: ["10.0.1.0/24", "10.0.2.0/24"],
    private_cidrs: ["10.0.10.0/24", "10.0.20.0/24"],
    availability_zones: ["us-east-1a", "us-east-1b"]
  })
  
  # Use subnets in other resources
  load_balancer = aws_lb(:web_lb, {
    subnet_ids: subnets.public_subnet_ids,
    load_balancer_type: "application"
  })
end
```

### Production High-Availability Setup

```ruby
# High-availability production network with per-AZ NAT Gateways
production_subnets = public_private_subnets(:production, {
  vpc_ref: production_vpc,
  public_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"],
  private_cidrs: ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"],
  availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
  
  # High availability configuration
  nat_gateway_type: "per_az",  # NAT Gateway per AZ for redundancy
  enable_nat_gateway_monitoring: true,
  
  high_availability: {
    multi_az: true,
    min_availability_zones: 3,
    distribute_evenly: true
  },
  
  tags: {
    Environment: "production",
    HighAvailability: "true",
    CostCenter: "platform"
  },
  
  # Subnet-specific tags
  public_subnet_tags: {
    Tier: "web",
    Internet: "accessible"
  },
  
  private_subnet_tags: {
    Tier: "application",
    Internet: "nat_only"
  }
})
```

### Cost-Optimized Development Setup

```ruby
# Development environment with single NAT Gateway
dev_subnets = public_private_subnets(:development, {
  vpc_ref: dev_vpc,
  public_cidrs: ["10.1.1.0/24", "10.1.2.0/24"],
  private_cidrs: ["10.1.10.0/24", "10.1.20.0/24"],
  availability_zones: ["us-east-1a", "us-east-1b"],
  
  # Cost optimization
  nat_gateway_type: "single",  # Single NAT Gateway to reduce costs
  enable_nat_gateway_monitoring: false,
  
  high_availability: {
    multi_az: true,
    min_availability_zones: 2
  },
  
  tags: {
    Environment: "development",
    AutoShutdown: "true",
    CostOptimized: "true"
  }
})

# Check estimated costs
puts "Estimated monthly NAT cost: $#{dev_subnets.estimated_monthly_nat_cost}"
```

## Attributes

### Required Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `vpc_ref` | ResourceReference/String | VPC to create subnets in |
| `public_cidrs` | Array[String] | CIDR blocks for public subnets |
| `private_cidrs` | Array[String] | CIDR blocks for private subnets |

### Optional Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `availability_zones` | Array[String] | Auto-detected | Availability zones for subnet distribution |
| `create_nat_gateway` | Boolean | `true` | Whether to create NAT Gateway for private subnets |
| `nat_gateway_type` | String | `'per_az'` | NAT Gateway strategy: `'single'` or `'per_az'` |
| `enable_nat_gateway_monitoring` | Boolean | `true` | Enable CloudWatch monitoring for NAT Gateways |
| `tags` | Hash | `{}` | Tags applied to all resources |
| `public_subnet_tags` | Hash | `{}` | Additional tags for public subnets |
| `private_subnet_tags` | Hash | `{}` | Additional tags for private subnets |
| `high_availability` | Hash | See below | High availability configuration |

### High Availability Configuration

```ruby
high_availability: {
  multi_az: true,                    # Distribute across multiple AZs
  min_availability_zones: 2,         # Minimum AZ count (1-6)
  distribute_evenly: true            # Distribute subnets evenly across AZs
}
```

## Resources Created

### Networking Infrastructure

1. **aws_internet_gateway**: Provides internet access for public subnets
   - Attached to the specified VPC
   - Enables bidirectional internet connectivity

2. **aws_subnet** (Public): Public subnets with internet access
   - `map_public_ip_on_launch` enabled
   - Distributed across availability zones
   - Tagged for identification as public/web tier

3. **aws_subnet** (Private): Private subnets for internal resources
   - `map_public_ip_on_launch` disabled
   - Distributed across availability zones
   - Tagged for identification as private/application tier

### Routing Infrastructure

4. **aws_route_table** (Public): Public subnet routing
   - Single route table for all public subnets
   - Routes 0.0.0.0/0 to Internet Gateway

5. **aws_route_table** (Private): Private subnet routing
   - Strategy depends on NAT Gateway configuration
   - Single route table (single NAT) or per-AZ route tables

6. **aws_route** (Public): Default route to Internet Gateway
   - Routes all traffic (0.0.0.0/0) to Internet Gateway

7. **aws_route** (Private): Default routes to NAT Gateway
   - Routes all traffic through NAT Gateway(s)

8. **aws_route_table_association**: Subnet-to-route-table associations
   - Associates each subnet with appropriate route table
   - Automatic association based on subnet type and AZ

### NAT Gateway Infrastructure (if enabled)

9. **aws_eip**: Elastic IP addresses for NAT Gateways
   - One per NAT Gateway
   - VPC domain allocation

10. **aws_nat_gateway**: NAT Gateways for outbound internet access
    - Single NAT Gateway or per-AZ NAT Gateways
    - Placed in public subnets
    - Uses Elastic IP addresses

## Outputs

### Subnet Information
- `public_subnet_ids`: Array of public subnet IDs
- `private_subnet_ids`: Array of private subnet IDs
- `public_subnet_cidrs`: Array of public subnet CIDR blocks
- `private_subnet_cidrs`: Array of private subnet CIDR blocks

### Network Infrastructure
- `vpc_id`: VPC ID
- `internet_gateway_id`: Internet Gateway ID
- `nat_gateway_ids`: Array of NAT Gateway IDs
- `nat_eip_ips`: Array of NAT Gateway public IP addresses

### Routing Information
- `public_route_table_id`: Public route table ID
- `private_route_table_ids`: Array of private route table IDs

### Configuration Summary
- `subnet_pairs_count`: Number of subnet pairs (public-private)
- `total_subnets_count`: Total number of subnets created
- `nat_gateway_count`: Number of NAT Gateways created
- `nat_gateway_type`: NAT Gateway deployment strategy

### High Availability Information
- `availability_zones`: Array of availability zones used
- `high_availability_level`: HA level (`'none'`, `'basic'`, `'high'`)
- `subnet_distribution_strategy`: Distribution strategy used
- `networking_pattern`: Pattern type (`'hybrid_public_private'`, etc.)
- `security_profile`: Security profile level

### Cost Information
- `estimated_monthly_nat_cost`: Estimated monthly NAT Gateway costs

## Component Reference Usage

```ruby
# Access subnet collections
public_subnets = subnets.resources[:public_subnets]
private_subnets = subnets.resources[:private_subnets]

# Access specific resources
first_public = subnets.resources[:public_subnets][:public_1]
internet_gateway = subnets.resources[:internet_gateway]

# Use computed outputs
load_balancer = aws_lb(:web_lb, {
  subnet_ids: subnets.public_subnet_ids,
  scheme: "internet-facing"
})

app_instances = aws_instance(:app_servers, {
  subnet_id: subnets.private_subnet_ids.first,
  ami: "ami-12345678"
})

# Check configuration
if subnets.high_availability_level == 'high'
  puts "High availability network deployed"
  puts "NAT Gateway cost: $#{subnets.estimated_monthly_nat_cost}/month"
end
```

## Validation and Constraints

### CIDR Block Validation
- Public and private CIDR blocks must not overlap
- All CIDR blocks must be valid and within VPC CIDR range
- CIDR blocks are validated for proper subnet mask

### Availability Zone Validation
- All availability zones must be from the same region
- High availability mode requires minimum AZ count
- Even distribution requires subnet count divisible by AZ count

### NAT Gateway Validation
- Per-AZ NAT Gateway requires at least one private subnet per AZ
- Single NAT Gateway mode uses first public subnet
- NAT Gateway monitoring requires NAT Gateway creation

### High Availability Validation
- Multi-AZ mode requires multiple availability zones
- Even distribution validates subnet-to-AZ ratio
- Minimum AZ requirements are enforced

## NAT Gateway Strategies

### Single NAT Gateway (`nat_gateway_type: 'single'`)

**Use Cases:**
- Development environments
- Cost-sensitive deployments  
- Simple architectures with minimal availability requirements

**Characteristics:**
- One NAT Gateway in first public subnet
- Single point of failure
- Lower cost (~$45/month)
- All private subnets route through single NAT

**Architecture:**
```
Public Subnet 1 [Internet Gateway] <-- NAT Gateway
Public Subnet 2 [Internet Gateway]
                     |
         ┌──────────────┴──────────────┐
Private Subnet 1 ──────────────────────┘
Private Subnet 2 ──────────────────────┘
```

### Per-AZ NAT Gateway (`nat_gateway_type: 'per_az'`)

**Use Cases:**
- Production environments
- High availability requirements
- Applications requiring fault tolerance

**Characteristics:**
- One NAT Gateway per availability zone
- No single point of failure
- Higher cost (NAT cost × AZ count)
- AZ-isolated routing for better performance

**Architecture:**
```
AZ-1: Public Subnet 1 [IGW] <-- NAT Gateway 1
      Private Subnet 1 ────────────────┘

AZ-2: Public Subnet 2 [IGW] <-- NAT Gateway 2  
      Private Subnet 2 ────────────────┘
```

## Integration Patterns

### With Secure VPC Component

```ruby
# Create secure VPC foundation
network = secure_vpc(:main, {
  cidr_block: "10.0.0.0/16",
  availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"]
})

# Add public-private subnet architecture
subnets = public_private_subnets(:web_tier, {
  vpc_ref: network.vpc,
  public_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"],
  private_cidrs: ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"],
  availability_zones: network.availability_zones
})
```

### With Load Balancer

```ruby
# Create load balancer in public subnets
alb = aws_lb(:web_lb, {
  name: "web-load-balancer",
  load_balancer_type: "application",
  scheme: "internet-facing",
  subnet_ids: subnets.public_subnet_ids,
  security_groups: [web_sg.id]
})

# Create target instances in private subnets
web_servers = aws_autoscaling_group(:web_servers, {
  vpc_zone_identifier: subnets.private_subnet_ids,
  target_group_arns: [target_group.arn]
})
```

### With Database Subnets

```ruby
# Add database subnets to the architecture
db_subnets = aws_db_subnet_group(:database, {
  name: "database-subnets",
  subnet_ids: subnets.private_subnet_ids,
  tags: { Tier: "database" }
})

# Create RDS instance in private subnets
database = aws_db_instance(:main_db, {
  db_subnet_group_name: db_subnets.name,
  vpc_security_group_ids: [db_sg.id]
})
```

## Cost Considerations

### NAT Gateway Costs
- **Single NAT**: ~$45/month + data processing fees
- **Per-AZ NAT**: ~$45/month × number of AZs + data processing fees
- **Data Processing**: ~$0.045 per GB processed

### Cost Optimization Strategies
1. **Use single NAT Gateway** for development environments
2. **Enable auto-shutdown tags** for temporary environments  
3. **Monitor NAT Gateway data processing** charges
4. **Consider VPC endpoints** for AWS service access to reduce NAT usage

### Estimated Monthly Costs (US-East-1)

| Configuration | NAT Gateways | Estimated Cost |
|---------------|--------------|----------------|
| Single AZ | 1 | $45-60/month |
| 2 AZ (single NAT) | 1 | $45-60/month |
| 2 AZ (per-AZ NAT) | 2 | $90-120/month |
| 3 AZ (per-AZ NAT) | 3 | $135-180/month |

*Estimates include NAT Gateway hours and moderate data processing*

## Security Considerations

### Network Isolation
- **Public subnets** have direct internet access (bidirectional)
- **Private subnets** have outbound-only internet access through NAT
- **Route table isolation** prevents cross-tier traffic leakage

### Security Groups
- Public subnets typically need security groups allowing inbound web traffic
- Private subnets need security groups allowing traffic from public tier
- NAT Gateways provide stateful outbound internet access

### Compliance Features
- **Network segmentation** between tiers
- **Controlled internet access** for private resources
- **High availability** options for business continuity
- **Comprehensive tagging** for audit and compliance

## Best Practices

### Design Principles
1. **Plan CIDR blocks** to avoid overlaps and allow growth
2. **Use per-AZ NAT Gateways** for production high availability
3. **Implement even distribution** for balanced load across AZs
4. **Tag resources comprehensively** for management and cost allocation

### Operational Excellence
1. **Monitor NAT Gateway metrics** for performance and costs
2. **Implement CloudWatch alarms** for NAT Gateway health
3. **Use descriptive naming** for easy resource identification
4. **Document subnet purposes** in tags and descriptions

### Cost Management
1. **Choose NAT strategy** based on availability requirements vs. cost
2. **Monitor data processing charges** for unexpected usage
3. **Consider VPC endpoints** for AWS service access
4. **Use auto-shutdown tags** in non-production environments

## Error Handling

Common validation errors and solutions:

### CIDR Overlap Errors
```ruby
# Error: Duplicate CIDR blocks
public_private_subnets(:test, {
  public_cidrs: ["10.0.1.0/24"],
  private_cidrs: ["10.0.1.0/24"]  # Same as public
})
# Solution: Use non-overlapping CIDR blocks
```

### High Availability Errors
```ruby
# Error: Not enough AZs for HA requirements
public_private_subnets(:test, {
  availability_zones: ["us-east-1a"],  # Only 1 AZ
  high_availability: { 
    multi_az: true,
    min_availability_zones: 2  # Requires 2 AZs
  }
})
# Solution: Provide sufficient availability zones
```

### Even Distribution Errors
```ruby
# Error: Uneven subnet distribution
public_private_subnets(:test, {
  public_cidrs: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"],  # 3 subnets
  availability_zones: ["us-east-1a", "us-east-1b"],  # 2 AZs
  high_availability: { distribute_evenly: true }  # 3 not divisible by 2
})
# Solution: Make subnet count divisible by AZ count
```

## Testing

```ruby
RSpec.describe Pangea::Components::PublicPrivateSubnets do
  describe "#public_private_subnets" do
    it "creates complete public-private architecture" do
      vpc = double('vpc', id: 'vpc-12345')
      
      subnets = public_private_subnets(:test, {
        vpc_ref: vpc,
        public_cidrs: ["10.0.1.0/24", "10.0.2.0/24"],
        private_cidrs: ["10.0.10.0/24", "10.0.20.0/24"]
      })
      
      expect(subnets).to be_a(ComponentReference)
      expect(subnets.type).to eq('public_private_subnets')
      expect(subnets.resources[:public_subnets]).to have(2).items
      expect(subnets.resources[:private_subnets]).to have(2).items
      expect(subnets.resources[:nat_gateways]).to have(2).items  # per-AZ default
      expect(subnets.networking_pattern).to eq('hybrid_public_private')
    end
    
    it "validates CIDR uniqueness" do
      expect {
        public_private_subnets(:test, {
          public_cidrs: ["10.0.1.0/24"],
          private_cidrs: ["10.0.1.0/24"]
        })
      }.to raise_error(Dry::Struct::Error, /Duplicate CIDR blocks/)
    end
    
    it "calculates costs correctly" do
      subnets = public_private_subnets(:test, {
        availability_zones: ["us-east-1a", "us-east-1b"],
        nat_gateway_type: "per_az"
      })
      
      expect(subnets.estimated_monthly_nat_cost).to eq(90.0)  # 2 AZs × $45
    end
  end
end
```

This public-private subnets component provides a complete, production-ready two-tier network architecture with flexible high availability and cost optimization options.