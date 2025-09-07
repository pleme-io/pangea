# AWS ECS Cluster Implementation

## Overview

The `aws_ecs_cluster` resource implements type-safe AWS ECS cluster creation with comprehensive validation and helper methods. This resource is the foundation for container orchestration in ECS.

## Type System Design

### EcsClusterAttributes

The main attributes struct provides:

1. **Cluster Configuration**
   - `name` - Required cluster identifier
   - `capacity_providers` - Array of provider names/ARNs with validation
   - `container_insights_enabled` - Boolean for CloudWatch Container Insights

2. **Advanced Settings**
   - `setting` - Array of name/value pairs for cluster settings
   - `configuration` - Nested execute command configuration
   - `service_connect_defaults` - Service mesh defaults

3. **Validation Rules**
   - Capacity providers must be FARGATE, FARGATE_SPOT, or valid ARNs
   - Container insights setting conflicts are detected
   - Setting values are enum-validated

### EcsCapacityProviderStrategy

A separate type for capacity provider strategies with:
- `capacity_provider` - Provider name/ARN
- `weight` - Distribution weight (0-1000)
- `base` - Base count (0-100000)
- Validation ensures base > 0 requires weight > 0

## Key Features

### 1. Capacity Provider Support

```ruby
# Validates against allowed providers
capacity_providers: ["FARGATE", "FARGATE_SPOT"]  # Valid
capacity_providers: ["INVALID"]  # Raises error
capacity_providers: ["arn:aws:ecs:us-east-1:123456789012:capacity-provider/custom"]  # Valid ARN
```

### 2. Container Insights Integration

Two ways to enable Container Insights:

```ruby
# Shorthand
container_insights_enabled: true

# Or explicit setting
setting: [{
  name: "containerInsights",
  value: "enabled"
}]
```

The implementation prevents conflicts between these approaches.

### 3. Execute Command Configuration

Comprehensive support for ECS Exec:

```ruby
configuration: {
  execute_command_configuration: {
    kms_key_id: "arn:aws:kms:...",
    logging: "OVERRIDE",
    log_configuration: {
      cloud_watch_encryption_enabled: true,
      cloud_watch_log_group_name: "/ecs/exec",
      s3_bucket_name: "exec-logs",
      s3_bucket_encryption_enabled: true,
      s3_key_prefix: "logs/"
    }
  }
}
```

### 4. Service Connect Support

Enables service mesh capabilities:

```ruby
service_connect_defaults: {
  namespace: "arn:aws:servicediscovery:..."
}
```

## Helper Methods

### Capacity Detection

```ruby
cluster.using_fargate?  # true if any FARGATE* provider
cluster.using_ec2?      # true if any non-FARGATE provider
```

### Container Insights Status

```ruby
cluster.insights_enabled?  # Checks both shorthand and settings
```

### Cost Estimation

```ruby
cluster.estimated_monthly_cost  # Returns estimated costs
# Container Insights: $5/month
# Service Connect: $2/month
```

### ARN Generation

```ruby
cluster.arn_pattern("us-east-1", "123456789012")
# => "arn:aws:ecs:us-east-1:123456789012:cluster/cluster-name"
```

## Resource Synthesis

The resource implementation:

1. **Handles Optional Blocks** - Only synthesizes configured sections
2. **Manages Settings** - Merges container_insights_enabled with explicit settings
3. **Preserves Structure** - Maintains nested configuration hierarchy
4. **Tag Support** - Standard AWS tagging implementation

## Outputs

Standard outputs provided:
- `id` - Cluster ID
- `arn` - Full cluster ARN
- `name` - Cluster name
- `capacity_providers` - Provider list
- `tags_all` - Complete tag map
- `setting` - All cluster settings
- `configuration` - Execute command config
- `service_connect_defaults` - Service mesh defaults

## Integration Points

### With ECS Services

```ruby
cluster = aws_ecs_cluster(:main, {...})
service = aws_ecs_service(:web, {
  cluster: cluster.id,
  ...
})
```

### With Capacity Providers

```ruby
aws_ecs_cluster_capacity_providers(:config, {
  cluster_name: cluster.name,
  capacity_providers: ["FARGATE", custom_provider.name]
})
```

### With Task Definitions

Task definitions reference clusters indirectly through services.

## Terraform JSON Generation

The synthesis produces standard Terraform JSON:

```json
{
  "resource": {
    "aws_ecs_cluster": {
      "main": {
        "name": "production-cluster",
        "capacity_providers": ["FARGATE", "FARGATE_SPOT"],
        "setting": [{
          "name": "containerInsights",
          "value": "enabled"
        }],
        "tags": {
          "Environment": "production"
        }
      }
    }
  }
}
```

## Design Decisions

1. **Separate Capacity Provider Strategy Type** - Allows reuse across resources
2. **Container Insights Shorthand** - Simplifies common configuration
3. **ARN Pattern Helper** - Useful for IAM policy generation
4. **Cost Estimation** - Helps with budget planning
5. **Validation at Construction** - Catches errors early

## Testing Considerations

Key test scenarios:
1. Capacity provider validation (valid/invalid providers)
2. Container insights setting conflicts
3. Execute command configuration nesting
4. Service Connect namespace validation
5. Cost calculation accuracy

## Future Enhancements

Potential improvements:
1. Auto-generate capacity provider from ASG reference
2. Service Connect configuration validation
3. Cross-region cluster support helpers
4. Cluster-level default tags propagation
5. Integration with ECS Anywhere