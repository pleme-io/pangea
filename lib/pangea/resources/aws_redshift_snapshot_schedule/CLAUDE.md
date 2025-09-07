# AWS Redshift Snapshot Schedule - Technical Documentation

## Architecture Overview

AWS Redshift Snapshot Schedules provide automated backup management for Redshift clusters. They enable point-in-time recovery, disaster recovery, and compliance with data retention policies through scheduled snapshots.

### Key Concepts

1. **Automated Backups**: Schedule-driven snapshot creation
2. **Flexible Scheduling**: Rate-based and cron expressions
3. **Multi-Schedule Support**: Up to 50 definitions per schedule
4. **Incremental Snapshots**: Only changed blocks after first full snapshot

## Implementation Details

### Type Safety with Dry::Struct

The `RedshiftSnapshotScheduleAttributes` class provides validation:

```ruby
# Identifier validation
- Must start with letter
- Alphanumeric, hyphens, underscores allowed
- Maximum 255 characters

# Schedule definition validation
- Rate expressions: rate(N hours|days)
- Cron expressions: 6-field format
- Maximum 50 definitions per schedule

# Expression validation
- Rate: 1-999 hours/days
- Cron: Standard 6-field AWS format
```

### Resource Outputs

The resource returns:
- `id` - Schedule identifier
- `arn` - Schedule ARN
- `definitions` - Array of schedule definitions

### Computed Properties

1. **Schedule Analysis**
   - `has_rate_schedules?` - Uses rate expressions
   - `has_cron_schedules?` - Uses cron expressions
   - `high_frequency?` - Interval ≤ 4 hours

2. **Interval Metrics**
   - `minimum_interval_hours` - Shortest interval
   - `maximum_interval_hours` - Longest interval
   - `estimated_snapshots_per_day` - Daily snapshot count

## Advanced Features

### Schedule Expression Parsing

The implementation provides intelligent parsing of schedule expressions:

```ruby
# Rate expression parsing
"rate(1 hour)"   -> 1 hour interval
"rate(12 hours)" -> 12 hour interval
"rate(1 day)"    -> 24 hour interval
"rate(7 days)"   -> 168 hour interval

# Cron expression format
# ┌───────────── minute (0 - 59)
# │ ┌───────────── hour (0 - 23)
# │ │ ┌───────────── day of month (1 - 31)
# │ │ │ ┌───────────── month (1 - 12)
# │ │ │ │ ┌───────────── day of week (SUN - SAT)
# │ │ │ │ │ ┌───────────── year (*)
# │ │ │ │ │ │
# * * * * * *
"cron(0 2 * * ? *)"     # Daily at 2 AM
"cron(0 */4 * * ? *)"   # Every 4 hours
"cron(0 2 ? * MON *)"   # Monday at 2 AM
```

### Storage Estimation

Calculate storage requirements for snapshot retention:

```ruby
# Storage calculation
def estimate_storage(cluster_size_gb, retention_days, change_rate = 0.05)
  schedule = RedshiftSnapshotScheduleAttributes.schedule_for_retention(retention_days)
  
  # Create schedule with calculated definitions
  schedule_ref = aws_redshift_snapshot_schedule(:calculated, {
    identifier: "retention-#{retention_days}d",
    definitions: schedule[:definitions]
  })
  
  # Estimate storage
  snapshots_per_day = schedule_ref.computed_properties[:estimated_snapshots_per_day]
  total_snapshots = snapshots_per_day * retention_days
  
  # First snapshot is full, rest are incremental
  full_size = cluster_size_gb
  incremental_size = cluster_size_gb * change_rate * total_snapshots
  
  total_storage_gb = full_size + incremental_size
  monthly_cost = total_storage_gb * 0.023 # S3 standard pricing
  
  { storage_gb: total_storage_gb, monthly_cost_usd: monthly_cost }
end
```

## Best Practices

### 1. RPO-Based Scheduling

