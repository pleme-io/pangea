# Global Multi-Region Infrastructure

This example demonstrates how to deploy globally distributed infrastructure across multiple AWS regions using Pangea, featuring cross-region replication, global traffic management, and region-specific configurations.

## Overview

The global multi-region infrastructure includes:

- **Global Traffic Management**: Route 53 with geolocation and latency routing
- **Content Delivery**: CloudFront CDN with regional origins
- **Cross-Region Replication**: DynamoDB Global Tables and S3 replication
- **Regional Failover**: Automated failover between regions
- **Global Monitoring**: Centralized monitoring across all regions
- **Data Sovereignty**: Region-specific data storage and processing

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Global Users                                 │
└─────────────────────┬───────────────┬───────────┬──────────────────┘
                      │               │           │
          ┌───────────▼─────────┐     │     ┌─────▼──────────┐
          │   Route 53          │     │     │  CloudFront    │
          │ (DNS + Health Check)│     │     │  (Global CDN)  │
          └───────────┬─────────┘     │     └────────────────┘
                      │               │
     ┌────────────────┴───────────────┴────────────────┐
     │                                                  │
┌────▼─────────┐  ┌────▼─────────┐  ┌────▼─────────┐  ┌────▼─────────┐
│  US-EAST-1   │  │  US-WEST-2   │  │ EU-CENTRAL-1 │  │AP-SOUTHEAST-1│
│  (Primary)   │  │ (Secondary)  │  │   (Europe)   │  │ (Asia Pac)   │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
     │                 │                 │                 │
┌────┴─────────────────┴─────────────────┴─────────────────┴────┐
│                    Per Region Infrastructure:                   │
│                                                                 │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐       │
│  │     VPC     │  │     ALB      │  │  Auto Scaling  │       │
│  │ (Regional)  │  │ (Regional LB) │  │    Groups      │       │
│  └─────────────┘  └──────────────┘  └────────────────┘       │
│                                                                 │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐       │
│  │  RDS with   │  │  DynamoDB    │  │ ElastiCache    │       │
│  │ Read Replica│  │ Global Table │  │   Cluster      │       │
│  └─────────────┘  └──────────────┘  └────────────────┘       │
│                                                                 │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐       │
│  │ S3 Buckets  │  │   Lambda     │  │  CloudWatch    │       │
│  │(Cross-Region│  │  Functions   │  │  (Regional)    │       │
│  │ Replication)│  │              │  │                │       │
│  └─────────────┘  └──────────────┘  └────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
                                │
                    ┌───────────▼──────────────┐
                    │   Global Services:        │
                    │  - IAM (Global)          │
                    │  - CloudWatch Dashboards │
                    │  - AWS Organizations     │
                    └──────────────────────────┘
```

## Templates

### 1. Global Resources (`global_resources`)

Resources that span all regions:
- Route 53 hosted zones and health checks
- CloudFront distributions
- IAM roles for cross-region access
- Global CloudWatch dashboards
- Cost allocation tags

### 2. Regional Infrastructure (`regional_infrastructure`)

Per-region infrastructure components:
- VPC with public/private subnets
- Application Load Balancers
- Auto Scaling Groups
- RDS instances with read replicas
- ElastiCache clusters
- Regional monitoring

### 3. Cross-Region Services (`cross_region_services`)

Services that work across regions:
- DynamoDB Global Tables
- S3 Cross-Region Replication
- Lambda@Edge functions
- EventBridge global event bus
- Cross-region VPC peering

## Deployment Strategy

### Sequential Deployment Order

1. **Global Resources First**
   ```bash
   # Deploy global resources (Route 53, CloudFront, IAM)
   pangea apply infrastructure.rb --namespace global --template global_resources
   ```

2. **Primary Region**
   ```bash
   # Deploy primary region (US-EAST-1)
   export AWS_REGION=us-east-1
   pangea apply infrastructure.rb --namespace us_east_1 --template regional_infrastructure
   ```

3. **Secondary Regions**
   ```bash
   # Deploy other regions
   export AWS_REGION=us-west-2
   pangea apply infrastructure.rb --namespace us_west_2 --template regional_infrastructure
   
   export AWS_REGION=eu-central-1
   pangea apply infrastructure.rb --namespace eu_central_1 --template regional_infrastructure
   
   export AWS_REGION=ap-southeast-1
   pangea apply infrastructure.rb --namespace ap_southeast_1 --template regional_infrastructure
   ```

4. **Cross-Region Services**
   ```bash
   # Deploy cross-region services last
   pangea apply infrastructure.rb --namespace global --template cross_region_services
   ```

## Region-Specific Configuration

### Environment Variables

Set region-specific variables before deployment:

```bash
# US East 1 (Primary)
export AWS_REGION=us-east-1
export VPC_CIDR=10.0.0.0/16
export IS_PRIMARY=true
export DB_INSTANCE_CLASS=db.r5.xlarge

# US West 2 (Secondary)
export AWS_REGION=us-west-2
export VPC_CIDR=10.1.0.0/16
export IS_PRIMARY=false
export DB_INSTANCE_CLASS=db.r5.large

# EU Central 1
export AWS_REGION=eu-central-1
export VPC_CIDR=10.2.0.0/16
export IS_PRIMARY=false
export DB_INSTANCE_CLASS=db.r5.large
export GDPR_COMPLIANCE=true

# AP Southeast 1
export AWS_REGION=ap-southeast-1
export VPC_CIDR=10.3.0.0/16
export IS_PRIMARY=false
export DB_INSTANCE_CLASS=db.r5.large
```

## Traffic Management

### Route 53 Configuration

```hcl
# Geolocation routing
resource "aws_route53_record" "www_eu" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.example.com"
  type    = "A"
  
  alias {
    name                   = aws_lb.eu_central_1.dns_name
    zone_id                = aws_lb.eu_central_1.zone_id
    evaluate_target_health = true
  }
  
  geolocation_routing_policy {
    continent = "EU"
  }
}

