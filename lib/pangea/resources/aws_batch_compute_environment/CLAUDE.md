# AWS Batch Compute Environment Implementation

## Overview

This implementation provides a type-safe interface for AWS Batch compute environments with comprehensive validation for all supported compute types (EC2, Spot, Fargate, Fargate Spot) and configuration patterns.

## Architecture

### Type System
- **BatchComputeEnvironmentAttributes**: Main dry-struct with compute environment validation
- **Compute Resource Validation**: Type-specific validation for different compute types
- **Configuration Templates**: Pre-built templates for common deployment patterns
- **Instance Type Helpers**: Predefined instance type groups for different workload types

### Validation Layers

1. **Name Validation**: AWS naming requirements (1-128 chars, alphanumeric + hyphens/underscores)
2. **Type Validation**: MANAGED vs UNMANAGED environment types
3. **Compute Resource Validation**: Type-specific validation for EC2, Spot, Fargate
4. **Capacity Validation**: vCPU limits and allocation validation
5. **Networking Validation**: VPC, subnet, and security group requirements

## Compute Environment Types

### MANAGED vs UNMANAGED

**MANAGED Environments**:
- AWS manages the compute resources automatically
- Supports EC2, Spot, Fargate, and Fargate Spot
- Requires compute_resources configuration
- Automatic scaling based on job queue demand

**UNMANAGED Environments**:
- You manage the compute resources manually
- Typically used with existing ECS clusters
- Cannot have compute_resources configuration
- Manual capacity management required

### Compute Resource Types

**EC2**:
- On-demand EC2 instances
- Full control over instance types and configuration
- Supports launch templates and custom AMIs
- Best for consistent, predictable workloads

**SPOT**:
- EC2 Spot instances for cost optimization
- Requires spot_iam_fleet_request_role
- Supports bid_percentage configuration
- Best for fault-tolerant, flexible workloads

**FARGATE**:
- Serverless container compute
- No instance management required
- Pay per task execution
- Best for event-driven and variable workloads

**FARGATE_SPOT**:
- Spot pricing for Fargate tasks
- Up to 70% cost savings vs regular Fargate
- May be interrupted with 2-minute notice
- Best for fault-tolerant serverless workloads

## Validation Implementation

### Name Validation
```ruby
def self.validate_compute_environment_name(name)
  # Length validation
  if name.length < 1 || name.length > 128
    raise Dry::Struct::Error, "Compute environment name must be between 1 and 128 characters"
  end
  
  # Character validation
  unless name.match?(/^[a-zA-Z0-9\-_]+$/)
    raise Dry::Struct::Error, "Compute environment name can only contain letters, numbers, hyphens, and underscores"
  end
  
  true
end
```

### Compute Resources Validation
```ruby
def self.validate_compute_resources(resources)
  # Type validation
  if resources[:type] && !%w[EC2 SPOT FARGATE FARGATE_SPOT].include?(resources[:type])
    raise Dry::Struct::Error, "Compute resource type must be one of: EC2, SPOT, FARGATE, FARGATE_SPOT"
  end
  
  # Allocation strategy validation per type
  if resources[:allocation_strategy]
    valid_strategies = case resources[:type]
    when "EC2", "SPOT"
      %w[BEST_FIT BEST_FIT_PROGRESSIVE SPOT_CAPACITY_OPTIMIZED]
    when "FARGATE", "FARGATE_SPOT"
      ["SPOT_CAPACITY_OPTIMIZED"]
    end
    
    unless valid_strategies.include?(resources[:allocation_strategy])
      raise Dry::Struct::Error, "Invalid allocation strategy for type #{resources[:type]}"
    end
  end
  
  # vCPU validation
  if resources[:min_vcpus] && resources[:max_vcpus] && resources[:min_vcpus] > resources[:max_vcpus]
    raise Dry::Struct::Error, "min_vcpus cannot be greater than max_vcpus"
  end
  
  # Spot-specific validation
  if resources[:type] == "SPOT" && resources[:spot_iam_fleet_request_role].nil?
    raise Dry::Struct::Error, "SPOT compute resources require spot_iam_fleet_request_role"
  end
  
  true
end
```

