# AWS Athena Workgroup - Technical Documentation

## Architecture Overview

AWS Athena Workgroups provide resource isolation, access control, and cost management for Athena queries. They act as logical containers that separate query execution contexts, making them essential for multi-tenant environments and cost allocation.

### Key Concepts

1. **Query Isolation**: Separate query history, saved queries, and settings
2. **Cost Control**: Per-workgroup query limits and cost tracking
3. **Access Management**: IAM-based permissions per workgroup
4. **Configuration Enforcement**: Override client-side query settings

## Implementation Details

### Type Safety with Dry::Struct

The `AthenaWorkgroupAttributes` class provides comprehensive validation:

```ruby
# Workgroup name validation
- Alphanumeric characters, hyphens, underscores only
- Maximum 128 characters
- No spaces or special characters

# Configuration validation
- KMS key required for KMS encryption options
- Bytes scanned cutoff minimum 10MB
- Engine version compatibility checks
```

### Resource Outputs

The resource returns these Terraform outputs:
- `id` - Workgroup name
- `arn` - Workgroup ARN
- `configuration` - Complete configuration object

### Computed Properties

1. **enabled?** - Workgroup state check
2. **has_output_location?** - Result location configuration
3. **enforces_configuration?** - Configuration override status
4. **cloudwatch_metrics_enabled?** - Metrics publishing status
5. **encryption_type** - Encryption method used
6. **uses_kms?** - KMS encryption check
7. **has_query_limits?** - Query limit configuration
8. **query_limit_gb** - Limit converted to gigabytes
9. **estimated_monthly_cost_usd** - Cost estimation based on usage patterns

## Advanced Features

### Configuration Templates

Pre-built configurations for common use cases:

```ruby
# Production workgroup - high security, monitoring
config = AthenaWorkgroupAttributes.default_configuration_for_type(
  :production,
  "s3://prod-results/"
)
# Includes: KMS encryption, 1TB query limit, metrics enabled

# Development workgroup - flexible, cost-conscious  
config = AthenaWorkgroupAttributes.default_configuration_for_type(
  :development,
  "s3://dev-results/"
)
# Includes: 10GB query limit, configuration override disabled

# Cost-optimized workgroup - strict limits
config = AthenaWorkgroupAttributes.default_configuration_for_type(
  :cost_optimized,
  "s3://cost-results/"
)
# Includes: 1GB limit, requester pays, SSE-S3 encryption

# Analytics workgroup - performance focused
config = AthenaWorkgroupAttributes.default_configuration_for_type(
  :analytics,
  "s3://analytics-results/"
)
# Includes: Engine v3, KMS encryption, metrics enabled
```

### Query Execution Control

```ruby
# Strict query limits for cost control
configuration: {
  bytes_scanned_cutoff_per_query: 10_737_418_240, # 10GB
  enforce_workgroup_configuration: true # Can't be overridden
}

# Flexible limits for power users
configuration: {
  bytes_scanned_cutoff_per_query: 1_099_511_627_776, # 1TB
  enforce_workgroup_configuration: false # Allow overrides
}
```

## Best Practices

### 1. Workgroup Organization

```ruby
# By team
aws_athena_workgroup(:analytics_team, { name: "analytics-prod" })
aws_athena_workgroup(:data_science, { name: "datascience-prod" })

# By environment
aws_athena_workgroup(:prod_queries, { name: "production" })
aws_athena_workgroup(:dev_queries, { name: "development" })

# By cost center
aws_athena_workgroup(:dept_100, { name: "finance-dept-100" })
aws_athena_workgroup(:dept_200, { name: "marketing-dept-200" })
```

### 2. Security Configuration

```ruby
# Enforce encryption and access controls
aws_athena_workgroup(:secure, {
  name: "secure-workgroup",
  configuration: {
    result_configuration: {
      output_location: "s3://secure-results/",
      encryption_configuration: {
        encryption_option: "SSE_KMS",
        kms_key_id: kms_key_ref.id
      },
      expected_bucket_owner: "123456789012"
    },
    customer_content_encryption_configuration: {
      kms_key_id: customer_kms_ref.id
    },
    enforce_workgroup_configuration: true
  }
})
```

### 3. Cost Management

