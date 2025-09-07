# AWS Load Balancer Target Group Attachment Implementation

## Overview

The `aws_lb_target_group_attachment` resource implements comprehensive AWS Load Balancer target registration with intelligent target type detection, validation, and support for all AWS target types including EC2 instances, IP addresses, Lambda functions, and Application Load Balancers.

## Architecture

### Type System

```ruby
LoadBalancerTargetGroupAttachmentAttributes < Dry::Struct
  - target_group_arn: String (validated ALB/NLB target group ARN)
  - target_id: String (EC2 instance ID, IP address, Lambda ARN, or ALB ARN)
  - port: ListenerPort? (1-65535, required for instance/IP targets)
  - availability_zone: String? (required for cross-AZ IP targets)
```

### Target Type Detection Engine

The implementation automatically detects target type from `target_id` format:

```ruby
def self.determine_target_type(target_id)
  case target_id
  when /\Ai-[a-z0-9]+\z/                                    # EC2 instance
    :instance
  when /\A(?:\d{1,3}\.){3}\d{1,3}\z/, /\A[0-9a-f:]+\z/i    # IPv4/IPv6 address
    :ip
  when /\Aarn:aws:lambda:/                                   # Lambda function
    :lambda
  when /\Aarn:aws:elasticloadbalancing:.*:loadbalancer\/app\// # ALB
    :alb
  else
    :unknown
  end
end
```

### Validation Logic by Target Type

**EC2 Instance Targets:**
- Require `port` parameter
- `availability_zone` is optional (ALB discovers automatically)
- Instance ID format: `i-[a-z0-9]+`

**IP Address Targets:**
- Require `port` parameter
- `availability_zone` required if IP is in different AZ than load balancer
- Support both IPv4 and IPv6 addresses
- Private and public IP addresses supported

**Lambda Function Targets:**
- `port` not allowed (generates validation error)
- `availability_zone` not allowed
- Must be Lambda function ARN format

**ALB Targets:**
- `port` optional
- `availability_zone` not allowed
- Used for complex routing scenarios and service mesh architectures

## Production Target Registration Patterns

### Auto Scaling Integration

```ruby
class AutoScalingTargetManager
  def self.register_asg_instances(target_group_arn, asg_instances, port)
    # Register current ASG instances as targets
    current_attachments = asg_instances.map.with_index do |instance_id, index|
      aws_lb_target_group_attachment(:"asg_#{instance_id.tr('-', '_')}", {
        target_group_arn: target_group_arn,
        target_id: instance_id,
        port: port
      })
    end
    
    # Note: For production use, integrate with ASG lifecycle hooks
    # for automatic target registration/deregistration
    current_attachments
  end
end
```

### Microservices Service Discovery

```ruby
# Service mesh target registration with health checking
class ServiceMeshTargets
  SERVICES = {
    user_service: { port: 8001, instances: [] },
    order_service: { port: 8002, instances: [] },
    payment_service: { port: 8003, instances: [] },
    inventory_service: { port: 8004, instances: [] }
  }.freeze

  def self.register_service_targets(service_target_groups)
    all_attachments = {}
    
    SERVICES.each do |service, config|
      service_attachments = config[:instances].map.with_index do |instance, idx|
        aws_lb_target_group_attachment(:"#{service}_instance_#{idx}", {
          target_group_arn: service_target_groups[service].arn,
          target_id: instance,
          port: config[:port]
        })
      end
      
      all_attachments[service] = service_attachments
    end
    
    all_attachments
  end
end
```

### Container Orchestration Integration

```ruby
# ECS Fargate service target registration
class FargateTargetRegistration
  def self.register_fargate_tasks(target_group_arn, task_definitions)
    task_attachments = task_definitions.map.with_index do |task, index|
      aws_lb_target_group_attachment(:"fargate_task_#{index}", {
        target_group_arn: target_group_arn,
        target_id: task[:private_ip],
        port: task[:container_port],
        availability_zone: task[:availability_zone]
      })
    end
    
    task_attachments
  end
  
  def self.register_ecs_instances(target_group_arn, ecs_instances)
    # ECS instances with dynamic port mapping
    instance_attachments = ecs_instances.map.with_index do |instance, index|
      aws_lb_target_group_attachment(:"ecs_instance_#{index}", {
        target_group_arn: target_group_arn,
        target_id: instance[:instance_id],
        port: instance[:dynamic_port]
      })
    end
    
    instance_attachments
  end
end
```