### Instance Type Validation
```ruby
def self.validate_instance_types(instance_types)
  return true if instance_types == ["optimal"]
  
  unless instance_types.is_a?(Array) && instance_types.all? { |type| type.is_a?(String) }
    raise Dry::Struct::Error, "Instance types must be an array of strings"
  end
  
  # Basic EC2 instance type format validation
  instance_types.each do |type|
    unless type.match?(/^[a-z0-9]+\.[a-z0-9]+$/) || type == "optimal"
      raise Dry::Struct::Error, "Invalid instance type format: #{type}"
    end
  end
  
  true
end
```

## Configuration Templates

### Template Architecture

Templates provide pre-built configurations for common scenarios:

```ruby
def self.ec2_managed_environment(name, vpc_config, options = {})
  {
    compute_environment_name: name,
    type: "MANAGED",
    state: "ENABLED",
    compute_resources: {
      type: "EC2",
      allocation_strategy: "BEST_FIT_PROGRESSIVE",
      min_vcpus: options[:min_vcpus] || 0,
      max_vcpus: options[:max_vcpus] || 100,
      desired_vcpus: options[:desired_vcpus] || 0,
      instance_types: options[:instance_types] || ["optimal"],
      subnets: vpc_config[:subnets],
      security_group_ids: vpc_config[:security_group_ids],
      instance_role: options[:instance_role],
      tags: options[:tags] || {}
    }
  }
end
```

### Template Categories

**EC2 Template**:
- Standard on-demand EC2 instances
- BEST_FIT_PROGRESSIVE allocation strategy
- Configurable vCPU limits and instance types
- Full customization support

**Spot Template**:
- Cost-optimized Spot instances
- SPOT_CAPACITY_OPTIMIZED allocation strategy
- Requires spot_iam_fleet_request_role
- Configurable bid percentage

**Fargate Template**:
- Serverless container compute
- No min/desired vCPU configuration
- Platform capabilities set to ["FARGATE"]
- Private subnet requirement

**Fargate Spot Template**:
- Cost-optimized serverless compute
- Up to 70% cost savings
- Interruption-tolerant workloads
- Same configuration as Fargate with FARGATE_SPOT type

## Instance Type Management

### Pre-defined Instance Groups

```ruby
def self.compute_optimized_instances
  %w[c4.large c4.xlarge c4.2xlarge c4.4xlarge c4.8xlarge
     c5.large c5.xlarge c5.2xlarge c5.4xlarge c5.9xlarge c5.12xlarge c5.18xlarge c5.24xlarge
     c5n.large c5n.xlarge c5n.2xlarge c5n.4xlarge c5n.9xlarge c5n.18xlarge
     c6i.large c6i.xlarge c6i.2xlarge c6i.4xlarge c6i.8xlarge c6i.12xlarge c6i.16xlarge c6i.24xlarge c6i.32xlarge]
end

def self.memory_optimized_instances
  %w[r4.large r4.xlarge r4.2xlarge r4.4xlarge r4.8xlarge r4.16xlarge
     r5.large r5.xlarge r5.2xlarge r5.4xlarge r5.8xlarge r5.12xlarge r5.16xlarge r5.24xlarge
     r5a.large r5a.xlarge r5a.2xlarge r5a.4xlarge r5a.8xlarge r5a.12xlarge r5a.16xlarge r5a.24xlarge
     r6i.large r6i.xlarge r6i.2xlarge r6i.4xlarge r6i.8xlarge r6i.12xlarge r6i.16xlarge r6i.24xlarge r6i.32xlarge]
end

def self.gpu_instances
  %w[p2.xlarge p2.8xlarge p2.16xlarge
     p3.2xlarge p3.8xlarge p3.16xlarge
     p3dn.24xlarge
     g3.4xlarge g3.8xlarge g3.16xlarge
     g4dn.xlarge g4dn.2xlarge g4dn.4xlarge g4dn.8xlarge g4dn.12xlarge g4dn.16xlarge]
end
```