```ruby
# Tiered cost controls
tiers = {
  bronze: { limit_gb: 1, retention_days: 7 },
  silver: { limit_gb: 10, retention_days: 30 },
  gold: { limit_gb: 100, retention_days: 90 }
}

tiers.each do |tier, config|
  aws_athena_workgroup(:"#{tier}_tier", {
    name: "#{tier}-workgroup",
    configuration: {
      result_configuration: {
        output_location: "s3://results/#{tier}/"
      },
      bytes_scanned_cutoff_per_query: config[:limit_gb] * 1_073_741_824
    }
  })
end
```

## Common Patterns

### 1. Multi-Region Workgroups

```ruby
regions = ["us-east-1", "us-west-2", "eu-west-1"]

regions.each do |region|
  aws_athena_workgroup(:"analytics_#{region.tr("-", "_")}", {
    name: "analytics-#{region}",
    configuration: {
      result_configuration: {
        output_location: "s3://athena-results-#{region}/analytics/"
      }
    }
  })
end
```

### 2. Scheduled Query Workgroup

```ruby
aws_athena_workgroup(:scheduled_queries, {
  name: "scheduled-queries",
  description: "Workgroup for automated scheduled queries",
  configuration: {
    result_configuration: {
      output_location: "s3://scheduled-results/",
      encryption_configuration: {
        encryption_option: "SSE_S3"
      }
    },
    publish_cloudwatch_metrics_enabled: true,
    engine_version: {
      selected_engine_version: "Athena engine version 3"
    }
  }
})
```

### 3. Federated Query Workgroup

```ruby
aws_athena_workgroup(:federated, {
  name: "federated-queries",
  configuration: {
    result_configuration: {
      output_location: "s3://federated-results/"
    },
    execution_role: iam_role_ref.arn,
    engine_version: {
      selected_engine_version: "Athena engine version 3"
    }
  }
})
```

## Integration Examples

### With CloudWatch Alarms

```ruby
workgroup_ref = aws_athena_workgroup(:monitored, {
  name: "monitored-workgroup",
  configuration: {
    publish_cloudwatch_metrics_enabled: true
  }
})

aws_cloudwatch_metric_alarm(:high_data_scanned, {
  alarm_name: "athena-high-data-scanned",
  namespace: "AWS/Athena",
  metric_name: "DataScannedInBytes",
  dimensions: {
    WorkGroup: workgroup_ref.outputs[:id]
  },
  threshold: 1_099_511_627_776 # 1TB
})
```

### With IAM Policies

```ruby
workgroup_ref = aws_athena_workgroup(:restricted, {
  name: "restricted-workgroup"
})

aws_iam_policy(:workgroup_access, {
  name: "athena-workgroup-access",
  policy: JSON.generate({
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Action: [
        "athena:GetQueryExecution",
        "athena:GetQueryResults",
        "athena:StartQueryExecution"
      ],
      Resource: workgroup_ref.outputs[:arn]
    }]
  })
})
```

## Troubleshooting

### Common Issues

1. **Query Execution Failures**
   - Check workgroup state (ENABLED/DISABLED)
   - Verify output location permissions
   - Ensure KMS key access for encryption

2. **Cost Overruns**
   - Set appropriate bytes_scanned_cutoff_per_query
   - Enable CloudWatch metrics for monitoring
   - Use partition projection to reduce scan volume

3. **Access Denied Errors**
   - Verify IAM permissions for workgroup
   - Check S3 bucket policies for output location
   - Ensure cross-account permissions if needed

## Cost Optimization

### Query Cost Calculation
```ruby
# Athena charges $5 per TB scanned
# Example: 100GB query = 0.1TB * $5 = $0.50

# Set limits based on budget
daily_budget_usd = 50
queries_per_day = 100
bytes_per_query = (daily_budget_usd / 5.0 / queries_per_day * 1_099_511_627_776).to_i

aws_athena_workgroup(:budget_controlled, {
  name: "budget-controlled",
  configuration: {
    bytes_scanned_cutoff_per_query: bytes_per_query
  }
})
```

### Cost Reduction Strategies

1. **Compression**: Use Parquet/ORC formats
2. **Partitioning**: Reduce data scanned
3. **Query Limits**: Prevent runaway queries
4. **Result Caching**: Reuse recent results