# Disaster Recovery Infrastructure

This example demonstrates a comprehensive disaster recovery (DR) architecture using Pangea, featuring automated failover, data replication, and recovery orchestration across AWS regions.

## Overview

The disaster recovery infrastructure includes:

- **Active-Passive DR**: Primary region with warm standby in DR region
- **Automated Failover**: Health monitoring and automatic failover
- **Data Replication**: Real-time replication of databases and storage
- **Recovery Orchestration**: Step Functions for coordinated recovery
- **DR Testing**: Non-disruptive DR testing capabilities
- **Runbook Automation**: Automated recovery procedures

## DR Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Route 53 (Global DNS)                             │
│                 Health Checks & Failover                             │
└──────────────────────┬─────────────────────┬────────────────────────┘
                       │                     │
         ┌─────────────▼──────────┐   ┌─────▼───────────────┐
         │   Primary Region        │   │   DR Region         │
         │   (US-EAST-1)          │   │   (US-WEST-2)       │
         │   Status: ACTIVE       │   │   Status: STANDBY   │
         └────────────────────────┘   └─────────────────────┘
                    │                           │
    ┌───────────────┴──────────────┐   ┌───────┴──────────────────┐
    │                              │   │                          │
    │  ┌────────────────────┐     │   │  ┌────────────────────┐ │
    │  │   CloudFront       │     │   │  │   CloudFront       │ │
    │  │   Distribution     │     │   │  │   (Standby)       │ │
    │  └─────────┬──────────┘     │   │  └─────────┬──────────┘ │
    │            │                 │   │            │            │
    │  ┌─────────▼──────────┐     │   │  ┌─────────▼──────────┐ │
    │  │   Load Balancer    │     │   │  │   Load Balancer    │ │
    │  │   (Active)         │     │   │  │   (Warm Standby)   │ │
    │  └─────────┬──────────┘     │   │  └─────────┬──────────┘ │
    │            │                 │   │            │            │
    │  ┌─────────▼──────────┐     │   │  ┌─────────▼──────────┐ │
    │  │   Auto Scaling     │     │   │  │   Auto Scaling     │ │
    │  │   (Full Capacity)  │     │   │  │   (Min Capacity)   │ │
    │  └────────────────────┘     │   │  └────────────────────┘ │
    │                              │   │                          │
    └───────────┬──────────────────┘   └────────────┬────────────┘
                │                                    │
    ┌───────────▼──────────────────┐   ┌────────────▼────────────┐
    │     Data Layer              │   │     Data Layer          │
    │  ┌────────────────────┐     │   │  ┌────────────────────┐ │
    │  │   RDS Primary      │─────┼───┼──│  RDS Read Replica  │ │
    │  │   (Multi-AZ)       │     │   │  │  (Promotable)      │ │
    │  └────────────────────┘     │   │  └────────────────────┘ │
    │                              │   │                          │
    │  ┌────────────────────┐     │   │  ┌────────────────────┐ │
    │  │   DynamoDB         │─────┼───┼──│  DynamoDB Global   │ │
    │  │   (Global Table)   │     │   │  │  Table Replica     │ │
    │  └────────────────────┘     │   │  └────────────────────┘ │
    │                              │   │                          │
    │  ┌────────────────────┐     │   │  ┌────────────────────┐ │
    │  │   S3 Buckets       │─────┼───┼──│  S3 Replicated     │ │
    │  │   (Primary)        │     │   │  │  Buckets           │ │
    │  └────────────────────┘     │   │  └────────────────────┘ │
    └──────────────────────────────┘   └──────────────────────────┘
                │                                    │
    ┌───────────▼──────────────────────────────────▼─────────────┐
    │              Recovery Orchestration Layer                   │
    │  ┌────────────────┐  ┌──────────────┐  ┌───────────────┐  │
    │  │ Step Functions │  │   Lambda     │  │  CloudWatch   │  │
    │  │ (Orchestration)│  │  (Recovery)  │  │  (Monitoring) │  │
    │  └────────────────┘  └──────────────┘  └───────────────┘  │
    └─────────────────────────────────────────────────────────────┘
