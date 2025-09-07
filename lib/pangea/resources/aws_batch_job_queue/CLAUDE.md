# AWS Batch Job Queue Implementation

## Overview

This implementation provides a type-safe interface for AWS Batch job queues with comprehensive validation for priority management, compute environment ordering, and workload-specific configuration patterns.

## Architecture

### Type System
- **BatchJobQueueAttributes**: Main dry-struct with queue configuration validation
- **Priority Management**: Built-in priority levels and validation (0-1000 range)
- **Compute Environment Ordering**: Validation and automatic ordering of compute environments
- **Template System**: Pre-built configurations for common workload patterns

### Validation Layers

1. **Name Validation**: AWS naming requirements (1-128 chars, alphanumeric start, alphanumeric + hyphens/underscores)
2. **Priority Validation**: Range validation (0-1000) with semantic priority levels
3. **State Validation**: ENABLED vs DISABLED state validation
4. **Compute Environment Validation**: Order uniqueness and configuration validation

## Queue Priority System

### Priority Range and Semantics

AWS Batch job queues use priority values from 0-1000:
- **Higher numbers = Higher priority**
- **Jobs from higher priority queues run first**
- **Within same priority, FIFO ordering**

### Built-in Priority Levels

```ruby
def self.priority_levels
  {
    critical: 1000,     # Highest priority - real-time, critical systems
    high: 900,          # High priority - production, SLA-sensitive
    medium_high: 750,   # Above normal - important batch jobs
    medium: 500,        # Normal priority - standard processing
    medium_low: 250,    # Below normal - routine maintenance
    low: 100,           # Low priority - background tasks
    background: 1       # Lowest priority - cleanup, archival
  }
end
```

### Priority Validation

```ruby
def self.validate_priority(priority)
  if priority < 0 || priority > 1000
    raise Dry::Struct::Error, "Job queue priority must be between 0 and 1000"
  end
  
  true
end
```

## Compute Environment Ordering

### Ordering Logic

Compute environments in a job queue are tried in **ascending order**:
1. **order: 1** - First choice (primary)
2. **order: 2** - Second choice (fallback)
3. **order: 3** - Third choice (final fallback)

### Validation Rules

```ruby
def self.validate_compute_environment_order(compute_envs)
  unless compute_envs.is_a?(Array) && !compute_envs.empty?
    raise Dry::Struct::Error, "Compute environment order must be a non-empty array"
  end
  
  compute_envs.each_with_index do |env, index|
    # Must be hash with required fields
    unless env.is_a?(Hash)
      raise Dry::Struct::Error, "Compute environment order item #{index} must be a hash"
    end
    
    # Required fields validation
    unless env[:order] && env[:compute_environment]
      raise Dry::Struct::Error, "Must have 'order' and 'compute_environment' fields"
    end
    
    # Order must be non-negative integer
    unless env[:order].is_a?(Integer) && env[:order] >= 0
      raise Dry::Struct::Error, "Order must be a non-negative integer"
    end
  end
  
  # Validate unique orders
  orders = compute_envs.map { |env| env[:order] }
  if orders.uniq.length != orders.length
    raise Dry::Struct::Error, "Compute environment orders must be unique"
  end
  
  true
end
```

### Common Ordering Patterns

**Cost Optimization Pattern**:
```ruby
# Try cheapest first, fallback to more expensive
[
  { order: 1, compute_environment: spot_env.arn },      # Cheapest
  { order: 2, compute_environment: ec2_env.arn },       # Moderate
  { order: 3, compute_environment: fargate_env.arn }    # Most expensive
]
```

**Availability Pattern**:
```ruby
# Try most available first
[
  { order: 1, compute_environment: large_capacity_env.arn },    # Most capacity
  { order: 2, compute_environment: medium_capacity_env.arn },   # Fallback
  { order: 3, compute_environment: small_capacity_env.arn }     # Emergency
]
```

**Performance Pattern**:
```ruby
# Try highest performance first
[
  { order: 1, compute_environment: gpu_env.arn },        # GPU for ML
  { order: 2, compute_environment: cpu_optimized_env.arn }, # CPU fallback
  { order: 3, compute_environment: general_env.arn }     # General fallback
]
```

