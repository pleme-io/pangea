# Spot Instance Carbon Optimizer Component

Intelligent spot instance management that optimizes for both carbon emissions and cost by dynamically distributing workloads across regions based on real-time grid carbon intensity and renewable energy availability.

## Overview

The Spot Instance Carbon Optimizer revolutionizes cloud computing sustainability by combining AWS Spot Instance cost savings with carbon-aware scheduling. It automatically migrates workloads to regions with cleaner energy grids while leveraging spot capacity, achieving both environmental and economic benefits.

## Key Features

- **Multi-Region Spot Fleets**: Manages spot instances across multiple AWS regions
- **Real-Time Carbon Tracking**: Monitors grid carbon intensity every 5 minutes
- **Dynamic Workload Migration**: Moves workloads to cleaner regions automatically
- **Renewable Energy Preference**: Prioritizes regions with high renewable energy
- **Cost Optimization**: Leverages spot pricing for 70-90% cost savings
- **Multiple Migration Strategies**: Checkpoint/restore, blue-green, live migration
- **Follow-the-Sun**: Tracks renewable energy availability by timezone
- **Comprehensive Monitoring**: Carbon footprint and efficiency dashboards

## Usage

```ruby
spot_optimizer = Pangea::Components::SpotInstanceCarbonOptimizer.build(
  name: "green-compute-fleet",
  target_capacity: 20,
  workload_type: "batch",
  instance_types: ["t3.large", "t3a.large", "t4g.large"],
  
  # Carbon optimization
  optimization_strategy: "balanced",
  carbon_intensity_threshold: 200,
  renewable_percentage_minimum: 50,
  
  # Regional configuration
  allowed_regions: [
    "us-west-2",    # Oregon - hydro
    "eu-north-1",   # Stockholm - renewable
    "ca-central-1", # Montreal - hydro
    "us-east-1",    # Virginia - mixed
    "eu-west-1"     # Ireland - wind
  ],
  preferred_regions: ["us-west-2", "eu-north-1", "ca-central-1"],
  
  # Migration settings
  enable_cross_region_migration: true,
  migration_strategy: "checkpoint_restore",
  migration_threshold_minutes: 5,
  
  # VPC configuration per region
  vpc_configs: {
    "us-west-2" => { 
      vpc_id: "vpc-12345", 
      subnet_ids: "subnet-1a,subnet-1b" 
    },
    "eu-north-1" => { 
      vpc_id: "vpc-67890", 
      subnet_ids: "subnet-2a,subnet-2b" 
    }
  },
  
  tags: {
    "Environment" => "production",
    "CarbonOptimized" => "true"
  }
)

# Access outputs
puts spot_optimizer.active_regions
puts spot_optimizer.dashboard_url
```

## Optimization Strategies

### Carbon First
Aggressively optimizes for lowest carbon emissions, placing all workloads in the cleanest regions regardless of cost.

```ruby
optimization_strategy: "carbon_first"
```

### Cost First
Prioritizes lowest spot prices while respecting carbon thresholds.

```ruby
optimization_strategy: "cost_first"
carbon_intensity_threshold: 300  # More lenient threshold
```

### Balanced (Default)
Optimizes for both carbon and cost with configurable weights.

```ruby
optimization_strategy: "balanced"
```

### Renewable Only
Only runs workloads in regions with >70% renewable energy.

```ruby
optimization_strategy: "renewable_only"
```

### Follow the Sun
Migrates workloads to follow peak renewable energy generation times.

```ruby
optimization_strategy: "follow_the_sun"
```

## Regional Carbon Intensity

Default carbon intensity by region (gCO2/kWh):

| Region | Carbon Intensity | Primary Energy Source |
|--------|-----------------|----------------------|
| ca-central-1 | 30 | Hydroelectric (99%) |
| eu-north-1 | 40 | Renewable Mix (95%) |
| us-west-2 | 50 | Hydroelectric (80%) |
| eu-west-1 | 80 | Wind + Natural Gas |
| us-west-1 | 250 | Mixed Grid |
| eu-central-1 | 350 | Mixed Grid |
| us-east-1 | 400 | Coal + Natural Gas |
| ap-southeast-1 | 600 | Natural Gas |
| ap-southeast-2 | 700 | Coal Heavy |

## Workload Types

### Stateless
Best for carbon optimization - can migrate anytime without state concerns.

```ruby
workload_type: "stateless"
migration_strategy: "blue_green"
```

### Batch
Supports checkpoint/restore for long-running jobs.

```ruby
workload_type: "batch"
migration_strategy: "checkpoint_restore"
```

### Distributed
Multi-region capable workloads that can span regions.

```ruby
workload_type: "distributed"
enable_cross_region_migration: true
```

### GPU Compute
ML/AI workloads requiring GPU instances.

```ruby
workload_type: "gpu_compute"
instance_types: ["p3.2xlarge", "g4dn.xlarge"]
require_gpu: true
```

## Migration Strategies

### Checkpoint/Restore
Saves instance state, migrates, and restores in new region.

- Best for: Batch jobs, fault-tolerant workloads
- Downtime: 2-5 minutes
- Data consistency: Guaranteed