```ruby
# Define Recovery Point Objectives
rpo_requirements = {
  critical: { rpo_hours: 1, retention_days: 7 },
  standard: { rpo_hours: 4, retention_days: 30 },
  archive: { rpo_hours: 24, retention_days: 90 }
}

rpo_requirements.each do |tier, req|
  aws_redshift_snapshot_schedule(:"#{tier}_rpo", {
    identifier: "#{tier}-rpo-#{req[:rpo_hours]}h",
    definitions: ["rate(#{req[:rpo_hours]} hours)"],
    description: "#{tier.capitalize} tier: #{req[:rpo_hours]}h RPO, #{req[:retention_days]}d retention",
    tags: {
      Tier: tier.to_s,
      RPOHours: req[:rpo_hours].to_s,
      RetentionDays: req[:retention_days].to_s
    }
  })
end
```

### 2. Compliance-Driven Schedules

```ruby
# Regulatory compliance schedules
compliance_schedules = {
  hipaa: {
    definitions: ["rate(6 hours)"], # 4 snapshots daily
    retention: 2555, # 7 years
    description: "HIPAA compliance - 7 year retention"
  },
  pci_dss: {
    definitions: ["rate(1 hour)", "cron(0 0 * * ? *)"], # Hourly + daily
    retention: 365, # 1 year
    description: "PCI-DSS compliance - 1 year retention"
  },
  sox: {
    definitions: ["rate(4 hours)"], # 6 snapshots daily
    retention: 2555, # 7 years
    description: "SOX compliance - 7 year retention"
  }
}

compliance_schedules.each do |regulation, config|
  aws_redshift_snapshot_schedule(:"#{regulation}_compliance", {
    identifier: "#{regulation}-compliance",
    definitions: config[:definitions],
    description: config[:description],
    tags: {
      Compliance: regulation.to_s.upcase,
      RetentionDays: config[:retention].to_s,
      Mandatory: "true"
    }
  })
end
```

### 3. Cost-Optimized Scheduling

```ruby
# Balance snapshot frequency with storage costs
cost_tiers = {
  premium: { 
    schedule: ["rate(1 hour)"],
    clusters: ["production-critical"]
  },
  standard: { 
    schedule: ["rate(6 hours)"],
    clusters: ["production-standard", "staging"]
  },
  economy: { 
    schedule: ["cron(0 2 * * ? *)"], # Daily only
    clusters: ["development", "testing"]
  }
}

cost_tiers.each do |tier, config|
  schedule_ref = aws_redshift_snapshot_schedule(:"#{tier}_cost_tier", {
    identifier: "cost-tier-#{tier}",
    definitions: config[:schedule],
    tags: { CostTier: tier.to_s }
  })
  
  # Associate with appropriate clusters
  config[:clusters].each do |cluster_name|
    aws_redshift_snapshot_schedule_association(:"#{tier}_#{cluster_name}", {
      cluster_identifier: cluster_name,
      schedule_identifier: schedule_ref.outputs[:id]
    })
  end
end
```

## Common Patterns

### 1. Time-Zone Aware Scheduling

```ruby
# Schedule snapshots for different time zones
time_zones = {
  us_east: { cron: "cron(0 7 * * ? *)", tz: "EST" },    # 2 AM EST
  us_west: { cron: "cron(0 10 * * ? *)", tz: "PST" },   # 2 AM PST
  europe: { cron: "cron(0 1 * * ? *)", tz: "UTC" },     # 2 AM CET
  asia: { cron: "cron(0 17 * * ? *)", tz: "UTC" }       # 2 AM JST
}

time_zones.each do |region, config|
  aws_redshift_snapshot_schedule(:"#{region}_maintenance", {
    identifier: "#{region.to_s.tr('_', '-')}-maintenance-window",
    definitions: [config[:cron]],
    description: "Maintenance window snapshot for #{config[:tz]}",
    tags: {
      Region: region.to_s,
      TimeZone: config[:tz]
    }
  })
end
```

### 2. Workload-Aligned Scheduling

```ruby
# Align snapshots with workload patterns
workload_patterns = {
  batch_etl: {
    # Snapshot before and after batch runs
    definitions: [
      "cron(0 23 * * ? *)",  # Before midnight batch
      "cron(0 6 * * ? *)"    # After morning batch
    ]
  },
  real_time: {
    # Continuous protection for streaming
    definitions: ["rate(1 hour)"]
  },
  reporting: {
    # Before business hours and after close
    definitions: [
      "cron(0 7 * * MON-FRI *)",
      "cron(0 19 * * MON-FRI *)"
    ]
  }
}

workload_patterns.each do |pattern, config|
  aws_redshift_snapshot_schedule(:"#{pattern}_aligned", {
    identifier: "workload-#{pattern.to_s.tr('_', '-')}",
    definitions: config[:definitions],
    tags: { WorkloadPattern: pattern.to_s }
  })
end
```