### Instance Selection Strategies

**"optimal" Selection**:
- AWS automatically selects best instance types
- Based on current availability and pricing
- Balances performance and cost
- Recommended for most workloads

**Specific Instance Types**:
- Explicit instance type specification
- Better cost predictability
- Required for specific hardware requirements
- More control over performance characteristics

**Instance Family Selection**:
- Use predefined groups for workload optimization
- Compute optimized for CPU-intensive tasks
- Memory optimized for in-memory processing
- GPU instances for machine learning/graphics

## Allocation Strategies

### EC2 Allocation Strategies

**BEST_FIT**:
- Selects instance types with least available capacity
- Minimizes the number of running instances
- Better for consistent workloads
- Lower infrastructure overhead

**BEST_FIT_PROGRESSIVE**:
- Uses additional instance types if BEST_FIT types unavailable
- Better availability during capacity constraints
- Recommended for most production workloads
- Balances efficiency and availability

### Spot Allocation Strategies

**SPOT_CAPACITY_OPTIMIZED**:
- Selects instance types with highest available capacity
- Reduces interruption risk
- Better for large-scale batch processing
- Recommended for all Spot workloads

## Fargate Configuration Patterns

### Fargate Compute Resources

```ruby
# Fargate configuration
{
  type: "FARGATE",
  max_vcpus: 100,                    # Only max_vcpus for Fargate
  subnets: [private_subnet.id],      # Private subnets recommended
  security_group_ids: [sg.id],
  platform_capabilities: ["FARGATE"], # Required for Fargate
  tags: {}
}
```

### Fargate Spot Configuration

```ruby
# Fargate Spot configuration
{
  type: "FARGATE_SPOT",
  max_vcpus: 200,                    # Higher limits for Spot
  subnets: [private_subnet.id],
  security_group_ids: [sg.id],
  platform_capabilities: ["FARGATE"],
  tags: { SpotEnabled: "true" }
}
```

### Fargate Networking Requirements

**Private Subnets**:
- Required for outbound internet access via NAT Gateway
- Better security posture
- Standard configuration for production

**Security Groups**:
- Allow outbound HTTPS (443) for container registry access
- Allow outbound HTTP (80) for package downloads
- Restrict inbound access as needed

## Launch Template Integration

### Launch Template Configuration

```ruby
# Launch template for custom configuration
{
  launch_template: {
    launch_template_id: template.id,      # Or launch_template_name
    version: "$Latest"                    # Or specific version number
  }
}
```

### Common Launch Template Use Cases

**Custom AMI**:
- Pre-installed software and dependencies
- Faster job startup times
- Consistent runtime environment
- Security hardening

**Instance Configuration**:
- Custom instance metadata options
- Additional EBS volumes
- Network interface configuration
- Monitoring agent installation

**User Data Scripts**:
- Runtime environment setup
- Software installation
- Configuration management
- Secret retrieval

## Resource Lifecycle Management

### Compute Environment States

**ENABLED**:
- Can accept new job submissions
- Actively scales based on demand
- Standard operational state

**DISABLED**:
- No new job submissions accepted
- Existing jobs continue running
- Useful for maintenance or decommissioning

### Scaling Behavior

**Auto Scaling**:
- Automatically scales based on job queue demand
- Respects min/max vCPU limits
- Terminates idle instances to minimize cost

**Desired Capacity**:
- Maintains minimum running capacity
- Useful for consistent latency requirements
- Higher cost due to always-on capacity

## Error Handling and Validation

### Common Validation Errors

**Name Validation Errors**:
```ruby
# Too long
"This-name-is-way-too-long-for-a-compute-environment-name-and-will-exceed-the-128-character-limit-that-AWS-enforces"
# Error: "Compute environment name must be between 1 and 128 characters"

# Invalid characters
"invalid@name!"  
# Error: "Compute environment name can only contain letters, numbers, hyphens, and underscores"
```