### Blue-Green
Launches new instances before terminating old ones.

- Best for: Web services, APIs
- Downtime: Zero
- Cost: Temporarily double capacity

### Drain and Shift
Gracefully drains connections before migration.

- Best for: Stateful services
- Downtime: Minimal
- Complexity: Medium

### Live Migration
Attempts to migrate running instances (experimental).

- Best for: Critical services
- Downtime: Near-zero
- Complexity: High

## Example: Carbon-Optimized Web Service

```ruby
web_fleet = Pangea::Components::SpotInstanceCarbonOptimizer.build(
  name: "web-app-fleet",
  target_capacity: 50,
  workload_type: "stateless",
  instance_types: ["t4g.medium", "t4g.large"],  # Graviton for efficiency
  
  optimization_strategy: "balanced",
  carbon_intensity_threshold: 150,
  
  # Quick migrations for web traffic
  migration_strategy: "blue_green",
  migration_threshold_minutes: 2,
  
  # Web-optimized settings
  network_performance: "high",
  spot_price_buffer_percentage: 30,  # Higher buffer for stability
  
  vpc_configs: {
    "us-west-2" => { vpc_id: "vpc-web-west", subnet_ids: "subnet-1a,subnet-1b,subnet-1c" },
    "eu-north-1" => { vpc_id: "vpc-web-eu", subnet_ids: "subnet-2a,subnet-2b,subnet-2c" },
    "ca-central-1" => { vpc_id: "vpc-web-ca", subnet_ids: "subnet-3a,subnet-3b" }
  }
)
```

## Example: ML Training Fleet

```ruby
ml_fleet = Pangea::Components::SpotInstanceCarbonOptimizer.build(
  name: "ml-training-fleet",
  target_capacity: 10,
  workload_type: "gpu_compute",
  instance_types: ["p3.2xlarge", "p3.8xlarge"],
  
  # ML can be flexible with timing
  optimization_strategy: "carbon_first",
  carbon_intensity_threshold: 100,
  
  # Checkpoint for long training runs
  migration_strategy: "checkpoint_restore",
  migration_threshold_minutes: 10,
  
  # GPU requirements
  require_gpu: true,
  min_memory_gb: 64,
  ephemeral_storage_gb: 1000,
  
  # Use spot blocks for predictable training windows
  use_spot_blocks: true,
  spot_block_duration_hours: 6
)
```

## Monitoring and Metrics

### Carbon Metrics
- **Regional Carbon Intensity**: Real-time gCO2/kWh by region
- **Carbon Emissions Avoided**: Compared to baseline region
- **Renewable Energy Usage**: Percentage of clean energy
- **Carbon Efficiency Score**: Optimization effectiveness

### Operational Metrics
- **Fleet Capacity**: Instances by region
- **Migration Frequency**: Workload movements
- **Spot Savings**: Cost reduction achieved
- **Availability**: Uptime across regions

### Dashboard Widgets
1. Regional carbon intensity heatmap
2. Fleet distribution pie chart
3. Carbon savings accumulator
4. Migration activity timeline
5. Cost optimization tracker

## Cost Optimization

Typical savings achieved:

| Strategy | Spot Savings | Carbon Reduction | Total Savings |
|----------|--------------|------------------|---------------|
| Carbon First | 70% | 85% | High environmental value |
| Balanced | 80% | 65% | Best overall value |
| Cost First | 90% | 40% | Maximum cost savings |
| Renewable Only | 60% | 90% | Maximum sustainability |

## Best Practices

1. **Start Small**: Begin with non-critical workloads
2. **Monitor Migrations**: Review migration frequency and success
3. **Set Appropriate Buffers**: Higher buffers for critical workloads
4. **Use Multiple Instance Types**: Increases spot availability
5. **Enable Monitoring**: Track both carbon and cost metrics
6. **Test Migration Strategies**: Ensure workloads handle migrations
7. **Configure VPCs**: Ensure networking in all target regions

## Integration Examples

### With Auto Scaling

```ruby
# Combine with ASG for dynamic capacity
asg = aws_autoscaling_group(:web_asg, {
  min_size: 0,
  max_size: 100,
  mixed_instances_policy: {
    spot_allocation_strategy: "capacity-optimized",
    spot_instance_pools: 4
  }
})
```

### With Container Orchestration

```ruby
# ECS/EKS integration
ecs_cluster = aws_ecs_cluster(:green_cluster, {
  capacity_providers: ["FARGATE_SPOT"],
  default_capacity_provider_strategy: [{
    capacity_provider: "FARGATE_SPOT",
    weight: 100
  }]
})
```

## Troubleshooting

### High Migration Frequency
- Increase migration threshold minutes
- Use more stable optimization strategy
- Check carbon data volatility

### Spot Capacity Issues
- Add more instance types
- Increase allowed regions
- Adjust spot price buffer

### Network Connectivity
- Verify VPC configurations in all regions
- Check security group rules
- Ensure cross-region connectivity

### Workload Interruptions
- Verify migration strategy compatibility
- Check workload state handling
- Review interruption behavior settings