## High Availability Target Strategies

### Multi-AZ Target Distribution

```ruby
# Intelligent multi-AZ target distribution
class MultiAZTargetDistribution
  def self.distribute_targets(target_group_arn, targets_by_az, port)
    all_attachments = []
    
    targets_by_az.each do |az, targets|
      az_attachments = targets.map.with_index do |target, index|
        attachment_name = if target.start_with?('i-')
          # EC2 instance target
          "instance_#{az.tr('-', '_')}_#{index}"
        else
          # IP target
          "ip_#{az.tr('-', '_')}_#{index}"
        end
        
        aws_lb_target_group_attachment(attachment_name.to_sym, {
          target_group_arn: target_group_arn,
          target_id: target,
          port: port,
          availability_zone: target.start_with?('i-') ? nil : az
        })
      end
      
      all_attachments.concat(az_attachments)
    end
    
    all_attachments
  end
end

# Usage example
multi_az_targets = {
  'us-east-1a' => ['10.0.1.100', '10.0.1.101', 'i-instance1a'],
  'us-east-1b' => ['10.0.2.100', '10.0.2.101', 'i-instance1b'], 
  'us-east-1c' => ['10.0.3.100', '10.0.3.101', 'i-instance1c']
}

distributed_attachments = MultiAZTargetDistribution.distribute_targets(
  ha_target_group.arn,
  multi_az_targets,
  8080
)
```

### Cross-Region Target Management

```ruby
# Cross-region target registration for global load balancing
class GlobalTargetManager
  def self.register_regional_targets(regional_config)
    regional_attachments = {}
    
    regional_config.each do |region, config|
      region_name = region.tr('-', '_')
      
      config[:targets].each_with_index do |target, index|
        attachment_name = "#{region_name}_target_#{index}".to_sym
        
        regional_attachments[attachment_name] = aws_lb_target_group_attachment(
          attachment_name,
          {
            target_group_arn: config[:target_group_arn],
            target_id: target[:id],
            port: target[:port],
            availability_zone: target[:az]
          }
        )
      end
    end
    
    regional_attachments
  end
end

# Global deployment configuration
global_regions = {
  'us-east-1' => {
    target_group_arn: us_east_tg.arn,
    targets: [
      { id: '10.0.1.100', port: 443, az: 'us-east-1a' },
      { id: '10.0.2.100', port: 443, az: 'us-east-1b' }
    ]
  },
  'eu-west-1' => {
    target_group_arn: eu_west_tg.arn,
    targets: [
      { id: '10.1.1.100', port: 443, az: 'eu-west-1a' },
      { id: '10.1.2.100', port: 443, az: 'eu-west-1b' }
    ]
  }
}

global_attachments = GlobalTargetManager.register_regional_targets(global_regions)
```

## Serverless and Lambda Integration

### Lambda Function Target Management

```ruby
# Lambda-based API target registration
class ServerlessTargetManager
  def self.register_lambda_targets(lambda_target_group_arn, lambda_functions)
    lambda_attachments = lambda_functions.map do |function_name, function_ref|
      aws_lb_target_group_attachment(:"lambda_#{function_name}", {
        target_group_arn: lambda_target_group_arn,
        target_id: function_ref.arn
        # No port or availability_zone for Lambda targets
      })
    end
    
    lambda_attachments
  end
  
  def self.register_mixed_targets(target_group_arn, target_mix)
    # Support mixed target types in same target group
    mixed_attachments = []
    
    target_mix[:lambda_functions]&.each do |func_name, func_ref|
      mixed_attachments << aws_lb_target_group_attachment(:"lambda_#{func_name}", {
        target_group_arn: target_group_arn,
        target_id: func_ref.arn
      })
    end
    
    target_mix[:instances]&.each_with_index do |instance_id, index|
      mixed_attachments << aws_lb_target_group_attachment(:"instance_#{index}", {
        target_group_arn: target_group_arn,
        target_id: instance_id,
        port: target_mix[:instance_port]
      })
    end
    
    mixed_attachments
  end
end
```

