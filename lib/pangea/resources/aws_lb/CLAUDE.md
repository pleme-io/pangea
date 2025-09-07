# AWS Load Balancer Implementation Documentation

## Overview

This directory contains the implementation for the `aws_lb` resource function, providing type-safe creation and management of AWS Application and Network Load Balancers (ALB/NLB) through terraform-synthesizer integration.

## Implementation Architecture

### Core Components

#### 1. Resource Function (`resource.rb`)
The main `aws_lb` function that:
- Accepts a symbol name and attributes hash
- Validates attributes using dry-struct types
- Generates terraform resource blocks via terraform-synthesizer
- Returns ResourceReference with computed outputs

#### 2. Type Definitions (`types.rb`) 
LoadBalancerAttributes dry-struct defining:
- Required attributes: `subnet_ids`, `load_balancer_type`
- Optional attributes: `name`, `ip_address_type`, `access_logs`
- Type-specific validations for ALB vs NLB features
- Default values and constraints

#### 3. Documentation
- **CLAUDE.md** (this file): Implementation details for developers
- **README.md**: User-facing documentation with examples

## Technical Implementation Details

### Load Balancer Type Support

#### Application Load Balancer (ALB)
- **Protocol Support**: HTTP, HTTPS, WebSocket
- **Layer**: Layer 7 (Application)  
- **Features**: Path-based routing, host-based routing, SSL termination
- **Security Groups**: Required for traffic control

#### Network Load Balancer (NLB)
- **Protocol Support**: TCP, UDP, TLS
- **Layer**: Layer 4 (Transport)
- **Features**: Ultra-high performance, static IP addresses, low latency
- **Security Groups**: Optional (traffic allowed by default)

#### Gateway Load Balancer (GWLB)
- **Protocol Support**: GENEVE
- **Layer**: Layer 3 Gateway + Layer 4 Load Balancing
- **Features**: Deploy third-party virtual appliances

### Type Validation Logic

```ruby
class LoadBalancerAttributes < Dry::Struct
  # Core attributes
  attribute :load_balancer_type, Types::String.enum("application", "network", "gateway")
  attribute :subnet_ids, Types::Array.of(Types::String).constrained(min_size: 2)
  attribute :security_groups, Types::Array.of(Types::String).default([].freeze)
  
  # Type-specific validation
  def self.new(attributes = {})
    attrs = super(attributes)
    
    # Security groups only valid for ALB
    if attrs.security_groups.any? && attrs.load_balancer_type != "application"
      raise Dry::Struct::Error, "security_groups can only be specified for application load balancers"
    end
    
    # Cross-zone load balancing only valid for NLB  
    if !attrs.enable_cross_zone_load_balancing.nil? && attrs.load_balancer_type != "network"
      raise Dry::Struct::Error, "enable_cross_zone_load_balancing can only be specified for network load balancers"
    end
    
    attrs
  end
end
```

### Terraform Synthesis

The resource function generates terraform JSON through terraform-synthesizer:

```ruby
# Generate terraform resource block via terraform-synthesizer
resource(:aws_lb, name) do
  name lb_attrs.name if lb_attrs.name
  load_balancer_type lb_attrs.load_balancer_type
  internal lb_attrs.internal
  
  # Subnets (required for ALB/NLB)
  if lb_attrs.subnet_ids.any?
    subnets lb_attrs.subnet_ids
  end
  
  # Security groups (ALB only)
  if lb_attrs.security_groups.any? && lb_attrs.load_balancer_type == "application"
    security_groups lb_attrs.security_groups
  end
  
  # Additional attributes conditionally applied
  ip_address_type lb_attrs.ip_address_type if lb_attrs.ip_address_type
  enable_deletion_protection lb_attrs.enable_deletion_protection
  
  # Type-specific features
  if lb_attrs.load_balancer_type == "network" && !lb_attrs.enable_cross_zone_load_balancing.nil?
    enable_cross_zone_load_balancing lb_attrs.enable_cross_zone_load_balancing
  end
  
  # Access logs configuration
  if lb_attrs.access_logs
    access_logs do
      bucket lb_attrs.access_logs[:bucket]
      enabled lb_attrs.access_logs[:enabled]
      prefix lb_attrs.access_logs[:prefix] if lb_attrs.access_logs[:prefix]
    end
  end
  
  # Tags
  if lb_attrs.tags.any?
    tags do
      lb_attrs.tags.each do |key, value|
        public_send(key, value)
      end
    end
  end
end
```