# Latency-based routing
resource "aws_route53_record" "api_latency" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.example.com"
  type    = "A"
  
  alias {
    name                   = aws_lb.regional.dns_name
    zone_id                = aws_lb.regional.zone_id
    evaluate_target_health = true
  }
  
  latency_routing_policy {
    region = var.aws_region
  }
}
```

## Data Replication

### DynamoDB Global Tables

```python
# Create global table
import boto3

dynamodb = boto3.client('dynamodb', region_name='us-east-1')

response = dynamodb.create_global_table(
    GlobalTableName='user-sessions',
    ReplicationGroup=[
        {'RegionName': 'us-east-1'},
        {'RegionName': 'us-west-2'},
        {'RegionName': 'eu-central-1'},
        {'RegionName': 'ap-southeast-1'}
    ]
)
```

### S3 Cross-Region Replication

```python
# Configure replication
s3 = boto3.client('s3')

replication_config = {
    'Role': 'arn:aws:iam::123456789012:role/s3-replication-role',
    'Rules': [
        {
            'ID': 'replicate-to-all-regions',
            'Status': 'Enabled',
            'Priority': 1,
            'Filter': {},
            'Destinations': [
                {
                    'Bucket': 'arn:aws:s3:::my-bucket-us-west-2',
                    'ReplicationTime': {
                        'Status': 'Enabled',
                        'Time': {'Minutes': 15}
                    },
                    'Metrics': {'Status': 'Enabled'},
                    'StorageClass': 'STANDARD_IA'
                }
            ]
        }
    ]
}

s3.put_bucket_replication(
    Bucket='my-bucket-us-east-1',
    ReplicationConfiguration=replication_config
)
```

## Monitoring

### Global Dashboard

```python
# Create multi-region CloudWatch dashboard
import boto3
import json

cloudwatch = boto3.client('cloudwatch', region_name='us-east-1')

dashboard_body = {
    "widgets": [
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    ["AWS/ELB", "RequestCount", {"region": "us-east-1"}],
                    ["...", {"region": "us-west-2"}],
                    ["...", {"region": "eu-central-1"}],
                    ["...", {"region": "ap-southeast-1"}]
                ],
                "period": 300,
                "stat": "Sum",
                "region": "us-east-1",
                "title": "Request Count by Region"
            }
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    ["AWS/ELB", "TargetResponseTime", {"region": "us-east-1"}],
                    ["...", {"region": "us-west-2"}],
                    ["...", {"region": "eu-central-1"}],
                    ["...", {"region": "ap-southeast-1"}]
                ],
                "period": 300,
                "stat": "Average",
                "region": "us-east-1",
                "title": "Response Time by Region"
            }
        }
    ]
}

cloudwatch.put_dashboard(
    DashboardName='Global-Infrastructure-Dashboard',
    DashboardBody=json.dumps(dashboard_body)
)
```

## Disaster Recovery

### Automated Failover

1. **Health Checks**
   - Route 53 monitors endpoint health
   - CloudWatch alarms trigger failover
   - Lambda functions coordinate recovery

2. **RTO/RPO Targets**
   - RTO: < 5 minutes (automated failover)
   - RPO: < 1 minute (real-time replication)

3. **Failover Testing**
   ```bash
   # Simulate region failure
   ./scripts/simulate-region-failure.sh us-east-1
   
   # Verify traffic routing
   ./scripts/verify-failover.sh
   
   # Restore primary region
   ./scripts/restore-region.sh us-east-1
   ```

## Cost Optimization

### Regional Cost Management

1. **Reserved Instances**
   - Purchase RIs in primary regions
   - Use On-Demand in secondary regions
   - Leverage Savings Plans for compute

2. **Data Transfer Optimization**
   - Use CloudFront for edge caching
   - Implement regional data locality
   - Minimize cross-region transfers

3. **Resource Right-Sizing**
   - Larger instances in primary regions
   - Smaller instances in secondary regions
   - Auto-scale based on regional demand

### Cost Monitoring

```bash
# Regional cost breakdown
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=REGION
```

## Security Considerations

### Cross-Region Security

1. **Encryption**
   - Region-specific KMS keys
   - Cross-region key policies
   - Encrypted replication

2. **Network Security**
   - Regional security groups
   - Cross-region VPC peering encryption
   - Regional WAF rules

3. **Compliance**
   - Data residency requirements
   - Regional compliance standards
   - Audit logging per region

## Troubleshooting

### Common Issues

1. **Replication Lag**
   - Monitor replication metrics
   - Check network connectivity
   - Verify IAM permissions

2. **Regional Service Limits**
   - Request limit increases per region
   - Monitor service quotas
   - Plan for regional constraints

3. **Cross-Region Latency**
   - Use CloudFront for static content
   - Implement regional caching
   - Optimize data access patterns

## Clean Up

Remove infrastructure by region:

```bash
# Remove cross-region services first
pangea destroy infrastructure.rb --namespace global --template cross_region_services

# Remove regional infrastructure
pangea destroy infrastructure.rb --namespace ap_southeast_1
pangea destroy infrastructure.rb --namespace eu_central_1
pangea destroy infrastructure.rb --namespace us_west_2
pangea destroy infrastructure.rb --namespace us_east_1

# Remove global resources last
pangea destroy infrastructure.rb --namespace global --template global_resources
```

## Next Steps

1. Implement automated deployment pipeline
2. Add more regions based on user distribution
3. Implement regional A/B testing
4. Set up cross-region data analytics
5. Add edge computing with Lambda@Edge