## Template System Architecture

### Template Categories

**Priority-Based Templates**:
- `high_priority_queue`: Critical workloads (priority 900)
- `medium_priority_queue`: Standard workloads (priority 500)  
- `low_priority_queue`: Background workloads (priority 100)

**Workload-Specific Templates**:
- `data_processing_queue`: Data pipeline jobs (configurable priority)
- `ml_training_queue`: Machine learning workloads (high priority)
- `batch_processing_queue`: Background batch jobs (low priority)
- `real_time_queue`: Real-time processing (critical priority)

**Environment-Based Templates**:
- `environment_queue_set`: Multi-environment queue generation

### Template Implementation Pattern

```ruby
def self.high_priority_queue(name, compute_environments, options = {})
  {
    name: name,
    state: options[:state] || "ENABLED",
    priority: options[:priority] || 900,
    compute_environment_order: build_compute_environment_order(compute_environments),
    tags: (options[:tags] || {}).merge(Priority: "high")
  }
end
```

### Compute Environment Order Builder

```ruby
def self.build_compute_environment_order(compute_environments)
  case compute_environments
  when String
    # Single compute environment
    [{ order: 1, compute_environment: compute_environments }]
  when Array
    if compute_environments.first.is_a?(String)
      # Array of compute environment names - auto-assign orders
      compute_environments.map.with_index do |env, index|
        { order: index + 1, compute_environment: env }
      end
    else
      # Array of compute environment configs - use as-is
      compute_environments
    end
  when Hash
    # Single compute environment config
    [compute_environments]
  else
    raise Dry::Struct::Error, "Invalid compute environment configuration"
  end
end
```

## Workload-Specific Configuration

### Data Processing Workloads

```ruby
def self.data_processing_queue(name, compute_environments, priority = :medium, options = {})
  {
    name: name,
    state: "ENABLED",
    priority: priority_levels[priority] || priority,
    compute_environment_order: build_compute_environment_order(compute_environments),
    tags: (options[:tags] || {}).merge(
      Workload: "data-processing",
      Type: "batch",
      Priority: priority.to_s
    )
  }
end
```

**Characteristics**:
- Usually medium priority (500)
- Can tolerate some latency
- Cost-optimization friendly (Spot instances)
- Predictable resource usage

### ML Training Workloads

```ruby
def self.ml_training_queue(name, compute_environments, options = {})
  {
    name: name,
    state: "ENABLED",
    priority: options[:priority] || priority_levels[:high], # Default high priority
    compute_environment_order: build_compute_environment_order(compute_environments),
    tags: (options[:tags] || {}).merge(
      Workload: "ml-training",
      Type: "gpu-intensive",
      Priority: "high"
    )
  }
end
```

**Characteristics**:
- High priority (900) by default
- GPU-intensive workloads
- Expensive compute resources
- Time-sensitive training jobs

### Real-Time Processing

```ruby
def self.real_time_queue(name, compute_environments, options = {})
  {
    name: name,
    state: "ENABLED", 
    priority: options[:priority] || priority_levels[:critical], # Critical priority
    compute_environment_order: build_compute_environment_order(compute_environments),
    tags: (options[:tags] || {}).merge(
      Workload: "real-time",
      Type: "latency-sensitive",
      Priority: "critical"
    )
  }
end
```

**Characteristics**:
- Critical priority (1000)
- Latency-sensitive
- Always-on compute capacity
- High availability requirements

## Multi-Environment Management

### Environment Queue Set

```ruby
def self.environment_queue_set(base_name, compute_environments_by_env, options = {})
  environments = %i[production staging development]
  priorities = {
    production: :high,      # 900
    staging: :medium,       # 500  
    development: :low       # 100
  }
  
  queues = {}
  
  environments.each do |env|
    next unless compute_environments_by_env[env]
    
    queue_name = "#{env}-#{base_name}-queue"
    priority = priorities[env]
    
    queues[env] = {
      name: queue_name,
      state: "ENABLED",
      priority: priority_levels[priority],
      compute_environment_order: build_compute_environment_order(
        compute_environments_by_env[env]
      ),
      tags: (options[:tags] || {}).merge(
        Environment: env.to_s,
        Priority: priority.to_s,
        Workload: base_name
      )
    }
  end
  
  queues
end
```

