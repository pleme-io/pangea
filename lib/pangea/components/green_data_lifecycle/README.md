# Green Data Lifecycle Component

Sustainable data storage infrastructure that automatically optimizes storage classes based on access patterns and carbon footprint, reducing both environmental impact and costs through intelligent lifecycle management.

## Overview

The Green Data Lifecycle component implements a comprehensive data management strategy that balances accessibility, cost, and environmental impact. It automatically transitions data through storage tiers based on access patterns while optimizing for the lowest carbon footprint per GB stored.

## Key Features

- **Intelligent Tiering**: Automatic movement between storage classes based on access frequency
- **Carbon-Optimized Storage**: Prioritizes low-carbon storage options (cold storage, tape)
- **Access Pattern Analysis**: ML-based prediction of data access patterns
- **Automated Archival**: Moves cold data to Glacier and Deep Archive
- **Compliance Support**: Legal hold, retention policies, and deletion protection
- **Cost Optimization**: Reduces storage costs by up to 95% for cold data
- **Comprehensive Monitoring**: Carbon footprint tracking per storage class

## Storage Carbon Intensity

Different storage classes have varying carbon footprints:

| Storage Class | Carbon Intensity (gCO2/GB/month) | Use Case |
|--------------|----------------------------------|----------|
| STANDARD | 0.55 | Frequently accessed hot data |
| INTELLIGENT_TIERING | 0.45 | Variable access patterns |
| STANDARD_IA | 0.35 | Infrequently accessed |
| ONEZONE_IA | 0.30 | Non-critical infrequent access |
| GLACIER_IR | 0.15 | Archive with quick retrieval |
| GLACIER_FLEXIBLE | 0.10 | Long-term archive |
| DEEP_ARCHIVE | 0.05 | Compliance/permanent archive |

## Usage

```ruby
green_storage = Pangea::Components::GreenDataLifecycle.build(
  name: "sustainable-app-data",
  bucket_prefix: "myapp",
  
  # Lifecycle strategy
  lifecycle_strategy: "carbon_optimized",
  enable_intelligent_tiering: true,
  enable_glacier_archive: true,
  
  # Transition timeline (days)
  transition_to_ia_days: 30,
  transition_to_glacier_ir_days: 90,
  transition_to_glacier_days: 180,
  transition_to_deep_archive_days: 365,
  
  # Access pattern monitoring
  monitor_access_patterns: true,
  access_pattern_window_days: 90,
  
  # Carbon optimization
  prefer_renewable_regions: true,
  carbon_threshold_gco2_per_gb: 0.3,
  
  # Compliance
  compliance_mode: true,
  deletion_protection: true,
  legal_hold_tags: ["legal-hold", "audit-required"],
  
  tags: {
    "Environment" => "production",
    "DataClassification" => "internal"
  }
)

# Access outputs
puts green_storage.primary_bucket_name
puts green_storage.dashboard_url
```

## Lifecycle Strategies

### Carbon Optimized (Default)
Aggressively moves data to lower carbon storage classes while maintaining accessibility requirements.

```ruby
lifecycle_strategy: "carbon_optimized"
```

### Access Pattern Based
Uses machine learning to predict access patterns and optimize storage accordingly.

```ruby
lifecycle_strategy: "access_pattern_based"
monitor_access_patterns: true
```

### Time Based
Simple age-based transitions for predictable workloads.

```ruby
lifecycle_strategy: "time_based"
```

### Size Based
Archives large files quickly to reduce storage footprint.

```ruby
lifecycle_strategy: "size_based"
large_object_threshold_mb: 100
archive_large_objects_days: 7
```

### Cost Optimized
Balances carbon reduction with cost savings.

```ruby
lifecycle_strategy: "cost_optimized"
```

## Data Classification

The component automatically classifies data into temperature tiers:

- **Hot**: Accessed multiple times per day
- **Warm**: Accessed weekly
- **Cool**: Accessed monthly
- **Cold**: Accessed quarterly or less
- **Frozen**: Compliance archive, rarely accessed

## Example: Machine Learning Dataset Storage