```

## Templates

### 1. Primary Infrastructure (`primary_infrastructure`)

Production infrastructure in primary region:
- Full application stack
- Multi-AZ deployments
- Production capacity auto-scaling
- Primary databases
- Monitoring and alerting

### 2. DR Infrastructure (`dr_infrastructure`)

Standby infrastructure in DR region:
- Warm standby configuration
- Minimal capacity (cost-optimized)
- Read replicas (promotable)
- Replicated data stores
- Pre-staged recovery resources

### 3. Replication Services (`replication_services`)

Cross-region data replication:
- Database replication (RDS, DynamoDB)
- S3 cross-region replication
- EBS snapshot copying
- AMI replication
- Configuration sync

### 4. Recovery Automation (`recovery_automation`)

Failover orchestration:
- Step Functions workflows
- Lambda recovery functions
- Route 53 health checks
- CloudWatch alarms
- SNS notifications

## DR Strategies

### Recovery Time Objective (RTO): 15 minutes
### Recovery Point Objective (RPO): 1 minute

### 1. Pilot Light
- Minimal resources running in DR
- Data replication active
- Quick scale-up capability

### 2. Warm Standby
- Reduced capacity running
- All services operational
- Immediate failover ready

### 3. Hot Standby
- Full capacity in both regions
- Active-active configuration
- Zero downtime failover

## Deployment

### Initial Setup

1. **Deploy Shared Resources**
   ```bash
   pangea apply infrastructure.rb --namespace dr_shared
   ```

2. **Deploy Primary Region**
   ```bash
   export AWS_REGION=us-east-1
   export IS_PRIMARY=true
   pangea apply infrastructure.rb --namespace primary
   ```

3. **Deploy DR Region**
   ```bash
   export AWS_REGION=us-west-2
   export IS_PRIMARY=false
   pangea apply infrastructure.rb --namespace dr_standby
   ```

4. **Enable Replication**
   ```bash
   pangea apply infrastructure.rb --namespace dr_shared --template replication_services
   ```

5. **Deploy Recovery Automation**
   ```bash
   pangea apply infrastructure.rb --namespace recovery --template recovery_automation
   ```

## Failover Procedures

### Automated Failover

1. **Health Check Failure Detection**
   ```python
   # Route 53 health check configuration
   health_check = {
       'Type': 'HTTPS',
       'ResourcePath': '/health',
       'FullyQualifiedDomainName': 'app.example.com',
       'Port': 443,
       'RequestInterval': 30,
       'FailureThreshold': 3
   }
   ```

2. **Automatic DNS Failover**
   - Route 53 updates DNS records
   - Traffic routes to DR region
   - No manual intervention required

### Manual Failover

```bash
# Execute failover runbook
aws stepfunctions start-execution \
  --state-machine-arn arn:aws:states:us-east-1:123456789012:stateMachine:dr-failover \
  --input '{"action": "failover", "targetRegion": "us-west-2"}'

# Monitor failover progress
aws stepfunctions describe-execution \
  --execution-arn arn:aws:states:us-east-1:123456789012:execution:dr-failover:failover-20240115
```

## Recovery Runbooks

### 1. Database Failover

```python
# Promote RDS read replica
import boto3

rds = boto3.client('rds', region_name='us-west-2')

# Promote read replica to primary
response = rds.promote_read_replica(
    DBInstanceIdentifier='myapp-db-replica',
    BackupRetentionPeriod=7,
    PreferredBackupWindow='03:00-04:00'
)

# Update application connection strings
ssm = boto3.client('ssm', region_name='us-west-2')
ssm.put_parameter(
    Name='/myapp/db/endpoint',
    Value=response['DBInstance']['Endpoint']['Address'],
    Type='String',
    Overwrite=True
)
```

### 2. Application Scaling

```python
# Scale up DR region capacity
autoscaling = boto3.client('autoscaling', region_name='us-west-2')

# Update Auto Scaling Group
autoscaling.update_auto_scaling_group(
    AutoScalingGroupName='myapp-asg-dr',
    MinSize=3,
    MaxSize=20,
    DesiredCapacity=6
)

# Update target tracking policy
autoscaling.put_scaling_policy(
    AutoScalingGroupName='myapp-asg-dr',
    PolicyName='target-tracking-cpu',
    PolicyType='TargetTrackingScaling',
    TargetTrackingConfiguration={
        'PredefinedMetricSpecification': {
            'PredefinedMetricType': 'ASGAverageCPUUtilization'
        },
        'TargetValue': 70.0
    }
)
```

### 3. Cache Warming

```python
# Warm ElastiCache in DR region
def warm_cache(redis_client, primary_data):
    """Pre-populate cache with critical data"""
    for key, value in primary_data.items():
        redis_client.set(key, value, ex=3600)
    
    # Load frequently accessed data
    common_queries = get_common_queries()
    for query in common_queries:
        result = execute_query(query)
        cache_key = generate_cache_key(query)
        redis_client.set(cache_key, result, ex=3600)
