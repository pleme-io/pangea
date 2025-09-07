# AWS ECS Cluster Capacity Providers Implementation

## Overview

The `aws_ecs_cluster_capacity_providers` resource manages the association between ECS clusters and capacity providers, along with default capacity provider strategies that services inherit when not explicitly specified.

## Type System Design

### EcsClusterCapacityProvidersAttributes

The main configuration type that handles:
- `cluster_name` - Target ECS cluster
- `capacity_providers` - List of providers to associate
- `default_capacity_provider_strategy` - Default distribution strategy

### EcsDefaultCapacityProviderStrategy

Reusable strategy type (shared with other resources):
- `capacity_provider` - Provider name
- `weight` - Relative weight for task distribution
- `base` - Minimum guaranteed tasks

## Key Validation Rules

### Provider Validation
- AWS managed providers: FARGATE, FARGATE_SPOT
- Custom providers: Must match valid naming pattern
- ARN format supported for cross-account providers

### Strategy Validation
1. **Weight and Base Logic**
   - Cannot have base > 0 with weight = 0
   - Total weight must be > 0 if all bases are 0

2. **Provider Reference Validation**
   - Strategy can only reference providers in capacity_providers list
   - Prevents orphaned strategy entries

3. **Base Uniqueness**
   - Only one provider can have a specific base value > 0
   - Prevents ambiguous base task assignment

## Helper Methods

### Provider Type Detection
```ruby
providers.using_fargate?         # Has FARGATE or FARGATE_SPOT
providers.using_ec2?            # Has non-Fargate providers
providers.using_custom_providers? # Has custom provider names
```

### Strategy Analysis
```ruby
providers.primary_capacity_provider  # Provider with highest base/weight
providers.capacity_distribution     # Percentage breakdown
providers.spot_prioritized?        # FARGATE_SPOT weight > FARGATE
```

### Cost Estimation
```ruby
providers.estimated_spot_savings_percent  # Based on Spot percentage
```

## Capacity Distribution Algorithm

The distribution calculation:
1. Sum all weights to get total
2. Calculate percentage for each provider
3. Include base values in the distribution

Example:
```ruby
# Strategy:
# FARGATE_SPOT: weight=4, base=0
# FARGATE: weight=1, base=1

# Distribution:
# FARGATE_SPOT: 80% (after base task)
# FARGATE: 20% + 1 base task
```

## Resource Synthesis

The implementation:
1. Sets cluster name
2. Lists capacity providers (if any)
3. Iterates through default strategies
4. Only includes base if > 0 (Terraform default is 0)

## Integration with ECS Services

Services inherit the default strategy unless they specify their own:

```ruby
# Cluster configuration
aws_ecs_cluster_capacity_providers(:config, {
  cluster_name: "my-cluster",
  default_capacity_provider_strategy: [
    { capacity_provider: "FARGATE_SPOT", weight: 4 },
    { capacity_provider: "FARGATE", weight: 1, base: 1 }
  ]
})

# Service uses cluster defaults
aws_ecs_service(:web, {
  cluster: "my-cluster",
  task_definition: "web:1"
  # Inherits 80/20 Spot/Regular split
})

# Service overrides defaults
aws_ecs_service(:api, {
  cluster: "my-cluster",
  task_definition: "api:1",
  capacity_provider_strategy: [
    { capacity_provider: "FARGATE", weight: 1 }  # 100% regular
  ]
})
```

## Common Patterns

### Cost-Optimized Pattern
Maximize Spot usage while maintaining minimum stability:
```ruby
default_capacity_provider_strategy: [
  { capacity_provider: "FARGATE_SPOT", weight: 9, base: 0 },
  { capacity_provider: "FARGATE", weight: 1, base: 1 }
]
```

### High Availability Pattern
Ensure base capacity on stable infrastructure:
```ruby
default_capacity_provider_strategy: [
  { capacity_provider: "FARGATE", weight: 1, base: 3 },
  { capacity_provider: "FARGATE_SPOT", weight: 1, base: 0 }
]
```

### EC2 Mixed Instance Pattern
Combine on-demand and Spot EC2 instances:
```ruby
capacity_providers: ["on-demand-cp", "spot-cp"],
default_capacity_provider_strategy: [
  { capacity_provider: "on-demand-cp", weight: 1, base: 2 },
  { capacity_provider: "spot-cp", weight: 3, base: 0 }
]
```

## Design Decisions

1. **Shared Strategy Type** - Reusable across cluster and service resources
2. **Distribution Calculation** - Helper method for capacity planning
3. **Spot Savings Estimation** - Helps justify Spot adoption
4. **Primary Provider Detection** - Identifies main capacity source
5. **Validation at Construction** - Catch configuration errors early

## Terraform Behavior

Important behaviors:
1. Changing capacity providers forces new resource
2. Strategy changes update in-place
3. Services must be updated separately after strategy changes
4. Removing providers requires service updates first

## Testing Considerations

Key test scenarios:
1. Strategy validation with invalid provider references
2. Base value uniqueness enforcement
3. Weight/base relationship validation
4. Distribution calculation accuracy
5. Cost savings estimation

## Best Practices

1. **Set Base Values Carefully** - Base tasks always run on specified provider
2. **Weight for Flexibility** - Use weights for dynamic distribution
3. **Monitor Spot Availability** - Adjust strategy based on interruptions
4. **Test Strategy Changes** - Verify service behavior with new strategies
5. **Document Rationale** - Explain why specific weights/bases were chosen

## Future Enhancements

Potential improvements:
1. Strategy templates for common patterns
2. Automatic Spot percentage optimization
3. Multi-region strategy support
4. Time-based strategy switching
5. Integration with AWS Compute Optimizer recommendations