### Usage Pattern

```ruby
# Input: compute environments per environment
compute_environments = {
  production: [prod_primary_env.arn, prod_fallback_env.arn],
  staging: [staging_env.arn],
  development: [dev_env.arn]
}

# Generate queue configurations
queue_configs = Types::BatchJobQueueAttributes.environment_queue_set(
  "data-processing",
  compute_environments
)

# Deploy each environment's queue
queue_configs.each do |env, config|
  aws_batch_job_queue(:"#{env}_data_processing", config)
end
```

## Queue State Management

### State Validation

```ruby
# Only ENABLED and DISABLED states are valid
if attrs[:state] && !%w[ENABLED DISABLED].include?(attrs[:state])
  raise Dry::Struct::Error, "Job queue state must be 'ENABLED' or 'DISABLED'"
end
```

### State Semantics

**ENABLED**:
- Queue accepts new job submissions
- Jobs are scheduled and executed normally
- Standard operational state

**DISABLED**:
- Queue does not accept new job submissions
- Existing jobs continue running to completion
- Used for maintenance or gradual decommissioning

### State Management Patterns

**Maintenance Mode**:
```ruby
# Disable queue for maintenance
aws_batch_job_queue(:maintenance_queue, {
  name: "processing-queue",
  state: "DISABLED",  # No new jobs
  priority: 500,
  # ... other config
})
```

**Conditional States**:
```ruby
# Environment-dependent state
queue_state = environment == "production" ? "ENABLED" : "DISABLED"

aws_batch_job_queue(:env_dependent_queue, {
  name: "environment-dependent-queue",
  state: queue_state,
  # ... other config
})
```

## Naming Convention System

### Naming Pattern Functions

```ruby
def self.queue_naming_patterns
  {
    production: ->(workload) { "prod-#{workload}-queue" },
    staging: ->(workload) { "staging-#{workload}-queue" },
    development: ->(workload) { "dev-#{workload}-queue" },
    priority_based: ->(priority, workload) { "#{priority}-priority-#{workload}-queue" },
    team_based: ->(team, workload) { "#{team}-#{workload}-queue" },
    environment_based: ->(env, priority, workload) { "#{env}-#{priority}-#{workload}-queue" }
  }
end
```

### Naming Best Practices

**Consistent Structure**:
- `{environment}-{workload}-{type}` - Standard pattern
- `{priority}-{workload}-queue` - Priority-based pattern
- `{team}-{workload}-queue` - Team-based pattern

**Examples**:
```ruby
"prod-ml-training-queue"              # Production ML training
"staging-data-processing-queue"       # Staging data processing
"high-priority-realtime-queue"        # High priority real-time
"data-eng-etl-queue"                  # Data engineering ETL
"dev-critical-image-processing-queue" # Development critical image processing
```

## Performance Optimization

### Priority Strategy

**Workload Classification**:
- **Critical (1000)**: Real-time, customer-facing, SLA-critical
- **High (900)**: Production batch, ML training, important processing
- **Medium (500)**: Standard data processing, regular ETL
- **Low (100)**: Background tasks, cleanup, archival
- **Background (1)**: Lowest priority maintenance tasks

**Queue Specialization**:
- Separate queues for different workload types
- Dedicated compute environments per workload
- Optimized priority assignment per business impact

### Compute Environment Strategy

**Cost Optimization Order**:
1. **Spot Instances** (order: 1) - 70%+ cost savings
2. **On-Demand Instances** (order: 2) - Predictable capacity
3. **Fargate** (order: 3) - Serverless, highest cost per vCPU

**Performance Optimization Order**:
1. **Dedicated Instances** (order: 1) - Best performance
2. **Burstable Instances** (order: 2) - Good for variable workloads  
3. **Shared Resources** (order: 3) - Economic fallback