### ResourceReference Return Value

The function returns a ResourceReference providing:

#### Terraform Outputs
- `id`: Load balancer ARN
- `arn`: Full ARN 
- `arn_suffix`: ARN suffix for CloudWatch metrics
- `dns_name`: DNS name for the load balancer
- `zone_id`: Route 53 hosted zone ID
- `canonical_hosted_zone_id`: Canonical hosted zone ID
- `vpc_id`: VPC where load balancer is deployed

#### Usage Pattern
```ruby
# Create load balancer and get reference
lb_ref = aws_lb(:main, {
  load_balancer_type: "application",
  subnet_ids: ["subnet-12345", "subnet-67890"],
  security_groups: ["sg-abcdef"],
  tags: { Name: "main-alb", Environment: "production" }
})

# Use reference outputs
puts "Load balancer DNS: #{lb_ref.dns_name}"
puts "Load balancer ARN: #{lb_ref.arn}"

# Use in other resources
aws_lb_listener(:main_https, {
  load_balancer_arn: lb_ref.arn,
  port: 443,
  protocol: "HTTPS"
})
```

## Integration Patterns

### 1. Basic Application Load Balancer
```ruby
template :web_infrastructure do
  # Create VPC and subnets first
  vpc = aws_vpc(:main, cidr_block: "10.0.0.0/16")
  public_subnet_a = aws_subnet(:public_a, {
    vpc_id: vpc.id,
    cidr_block: "10.0.1.0/24",
    availability_zone: "us-east-1a"
  })
  public_subnet_b = aws_subnet(:public_b, {
    vpc_id: vpc.id, 
    cidr_block: "10.0.2.0/24",
    availability_zone: "us-east-1b"
  })
  
  # Create security group for load balancer
  web_sg = aws_security_group(:web_lb, {
    name: "web-lb-sg",
    vpc_id: vpc.id,
    ingress_rules: [
      {
        from_port: 80,
        to_port: 80,
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"]
      },
      {
        from_port: 443,
        to_port: 443, 
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"]
      }
    ]
  })
  
  # Create Application Load Balancer
  web_alb = aws_lb(:web, {
    name: "web-application-lb",
    load_balancer_type: "application",
    internal: false,
    subnet_ids: [public_subnet_a.id, public_subnet_b.id],
    security_groups: [web_sg.id],
    enable_deletion_protection: true,
    tags: {
      Name: "web-alb",
      Environment: "production",
      Application: "web-app"
    }
  })
end
```

### 2. Network Load Balancer for High Performance
```ruby
template :high_performance_api do
  # Network Load Balancer for ultra-low latency
  api_nlb = aws_lb(:api, {
    name: "api-network-lb",
    load_balancer_type: "network", 
    internal: false,
    subnet_ids: [public_subnet_a.id, public_subnet_b.id],
    enable_cross_zone_load_balancing: true,
    ip_address_type: "ipv4",
    tags: {
      Name: "api-nlb",
      Service: "api",
      Performance: "high"
    }
  })
end
```

### 3. Internal Load Balancer with Access Logs
```ruby
template :internal_services do
  # Internal ALB with access logs
  internal_alb = aws_lb(:internal, {
    name: "internal-services-lb",
    load_balancer_type: "application",
    internal: true,  # Internal load balancer
    subnet_ids: [private_subnet_a.id, private_subnet_b.id],
    security_groups: [internal_sg.id],
    access_logs: {
      enabled: true,
      bucket: access_logs_bucket.bucket,
      prefix: "internal-alb-logs"
    },
    tags: {
      Name: "internal-alb",
      Tier: "application",
      Visibility: "internal"
    }
  })
end
```

## Error Handling and Validation

### Common Validation Errors

#### 1. Type-Specific Attribute Errors
```ruby
# ERROR: Security groups on NLB
aws_lb(:bad_nlb, {
  load_balancer_type: "network",
  security_groups: ["sg-12345"]  # Invalid for NLB
})
# Raises: Dry::Struct::Error: "security_groups can only be specified for application load balancers"

# ERROR: Cross-zone load balancing on ALB
aws_lb(:bad_alb, {
  load_balancer_type: "application", 
  enable_cross_zone_load_balancing: true  # Invalid for ALB
})
# Raises: Dry::Struct::Error: "enable_cross_zone_load_balancing can only be specified for network load balancers"
```

