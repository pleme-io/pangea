# Carbon Aware Compute Component

A sophisticated infrastructure component that enables carbon-aware workload scheduling and execution, automatically optimizing for both carbon emissions and cost efficiency by shifting workloads across time and regions based on grid carbon intensity.

## Overview

The Carbon Aware Compute component implements intelligent workload scheduling that considers real-time carbon intensity data to minimize the environmental impact of computational workloads. It supports multiple optimization strategies including time-shifting (delaying workloads to cleaner times) and location-shifting (moving workloads to greener regions).

## Key Features

- **Real-time Carbon Tracking**: Monitors grid carbon intensity across multiple AWS regions
- **Intelligent Scheduling**: Automatically schedules workloads during low-carbon periods
- **Multi-Region Optimization**: Shifts workloads to regions with cleaner energy grids
- **Flexible Strategies**: Supports time-shifting, location-shifting, or combined approaches
- **Comprehensive Monitoring**: Built-in CloudWatch dashboard for carbon and efficiency metrics
- **Cost Optimization**: Reduces costs while minimizing carbon footprint
- **Graviton Support**: Leverages energy-efficient ARM processors
- **Spot Instance Integration**: Uses excess capacity for additional sustainability

## Usage

```ruby
carbon_compute = Pangea::Components::CarbonAwareCompute.build(
  name: "sustainable-batch-processor",
  workload_type: "batch",
  vpc_id: "vpc-12345",
  subnet_ids: ["subnet-1a", "subnet-1b"],
  
  # Carbon optimization settings
  optimization_strategy: "combined",
  carbon_intensity_threshold: 150,  # gCO2/kWh
  preferred_regions: ["us-west-2", "eu-north-1", "ca-central-1"],
  
  # Execution windows
  min_execution_window_hours: 2,
  max_execution_window_hours: 24,
  deadline_hours: 48,
  
  # Performance settings
  cpu_units: 512,
  memory_mb: 1024,
  use_graviton: true,
  use_spot_instances: true,
  
  tags: {
    "Environment" => "production",
    "Sustainability" => "enabled"
  }
)

# Access outputs
puts carbon_compute.scheduler_function_arn
puts carbon_compute.dashboard_url
```

## Optimization Strategies

### Time Shifting
Delays workload execution to times when the electricity grid is cleaner (e.g., nighttime when renewable sources are more prevalent).

### Location Shifting  
Moves workloads to AWS regions powered by cleaner energy sources (e.g., Oregon with hydroelectric power).

### Combined Strategy
Uses both time and location shifting to find the optimal execution plan with the lowest carbon footprint.

### Efficiency First
Prioritizes computational efficiency to reduce overall energy consumption regardless of grid carbon intensity.

## Carbon Intensity Thresholds

The component uses the following carbon intensity classifications:

- **Very Low**: < 50 gCO2/kWh (e.g., Quebec, Norway)
- **Low**: 50-150 gCO2/kWh (e.g., Oregon, Sweden)
- **Medium**: 150-300 gCO2/kWh (e.g., California, Ireland)
- **High**: 300-500 gCO2/kWh (e.g., Virginia, Germany)
- **Very High**: > 500 gCO2/kWh (e.g., Singapore, Poland)

## Preferred Green Regions

Default regions with high renewable energy usage:

1. **us-west-2** (Oregon): ~80% hydroelectric power
2. **eu-north-1** (Stockholm): ~95% renewable energy
3. **eu-west-1** (Ireland): Carbon neutral data centers
4. **ca-central-1** (Montreal): ~99% hydroelectric power

## Monitoring and Metrics

The component automatically creates a CloudWatch dashboard showing:

- Real-time carbon emissions (gCO2eq)
- Regional carbon intensity (gCO2/kWh)
- Workload scheduling metrics
- Computational efficiency scores
- Cost savings from optimization

## Architecture Components

- **Lambda Functions**: Scheduler, executor, and monitor functions
- **DynamoDB Tables**: Workload queue and carbon data cache
- **EventBridge Rules**: Automated scheduling and monitoring
- **CloudWatch**: Metrics, alarms, and dashboards
- **IAM Roles**: Least-privilege access policies

## Best Practices

1. **Set Realistic Deadlines**: Allow sufficient time windows for optimal scheduling
2. **Monitor Carbon Savings**: Review dashboard regularly to track environmental impact
3. **Use Graviton**: Enable ARM-based instances for 20% better energy efficiency
4. **Implement Batching**: Group small workloads for more efficient execution
5. **Consider Time Zones**: Account for regional time differences in scheduling

## Example: ML Training Pipeline

```ruby
ml_training = Pangea::Components::CarbonAwareCompute.build(
  name: "ml-model-training",
  workload_type: "ml_training",
  vpc_id: vpc_id,
  subnet_ids: private_subnet_ids,
  
  # ML workloads can be flexible with timing
  optimization_strategy: "time_shifting",
  carbon_intensity_threshold: 100,
  min_execution_window_hours: 1,
  max_execution_window_hours: 72,  # 3 days flexibility
  
  # Higher resources for ML
  cpu_units: 4096,
  memory_mb: 16384,
  ephemeral_storage_gb: 100,
  
  # Cost optimization for long-running training
  use_spot_instances: true,
  
  tags: {
    "Project" => "sustainability-ml",
    "CostCenter" => "research"
  }
)
```

## Integration with CI/CD

```ruby
# In your CI/CD pipeline
ci_builds = Pangea::Components::CarbonAwareCompute.build(
  name: "ci-build-jobs",
  workload_type: "batch",
  vpc_id: vpc_id,
  subnet_ids: subnet_ids,
  
  # CI can usually wait a bit
  optimization_strategy: "time_shifting",
  min_execution_window_hours: 0,
  max_execution_window_hours: 4,
  deadline_hours: 6,
  
  # Smaller resources for builds
  cpu_units: 1024,
  memory_mb: 2048
)
```

## Carbon Data Sources

The component supports multiple carbon intensity data sources:

- **Electricity Maps**: Real-time grid carbon intensity
- **WattTime**: Marginal emissions data
- **Custom Sources**: Integrate your own data providers

## Troubleshooting

### High Carbon Alerts
If receiving frequent high carbon alerts:
1. Increase the carbon intensity threshold
2. Add more preferred regions
3. Extend execution time windows

### Workloads Not Executing
Check:
1. DynamoDB table permissions
2. Lambda function logs
3. EventBridge rule status
4. Network connectivity in VPC

### Metrics Not Appearing
Ensure:
1. CloudWatch permissions are correct
2. Lambda functions are executing successfully
3. Carbon reporting is enabled