**Type Configuration Errors**:
```ruby
# UNMANAGED with compute resources
{
  type: "UNMANAGED",
  compute_resources: { type: "EC2" }  # Invalid
}
# Error: "UNMANAGED compute environments cannot have compute_resources"

# Invalid compute resource type
{
  type: "MANAGED",
  compute_resources: { type: "INVALID" }
}
# Error: "Compute resource type must be one of: EC2, SPOT, FARGATE, FARGATE_SPOT"
```

**Capacity Validation Errors**:
```ruby
# min > max
{
  compute_resources: {
    min_vcpus: 100,
    max_vcpus: 50
  }
}
# Error: "min_vcpus cannot be greater than max_vcpus"

# Spot without IAM role
{
  compute_resources: {
    type: "SPOT"
    # Missing spot_iam_fleet_request_role
  }
}
# Error: "SPOT compute resources require spot_iam_fleet_request_role"
```

### Debugging Strategies

**Validation Testing**:
```ruby
# Test configuration before deployment
begin
  config = Types::BatchComputeEnvironmentAttributes.new(attributes)
  puts "Configuration valid: #{config.compute_environment_name}"
rescue Dry::Struct::Error => e
  puts "Validation error: #{e.message}"
end
```

**Resource Inspection**:
```ruby
# Check computed properties
config = Types::BatchComputeEnvironmentAttributes.new(attributes)
puts "Is managed: #{config.is_managed?}"
puts "Supports Fargate: #{config.supports_fargate?}"
puts "Is spot-based: #{config.is_spot_based?}"
```

## Security Considerations

### IAM Role Requirements

**Instance Role** (for EC2/Spot):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceAttribute",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeSpotInstanceRequests"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow", 
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*"
      ],
      "Resource": "*"
    }
  ]
}
```

**Spot Fleet Role** (for SPOT):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeImages",
        "ec2:DescribeSubnets", 
        "ec2:RequestSpotInstances",
        "ec2:TerminateInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:CreateTags"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::*:role/aws-ec2-spot-fleet-tagging-role"
    }
  ]
}
```

### Network Security

**Security Group Configuration**:
```ruby
# Minimal security group for batch compute
aws_security_group(:batch_compute_sg, {
  name: "batch-compute-security-group",
  vpc_id: vpc.id,
  
  # Allow all outbound traffic
  egress: [{
    from_port: 0,
    to_port: 0,
    protocol: "-1",
    cidr_blocks: ["0.0.0.0/0"]
  }],
  
  # No inbound rules needed for batch compute
  # Jobs communicate through Batch service
})
```

**VPC Endpoint Usage**:
For enhanced security and reduced data transfer costs, consider VPC endpoints for:
- Amazon ECR (container registry)
- Amazon S3 (data storage)
- Amazon CloudWatch (logging/metrics)

## Performance Optimization

### Scaling Strategies

**Fast Scale-Up**:
```ruby
{
  min_vcpus: 10,          # Always-on capacity
  max_vcpus: 1000,        # High ceiling
  desired_vcpus: 50,      # Consistent baseline
  allocation_strategy: "BEST_FIT_PROGRESSIVE"
}
```

**Cost-Optimized**:
```ruby
{
  min_vcpus: 0,           # No always-on costs
  max_vcpus: 500,         # Reasonable ceiling
  desired_vcpus: 0,       # Scale to zero when idle
  allocation_strategy: "SPOT_CAPACITY_OPTIMIZED"  # For Spot
}
```

### Instance Type Optimization

**Workload-Specific Selection**:
- CPU-intensive: Use compute optimized instances
- Memory-intensive: Use memory optimized instances  
- Mixed workloads: Use "optimal" selection
- GPU workloads: Use GPU instance types

**Multi-Instance Type Strategy**:
```ruby
# Use multiple compatible instance types
instance_types: ["m5.large", "m5.xlarge", "m4.large", "m4.xlarge"]
```

This increases availability and can reduce costs through better instance market selection.