### API Gateway Alternative Architecture

```ruby
# ALB with Lambda targets as API Gateway alternative
api_lambda_functions = {
  users_api: users_lambda_function,
  orders_api: orders_lambda_function, 
  payments_api: payments_lambda_function
}

api_lambda_attachments = ServerlessTargetManager.register_lambda_targets(
  api_lambda_target_group.arn,
  api_lambda_functions
)
```

## Blue/Green and Canary Deployment Patterns

### Blue/Green Target Management

```ruby
class BlueGreenTargetManager
  def self.setup_blue_green_targets(blue_tg_arn, green_tg_arn, deployment_config)
    blue_attachments = deployment_config[:blue_targets].map.with_index do |target, index|
      aws_lb_target_group_attachment(:"blue_target_#{index}", {
        target_group_arn: blue_tg_arn,
        target_id: target[:id],
        port: target[:port]
      })
    end
    
    green_attachments = deployment_config[:green_targets].map.with_index do |target, index|
      aws_lb_target_group_attachment(:"green_target_#{index}", {
        target_group_arn: green_tg_arn,
        target_id: target[:id], 
        port: target[:port]
      })
    end
    
    { blue: blue_attachments, green: green_attachments }
  end
  
  def self.swap_deployments(blue_attachments, green_attachments)
    # Implementation would involve updating listener rules or target group weights
    # to shift traffic from blue to green targets
  end
end
```

### Canary Deployment Target Strategy

```ruby
# Canary deployment with weighted target groups
class CanaryTargetManager
  def self.setup_canary_targets(stable_tg_arn, canary_tg_arn, canary_config)
    # Stable environment targets (90% traffic)
    stable_attachments = canary_config[:stable_targets].map.with_index do |target, index|
      aws_lb_target_group_attachment(:"stable_#{index}", {
        target_group_arn: stable_tg_arn,
        target_id: target,
        port: canary_config[:port]
      })
    end
    
    # Canary environment targets (10% traffic)  
    canary_attachments = canary_config[:canary_targets].map.with_index do |target, index|
      aws_lb_target_group_attachment(:"canary_#{index}", {
        target_group_arn: canary_tg_arn,
        target_id: target,
        port: canary_config[:port]
      })
    end
    
    { stable: stable_attachments, canary: canary_attachments }
  end
end
```

## Network Load Balancer Specialized Targets

### High-Performance TCP Target Registration

```ruby
# Network Load Balancer optimized target registration
class NetworkLoadBalancerTargets
  def self.register_tcp_targets(nlb_target_group_arn, tcp_backends, port)
    tcp_attachments = tcp_backends.map.with_index do |backend, index|
      aws_lb_target_group_attachment(:"tcp_backend_#{index}", {
        target_group_arn: nlb_target_group_arn,
        target_id: backend[:ip],
        port: port,
        availability_zone: backend[:az]
      })
    end
    
    tcp_attachments
  end
  
  def self.register_udp_targets(nlb_target_group_arn, udp_targets, port)
    udp_attachments = udp_targets.map.with_index do |target, index|
      aws_lb_target_group_attachment(:"udp_target_#{index}", {
        target_group_arn: nlb_target_group_arn,
        target_id: target,
        port: port
      })
    end
    
    udp_attachments
  end
end

# Game server UDP target registration
game_servers = ['i-game1', 'i-game2', 'i-game3']
game_attachments = NetworkLoadBalancerTargets.register_udp_targets(
  game_nlb_target_group.arn,
  game_servers,
  7777
)
```

## Security and Compliance Patterns

### Isolated Environment Target Management