#### 2. Subnet Requirements
```ruby
# ERROR: Insufficient subnets
aws_lb(:bad_subnets, {
  load_balancer_type: "application",
  subnet_ids: ["subnet-12345"]  # Need at least 2
})
# Raises: Dry::Struct::Error due to min_size constraint
```

#### 3. Invalid Load Balancer Type
```ruby
# ERROR: Invalid type
aws_lb(:bad_type, {
  load_balancer_type: "classic"  # Not supported
})
# Raises: Dry::Struct::Error due to enum constraint
```

## Testing Strategy

### Unit Tests
Test type validation, attribute processing, and terraform synthesis:

```ruby
RSpec.describe Pangea::Resources::AWS do
  describe "#aws_lb" do
    it "creates Application Load Balancer with valid attributes" do
      lb_ref = aws_lb(:test, {
        load_balancer_type: "application",
        subnet_ids: ["subnet-12345", "subnet-67890"],
        security_groups: ["sg-abcdef"]
      })
      
      expect(lb_ref).to be_a(ResourceReference)
      expect(lb_ref.type).to eq('aws_lb')
      expect(lb_ref.name).to eq(:test)
    end
    
    it "validates security groups only for ALB" do
      expect {
        aws_lb(:nlb_with_sg, {
          load_balancer_type: "network",
          subnet_ids: ["subnet-1", "subnet-2"],
          security_groups: ["sg-123"]
        })
      }.to raise_error(Dry::Struct::Error, /security_groups can only be specified/)
    end
    
    it "synthesizes correct terraform JSON" do
      synthesizer = TerraformSynthesizer.new
      synthesizer.instance_eval do
        aws_lb(:test, {
          load_balancer_type: "application",
          subnet_ids: ["subnet-1", "subnet-2"]
        })
      end
      
      tf_json = synthesizer.synthesis
      expect(tf_json[:resource][:aws_lb][:test]).to include(
        load_balancer_type: "application",
        subnets: ["subnet-1", "subnet-2"]
      )
    end
  end
end
```

### Integration Tests
Test with other AWS resources and terraform-synthesizer:

```ruby
RSpec.describe "Load Balancer Integration" do
  it "integrates with VPC and security groups" do
    synthesizer = TerraformSynthesizer.new
    
    synthesizer.instance_eval do
      vpc_ref = aws_vpc(:main, cidr_block: "10.0.0.0/16")
      subnet_ref = aws_subnet(:public, {
        vpc_id: vpc_ref.id,
        cidr_block: "10.0.1.0/24"
      })
      sg_ref = aws_security_group(:web, {
        name: "web-sg",
        vpc_id: vpc_ref.id
      })
      
      lb_ref = aws_lb(:web, {
        load_balancer_type: "application",
        subnet_ids: [subnet_ref.id, "subnet-additional"],
        security_groups: [sg_ref.id]
      })
    end
    
    tf_json = synthesizer.synthesis
    expect(tf_json[:resource]).to have_key(:aws_vpc)
    expect(tf_json[:resource]).to have_key(:aws_subnet) 
    expect(tf_json[:resource]).to have_key(:aws_security_group)
    expect(tf_json[:resource]).to have_key(:aws_lb)
  end
end
```

## Future Enhancements

### 1. Additional Load Balancer Types
- Support for Gateway Load Balancer (GWLB) features
- Classic Load Balancer (ELB) backward compatibility

### 2. Advanced Configuration
- Custom security policies
- SSL policies and certificate management
- Advanced access logs configuration

### 3. Computed Properties
- Health check endpoints
- Performance metrics integration
- Cost estimation

### 4. Integration Helpers
- Load balancer listener creation
- Target group attachment patterns
- SSL certificate validation

### 5. Multi-Region Support
- Cross-region load balancing patterns
- DNS failover integration

This implementation provides a solid foundation for AWS Load Balancer management within the Pangea resource system, following established patterns for type safety, documentation, and terraform integration.