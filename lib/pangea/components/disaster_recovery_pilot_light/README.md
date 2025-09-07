# Disaster Recovery Pilot Light Component

## Overview

The `disaster_recovery_pilot_light` component implements a cost-effective disaster recovery pattern where minimal resources are kept running in a DR region, with automated mechanisms to rapidly scale up during an actual disaster. This pattern balances cost efficiency with reasonable RTO (Recovery Time Objective) and RPO (Recovery Point Objective) requirements.

## Features

- **Pilot Light Infrastructure**: Minimal standby resources with rapid activation capability
- **Automated Data Replication**: Cross-region replication for databases, S3, and EFS
- **Intelligent Activation**: Manual, automated, or semi-automated failover options
- **Comprehensive Testing**: Scheduled DR drills with automated rollback
- **Cost Optimization**: Minimal running costs with pay-per-use activation
- **Compliance Support**: RTO/RPO tracking and audit logging
- **Multi-Service Support**: Database replicas, object storage, and file systems
- **Monitoring & Alerting**: Real-time replication lag and health monitoring

## Usage

```ruby
dr_pilot_light = disaster_recovery_pilot_light(:dr_system, {
  dr_name: "production-dr",
  dr_description: "Pilot light DR for production environment",
  
  primary_region: {
    region: "us-east-1",
    vpc_cidr: "10.0.0.0/16",
    availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
    critical_resources: [
      {
        type: "database",
        id: "prod-aurora-cluster",
        engine: "aurora-postgresql"
      }
    ],
    backup_schedule: "cron(0 2 * * ? *)"  # 2 AM daily
  },
  
  dr_region: {
    region: "us-west-2",
    vpc_cidr: "10.1.0.0/16",
    availability_zones: ["us-west-2a", "us-west-2b"],
    standby_resources: {
      compute_capacity: "minimal",
      database_capacity: "single-instance"
    }
  },
  
  critical_data: {
    databases: [
      {
        identifier: "prod-aurora-cluster",
        engine: "aurora-postgresql",
        engine_version: "14.6"
      }
    ],
    s3_buckets: ["prod-assets", "prod-backups"],
    efs_filesystems: ["fs-12345678"],
    backup_retention_days: 7,
    cross_region_backup: true,
    point_in_time_recovery: true
  },
  
  pilot_light: {
    minimal_compute: true,
    database_replicas: true,
    data_sync_interval: 300,  # 5 minutes
    standby_instance_type: "t3.small",
    auto_scaling_min: 2,
    auto_scaling_max: 20
  },
  
  activation: {
    activation_method: "semi-automated",
    health_check_threshold: 3,
    activation_timeout: 900,  # 15 minutes
    pre_activation_checks: [
      { name: "ValidatePrimaryDown", type: "health_check" },
      { name: "CheckDataSync", type: "replication_status" }
    ],
    post_activation_validation: [
      { name: "ApplicationHealth", type: "endpoint_check" },
      { name: "DatabaseConnectivity", type: "connection_test" }
    ]
  },
  
  testing: {
    test_schedule: "cron(0 10 ? * SUN *)",  # Sunday 10 AM
    test_scenarios: ["failover", "data_recovery", "partial_activation"],
    automated_testing: true,
    test_notification_enabled: true,
    rollback_after_test: true
  },
  
  cost_optimization: {
    use_spot_instances: false,  # For stability
    reserved_capacity_percentage: 20,
    auto_shutdown_non_critical: true,
    compress_backups: true,
    dedup_enabled: true
  },
  
  monitoring: {
    primary_region_monitoring: true,
    dr_region_monitoring: true,
    replication_lag_threshold_seconds: 300,
    backup_monitoring: true,
    synthetic_monitoring: true,
    dashboard_enabled: true,
    alerting_enabled: true
  },
  
  compliance: {
    rto_hours: 4,
    rpo_hours: 1,
    data_residency_requirements: ["US"],
    encryption_required: true,
    audit_logging: true,
    compliance_standards: ["SOC2", "HIPAA"]
  },
  
  enable_automated_failover: false,
  enable_cross_region_vpc_peering: true,
  enable_infrastructure_as_code_sync: true
})
```