```ruby
ml_storage = Pangea::Components::GreenDataLifecycle.build(
  name: "ml-datasets",
  bucket_prefix: "ml-data",
  
  # ML datasets have specific access patterns
  lifecycle_strategy: "access_pattern_based",
  monitor_access_patterns: true,
  optimize_for_read_heavy: true,
  
  # Keep training data accessible
  transition_to_ia_days: 60,
  transition_to_glacier_ir_days: 180,
  
  # Large model checkpoints
  large_object_threshold_mb: 1000,
  archive_large_objects_days: 14,
  
  tags: {
    "Project" => "ml-platform",
    "CostCenter" => "research"
  }
)
```

## Example: Compliance Data Archive

```ruby
compliance_storage = Pangea::Components::GreenDataLifecycle.build(
  name: "compliance-archive",
  
  # Strict compliance requirements
  lifecycle_strategy: "time_based",
  compliance_mode: true,
  deletion_protection: true,
  legal_hold_tags: ["sox-audit", "gdpr-retention"],
  
  # 7-year retention
  transition_to_ia_days: 90,
  transition_to_glacier_days: 365,
  transition_to_deep_archive_days: 730,
  expire_days: 2555,  # 7 years
  
  tags: {
    "Compliance" => "sox",
    "Retention" => "7-years"
  }
)
```

## Monitoring and Metrics

The component provides comprehensive monitoring through CloudWatch:

### Carbon Metrics
- Total carbon footprint (gCO2)
- Carbon per GB stored
- Carbon efficiency score
- Storage class distribution

### Efficiency Metrics
- Access pattern score
- Storage efficiency percentage
- Cost savings achieved
- Data temperature distribution

### Activity Metrics
- Objects transitioned
- Objects archived
- Objects deleted
- Compliance issues detected

## Best Practices

1. **Start with Intelligent Tiering**: Let AWS optimize based on access patterns
2. **Monitor Access Patterns**: Review the dashboard to understand data usage
3. **Set Appropriate Thresholds**: Balance carbon goals with performance needs
4. **Use Lifecycle Policies**: Automate transitions to reduce manual work
5. **Enable Inventory Reports**: Track storage distribution and costs
6. **Tag Strategically**: Use tags for fine-grained lifecycle control

## Integration Examples

### With Carbon Aware Compute

```ruby
# Store ML training results with carbon optimization
compute = carbon_aware_compute.executor_function
storage = green_data_lifecycle.primary_bucket

# Lambda processes and stores results
aws_lambda_permission(:allow_s3, {
  statement_id: "AllowS3Invoke",
  action: "lambda:InvokeFunction",
  function_name: compute.function_name,
  principal: "s3.amazonaws.com",
  source_arn: storage.arn
})
```

### With Data Pipeline

```ruby
# Archive pipeline outputs sustainably
pipeline_storage = Pangea::Components::GreenDataLifecycle.build(
  name: "pipeline-outputs",
  lifecycle_strategy: "size_based",
  
  # Archive large results quickly
  large_object_threshold_mb: 50,
  archive_large_objects_days: 3
)
```

## Cost and Carbon Savings

Typical savings achieved:

| Data Age | Storage Class | Cost Savings | Carbon Reduction |
|----------|--------------|--------------|------------------|
| 30 days | STANDARD_IA | 45% | 36% |
| 90 days | GLACIER_IR | 80% | 73% |
| 180 days | GLACIER | 85% | 82% |
| 365 days | DEEP_ARCHIVE | 95% | 91% |

## Troubleshooting

### Objects Not Transitioning
1. Check lifecycle rule status in S3 console
2. Verify object tags match rule filters
3. Ensure objects meet minimum age requirements
4. Check IAM permissions for lifecycle role

### High Carbon Alerts
1. Review storage class distribution
2. Identify hot data in expensive storage
3. Adjust transition timelines
4. Consider more aggressive archival

### Compliance Issues
1. Verify legal hold tags are applied
2. Check retention policy configuration
3. Review deletion protection settings
4. Audit object tagging compliance