### 3. Lifecycle-Based Scheduling

```ruby
# Different schedules for cluster lifecycle stages
lifecycle_schedules = {
  active: {
    definitions: ["rate(2 hours)"],
    description: "Frequent snapshots for active clusters"
  },
  maintenance: {
    definitions: ["rate(6 hours)", "cron(0 0 * * ? *)"],
    description: "Reduced frequency during maintenance"
  },
  archive: {
    definitions: ["cron(0 2 ? * SUN *)"], # Weekly
    description: "Minimal snapshots for archived clusters"
  }
}

lifecycle_schedules.each do |stage, config|
  aws_redshift_snapshot_schedule(:"#{stage}_lifecycle", {
    identifier: "lifecycle-#{stage}",
    definitions: config[:definitions],
    description: config[:description],
    tags: {
      LifecycleStage: stage.to_s,
      AutoTransition: "true"
    }
  })
end
```

## Integration Examples

### With Cluster Lifecycle Management

```ruby
# Create schedules for different cluster states
active_schedule = aws_redshift_snapshot_schedule(:active_clusters, {
  identifier: "active-cluster-snapshots",
  definitions: ["rate(1 hour)"]
})

paused_schedule = aws_redshift_snapshot_schedule(:paused_clusters, {
  identifier: "paused-cluster-snapshots",
  definitions: ["cron(0 2 * * ? *)"] # Daily when paused
})

# Switch schedules based on cluster state
# (Would be managed by automation/Lambda)
```

### With Cross-Region Replication

```ruby
# Primary region frequent snapshots
primary_schedule = aws_redshift_snapshot_schedule(:primary_region, {
  identifier: "primary-region-snapshots",
  definitions: ["rate(1 hour)"],
  tags: { Region: "primary", Replicated: "true" }
})

# DR region less frequent
dr_schedule = aws_redshift_snapshot_schedule(:dr_region, {
  identifier: "dr-region-snapshots",
  definitions: ["rate(6 hours)"],
  tags: { Region: "dr", Purpose: "disaster-recovery" }
})
```

## Troubleshooting

### Common Issues

1. **Snapshot Failures**
   - Check cluster state (must be available)
   - Verify IAM permissions
   - Ensure sufficient storage space

2. **Schedule Conflicts**
   - Multiple snapshots can't run simultaneously
   - Stagger schedules by at least 15 minutes
   - Monitor snapshot duration

3. **Storage Costs**
   - Review snapshot retention policies
   - Use lifecycle rules for old snapshots
   - Consider incremental backup patterns

## Cost Optimization

### Storage Cost Calculation

```ruby
# Snapshot storage cost estimator
def calculate_snapshot_costs(params)
  cluster_size_tb = params[:cluster_size_gb] / 1024.0
  change_rate = params[:daily_change_rate] || 0.05
  retention_days = params[:retention_days]
  
  # First snapshot is full size
  full_snapshot_tb = cluster_size_tb
  
  # Daily incremental size
  daily_incremental_tb = cluster_size_tb * change_rate
  
  # Total storage over retention period
  total_storage_tb = full_snapshot_tb + (daily_incremental_tb * retention_days)
  
  # S3 standard pricing per TB/month
  monthly_cost = total_storage_tb * 23.55
  
  {
    total_storage_tb: total_storage_tb.round(2),
    monthly_cost_usd: monthly_cost.round(2),
    yearly_cost_usd: (monthly_cost * 12).round(2)
  }
end
```

### Optimization Strategies

1. **Tiered Retention**: Frequent snapshots with short retention, infrequent with long retention
2. **Lifecycle Policies**: Move old snapshots to cheaper storage classes
3. **Incremental Optimization**: Minimize data changes between snapshots
4. **Schedule Consolidation**: Combine multiple schedules where possible