## Configuration Options

### Primary Region Configuration

- `region`: AWS region identifier for primary infrastructure
- `vpc_ref`: Optional reference to existing VPC
- `vpc_cidr`: CIDR block for new VPC (default: "10.0.0.0/16")
- `availability_zones`: List of AZs to use (minimum 2)
- `critical_resources`: Array of critical resource definitions
- `backup_schedule`: Cron expression for backup schedule

### DR Region Configuration

- `region`: AWS region identifier for DR infrastructure
- `vpc_ref`: Optional reference to existing VPC
- `vpc_cidr`: CIDR block for DR VPC (default: "10.1.0.0/16")
- `availability_zones`: List of AZs to use (minimum 2)
- `standby_resources`: Configuration for standby capacity
- `activation_priority`: Priority order for activation (default: 100)

### Critical Data Configuration

- `databases`: Array of database configurations to replicate
- `s3_buckets`: List of S3 buckets to replicate
- `efs_filesystems`: List of EFS filesystem IDs to replicate
- `backup_retention_days`: Days to retain backups (1-35)
- `cross_region_backup`: Enable cross-region backup copies
- `point_in_time_recovery`: Enable PITR for databases

### Pilot Light Configuration

- `minimal_compute`: Keep compute resources minimal
- `database_replicas`: Maintain database read replicas
- `data_sync_interval`: Sync interval in seconds (60-86400)
- `standby_instance_type`: Instance type for standby resources
- `auto_scaling_min`: Minimum instances when activated
- `auto_scaling_max`: Maximum instances when activated

### Activation Configuration

- `activation_method`: "manual", "automated", or "semi-automated"
- `health_check_threshold`: Failed checks before activation (1-10)
- `activation_timeout`: Maximum activation time in seconds (60-3600)
- `pre_activation_checks`: Checks to run before activation
- `post_activation_validation`: Validation after activation
- `notification_channels`: SNS topics for notifications

### Testing Configuration

- `test_schedule`: Cron expression for DR tests
- `test_scenarios`: Array of test scenarios to run
- `automated_testing`: Enable automated testing
- `test_notification_enabled`: Send test notifications
- `rollback_after_test`: Automatically rollback after test
- `test_data_subset`: Use subset of data for tests

### Cost Optimization Configuration

- `use_spot_instances`: Use spot for non-critical workloads
- `reserved_capacity_percentage`: Percentage of reserved capacity (0-100)
- `auto_shutdown_non_critical`: Shutdown non-critical resources
- `data_lifecycle_policies`: Enable data lifecycle management
- `compress_backups`: Compress backup data
- `dedup_enabled`: Enable deduplication

### Monitoring Configuration

- `primary_region_monitoring`: Monitor primary region
- `dr_region_monitoring`: Monitor DR region
- `replication_lag_threshold_seconds`: Maximum acceptable lag
- `backup_monitoring`: Monitor backup jobs
- `synthetic_monitoring`: Enable synthetic checks
- `dashboard_enabled`: Create CloudWatch dashboards
- `alerting_enabled`: Enable CloudWatch alarms

### Compliance Configuration

- `rto_hours`: Recovery Time Objective in hours
- `rpo_hours`: Recovery Point Objective in hours
- `data_residency_requirements`: Required data locations
- `encryption_required`: Enforce encryption
- `audit_logging`: Enable audit trails
- `compliance_standards`: List of compliance frameworks

## Outputs

The component returns:

- `dr_name`: Name of the DR setup
- `primary_region`: Primary region identifier
- `dr_region`: DR region identifier
- `rto_hours`: Configured RTO
- `rpo_hours`: Configured RPO
- `pilot_light_resources`: List of pilot light resources
- `activation_method`: Configured activation method
- `activation_runbook_url`: SSM document URL for activation
- `data_replication_status`: Status of each replication type
- `backup_status`: Backup configuration details
- `testing_configuration`: Test schedule and scenarios
- `cost_optimization_features`: Enabled cost features
- `monitoring_dashboards`: Created dashboard names
- `estimated_monthly_cost`: Monthly cost estimate
- `readiness_score`: DR readiness percentage (0-100)

## DR Patterns

### Minimal Cost Pattern

```ruby
pilot_light: {
  minimal_compute: true,
  database_replicas: true,
  auto_scaling_min: 0,
  auto_scaling_max: 10
},
cost_optimization: {
  use_spot_instances: true,
  auto_shutdown_non_critical: true,
  compress_backups: true
}
```

### Rapid Recovery Pattern

```ruby
pilot_light: {
  minimal_compute: true,
  database_replicas: true,
  standby_instance_type: "t3.medium",
  auto_scaling_min: 5,
  auto_scaling_max: 50
},
activation: {
  activation_method: "automated",
  activation_timeout: 300  # 5 minutes
}
```

### High Compliance Pattern

```ruby
compliance: {
  rto_hours: 2,
  rpo_hours: 0.5,
  encryption_required: true,
  audit_logging: true,
  compliance_standards: ["SOC2", "HIPAA", "PCI"]
},
critical_data: {
  cross_region_backup: true,
  point_in_time_recovery: true,
  backup_retention_days: 35
}
```

## Testing Procedures

### Automated DR Tests

The component supports various test scenarios:

1. **Failover Test**: Complete activation and validation
2. **Data Recovery Test**: Restore from backups
3. **Partial Activation**: Test specific components
4. **Network Connectivity**: Verify cross-region connectivity
5. **Application Health**: End-to-end application testing

### Manual Testing

```bash
# Trigger manual DR test
aws ssm start-automation-execution \
  --document-name "dr-system-DR-Activation-Runbook" \
  --parameters "ActivationType=test"

# Monitor test progress
aws cloudwatch get-dashboard \
  --dashboard-name "dr-system-replication-status"
```

## Cost Optimization

### Pilot Light Costs

- **Minimal Infrastructure**: ~$50-100/month
- **Database Replicas**: ~$50-200/month per database
- **S3 Replication**: ~$0.0125/GB for IA storage
- **Backup Storage**: ~$0.05/GB
- **Data Transfer**: ~$0.01-0.02/GB

### Activation Costs

- **Compute Scale-up**: Based on instance types and count
- **Increased Database Capacity**: Upgrading replica instances
- **Network Traffic**: Cross-region data transfer during activation

## Best Practices

1. **Regular Testing**: Test monthly or quarterly
2. **Documentation**: Keep runbooks updated
3. **Monitoring**: Set appropriate thresholds
4. **Automation**: Automate as much as possible
5. **Cost Tracking**: Monitor pilot light costs
6. **Compliance**: Regular compliance audits
7. **Training**: Ensure team knows procedures
8. **Communication**: Clear escalation paths

## Troubleshooting

### Common Issues

1. **High Replication Lag**
   - Check network connectivity
   - Verify instance sizes
   - Review data volumes

2. **Activation Failures**
   - Check IAM permissions
   - Verify resource limits
   - Review dependency order

3. **Test Failures**
   - Check test scenarios
   - Verify rollback procedures
   - Review test data

4. **Cost Overruns**
   - Review running resources
   - Check data transfer
   - Optimize storage classes

## Compliance Considerations

- **RTO/RPO Tracking**: Automated measurement and reporting
- **Audit Trails**: All actions logged to CloudTrail
- **Data Residency**: Enforced through region selection
- **Encryption**: At-rest and in-transit encryption
- **Access Control**: IAM policies and cross-account roles
- **Testing Evidence**: Test results stored and retained