**Availability Optimization Order**:
1. **Multi-AZ Primary** (order: 1) - High availability
2. **Single-AZ Secondary** (order: 2) - Lower cost fallback
3. **Cross-Region** (order: 3) - Disaster recovery

## Monitoring and Observability

### Queue Metrics

AWS Batch automatically provides metrics:
- `SubmittedJobs`: Jobs submitted to queue
- `RunnableJobs`: Jobs waiting for compute capacity
- `RunningJobs`: Jobs currently executing
- `CompletedJobs`: Successfully completed jobs
- `FailedJobs`: Jobs that failed execution

### Custom Monitoring Tags

```ruby
{
  tags: {
    # Cost allocation
    Team: "data-engineering",
    CostCenter: "engineering", 
    Project: "ml-platform",
    
    # Operations
    Environment: "production",
    Monitoring: "enabled",
    Alerting: "critical",
    
    # Business context
    SLA: "4-hour",
    BusinessUnit: "analytics",
    Priority: "high",
    
    # Technical context
    Workload: "ml-training",
    ComputeType: "gpu",
    ScalingProfile: "elastic"
  }
}
```

### Queue Health Monitoring

**Key Metrics to Monitor**:
- Queue depth (RunnableJobs metric)
- Average time in queue
- Job success/failure rates
- Compute environment utilization

**Alerting Patterns**:
- High queue depth indicates capacity constraints
- High failure rates indicate configuration issues
- Long queue times indicate performance problems

## Security Considerations

### IAM Integration

Job queues don't directly require IAM roles, but they integrate with:
- **Compute Environment Roles**: For EC2 instance permissions
- **Job Definition Roles**: For job execution permissions
- **Service Roles**: For Batch service operations

### Network Security

Queues themselves are logical constructs, but they schedule jobs on:
- **Compute Environments**: Must have proper security group configuration
- **VPC Integration**: Jobs run in specified VPC/subnets
- **Resource Access**: Jobs need appropriate resource permissions

## Error Handling

### Validation Error Examples

**Name Validation Errors**:
```ruby
# Invalid starting character
"_invalid-queue-name"
# Error: "Job queue name must start with an alphanumeric character"

# Too long
"this-queue-name-is-way-too-long-for-aws-batch-and-exceeds-the-128-character-limit-that-is-enforced-by-the-service"
# Error: "Job queue name must be between 1 and 128 characters"
```

**Priority Validation Errors**:
```ruby
# Out of range
{ priority: 1500 }
# Error: "Job queue priority must be between 0 and 1000"

{ priority: -10 }
# Error: "Job queue priority must be between 0 and 1000"
```

**Compute Environment Order Errors**:
```ruby
# Duplicate orders
[
  { order: 1, compute_environment: "env1" },
  { order: 1, compute_environment: "env2" }  # Duplicate order
]
# Error: "Compute environment orders must be unique"

# Missing required fields
[
  { order: 1 }  # Missing compute_environment
]
# Error: "Must have 'order' and 'compute_environment' fields"
```

### Debugging Strategies

**Configuration Testing**:
```ruby
begin
  config = Types::BatchJobQueueAttributes.new(attributes)
  puts "Queue configuration valid: #{config.name}"
  puts "Priority level: #{config.high_priority? ? 'High' : 'Normal'}"
rescue Dry::Struct::Error => e
  puts "Configuration error: #{e.message}"
end
```

**Queue Analysis**:
```ruby
# Analyze queue configuration
config = Types::BatchJobQueueAttributes.new(attributes)

puts "Queue: #{config.name}"
puts "State: #{config.is_enabled? ? 'Active' : 'Disabled'}"
puts "Priority: #{config.priority} (#{priority_level(config.priority)})"
puts "Compute environments: #{config.compute_environment_count}"
puts "Primary compute env: #{config.primary_compute_environment[:compute_environment]}"

def priority_level(priority)
  case priority
  when 900..1000 then "High"
  when 500..899 then "Medium"  
  when 100..499 then "Low"
  else "Background"
  end
end
```