```ruby
# Compliance-driven target isolation
class ComplianceTargetManager
  COMPLIANCE_ZONES = {
    pci: { network: '172.20.0.0/16', port: 443 },
    hipaa: { network: '172.21.0.0/16', port: 443 },
    sox: { network: '172.22.0.0/16', port: 443 }
  }.freeze
  
  def self.register_compliance_targets(compliance_type, target_group_arn, targets)
    zone_config = COMPLIANCE_ZONES[compliance_type]
    
    compliance_attachments = targets.map.with_index do |target, index|
      aws_lb_target_group_attachment(:"#{compliance_type}_target_#{index}", {
        target_group_arn: target_group_arn,
        target_id: target[:ip],
        port: zone_config[:port],
        availability_zone: target[:az]
      })
    end
    
    compliance_attachments
  end
end

# PCI DSS compliant targets
pci_targets = [
  { ip: '172.20.1.100', az: 'us-east-1a' },
  { ip: '172.20.2.100', az: 'us-east-1b' }
]

pci_attachments = ComplianceTargetManager.register_compliance_targets(
  :pci,
  pci_target_group.arn,
  pci_targets
)
```

## IP Address Validation Implementation

### IPv4 and IPv6 Support

```ruby
def self.valid_ip_address?(address)
  # IPv4 validation with proper range checking
  ipv4_pattern = /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/
  return true if address.match?(ipv4_pattern)
  
  # IPv6 full format
  ipv6_full = /\A([0-9a-f]{1,4}:){7}[0-9a-f]{1,4}\z/i
  return true if address.match?(ipv6_full)
  
  # IPv6 compressed formats
  ipv6_compressed = /\A([0-9a-f]{1,4}:)*::([0-9a-f]{1,4}:)*[0-9a-f]{1,4}\z/i
  return true if address.match?(ipv6_compressed)
  
  # IPv6 localhost and other special cases
  return true if address == '::1' || address == '::'
  
  false
end
```

## Error Handling and Validation

### Comprehensive Validation Scenarios

```ruby
# Target type validation examples
describe "target type validation" do
  it "requires port for EC2 instances" do
    expect {
      aws_lb_target_group_attachment(:test, {
        target_group_arn: tg.arn,
        target_id: "i-1234567890abcdef0"
        # Missing required port
      })
    }.to raise_error(/port is required for EC2 instance targets/)
  end
  
  it "requires port for IP addresses" do
    expect {
      aws_lb_target_group_attachment(:test, {
        target_group_arn: tg.arn,
        target_id: "192.168.1.100"
        # Missing required port
      })
    }.to raise_error(/port is required for IP targets/)
  end
  
  it "rejects port for Lambda functions" do
    expect {
      aws_lb_target_group_attachment(:test, {
        target_group_arn: tg.arn,
        target_id: "arn:aws:lambda:us-east-1:123456789012:function:test",
        port: 80  # Not allowed for Lambda
      })
    }.to raise_error(/port cannot be specified for Lambda targets/)
  end
  
  it "validates IP address format" do
    expect {
      aws_lb_target_group_attachment(:test, {
        target_group_arn: tg.arn,
        target_id: "999.999.999.999",  # Invalid IP
        port: 80
      })
    }.to raise_error(/must be a valid IPv4 or IPv6 address/)
  end
end
```

## Performance and Scaling Considerations

### Bulk Target Registration

```ruby
# Efficient bulk target registration
class BulkTargetRegistration
  def self.register_targets_in_batches(target_group_arn, targets, batch_size = 50)
    target_attachments = []
    
    targets.each_slice(batch_size).with_index do |batch, batch_index|
      batch_attachments = batch.map.with_index do |target, index|
        global_index = (batch_index * batch_size) + index
        
        aws_lb_target_group_attachment(:"bulk_target_#{global_index}", {
          target_group_arn: target_group_arn,
          target_id: target[:id],
          port: target[:port],
          availability_zone: target[:az]
        })
      end
      
      target_attachments.concat(batch_attachments)
    end
    
    target_attachments
  end
end
```

This implementation provides production-ready AWS Load Balancer target group attachment management with comprehensive target type support, intelligent validation, and advanced patterns for enterprise deployment scenarios.