```

## DR Testing

### Non-Disruptive Testing

1. **Route 53 Weighted Routing**
   ```python
   # Send 5% traffic to DR for testing
   route53.change_resource_record_sets(
       HostedZoneId='Z1234567890ABC',
       ChangeBatch={
           'Changes': [{
               'Action': 'UPSERT',
               'ResourceRecordSet': {
                   'Name': 'app.example.com',
                   'Type': 'A',
                   'SetIdentifier': 'DR-Test',
                   'Weight': 5,  # 5% of traffic
                   'AliasTarget': {
                       'HostedZoneId': dr_alb_zone_id,
                       'DNSName': dr_alb_dns_name,
                       'EvaluateTargetHealth': True
                   }
               }
           }]
       }
   )
   ```

2. **Isolated Testing Environment**
   ```bash
   # Deploy test environment
   export DR_TEST_MODE=true
   pangea apply infrastructure.rb --namespace dr_test
   
   # Run DR tests
   ./scripts/run-dr-tests.sh
   
   # Validate results
   ./scripts/validate-dr-readiness.sh
   ```

## Monitoring and Alerting

### Key Metrics

1. **Replication Lag**
   - RDS replica lag < 60 seconds
   - DynamoDB global table lag < 1 second
   - S3 replication time < 15 minutes

2. **Health Checks**
   - Primary region health
   - DR region readiness
   - Cross-region connectivity

3. **Recovery Metrics**
   - Time to failover
   - Data consistency
   - Application availability

### CloudWatch Dashboards

```python
# Create DR monitoring dashboard
dashboard_body = {
    "widgets": [
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    ["AWS/RDS", "ReplicaLag", {"DBInstanceIdentifier": "myapp-db-replica"}],
                    ["AWS/DynamoDB", "UserErrors", {"TableName": "myapp-global-table"}],
                    ["Custom", "ReplicationHealth", {"Region": "us-west-2"}]
                ],
                "period": 300,
                "stat": "Average",
                "region": "us-west-2",
                "title": "DR Replication Health"
            }
        }
    ]
}
```

## Cost Optimization

### Standby Cost Reduction

1. **Compute Resources**
   - Use smaller instance types in DR
   - Minimum auto-scaling capacity
   - Scheduled scaling for testing

2. **Storage Optimization**
   - Lifecycle policies for snapshots
   - Incremental backups only
   - Compressed replication

3. **Reserved Capacity**
   - Convertible RIs for flexibility
   - Capacity reservations for critical resources

### Monthly DR Costs (Estimate)
- Pilot Light: ~$500-1000
- Warm Standby: ~$2000-5000
- Hot Standby: ~100% of primary

## Compliance and Auditing

### DR Compliance Requirements

1. **Regular Testing**
   - Quarterly full failover tests
   - Monthly component tests
   - Weekly replication validation

2. **Documentation**
   - Runbook maintenance
   - Architecture diagrams
   - Contact lists

3. **Audit Trail**
   - All failover events logged
   - Recovery time tracking
   - Post-mortem reports

## Troubleshooting

### Common Issues

1. **Replication Failures**
   - Check IAM roles and permissions
   - Verify network connectivity
   - Monitor service limits

2. **Failover Delays**
   - DNS propagation time
   - Cache TTL settings
   - Health check sensitivity

3. **Data Inconsistency**
   - Validate replication status
   - Check for split-brain scenarios
   - Verify transaction ordering

## Clean Up

Remove DR infrastructure carefully:

```bash
# Disable replication first
pangea destroy infrastructure.rb --namespace dr_shared --template replication_services

# Remove recovery automation
pangea destroy infrastructure.rb --namespace recovery

# Remove DR infrastructure
pangea destroy infrastructure.rb --namespace dr_standby

# Keep primary running or remove if needed
# pangea destroy infrastructure.rb --namespace primary

# Remove shared resources last
pangea destroy infrastructure.rb --namespace dr_shared
```

## Next Steps

1. Implement chaos engineering tests
2. Add multi-region active-active setup
3. Integrate with incident management
4. Automate DR documentation updates
5. Implement cost anomaly detection