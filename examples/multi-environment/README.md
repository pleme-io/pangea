# Multi-Environment Deployment Infrastructure

This example demonstrates how to use Pangea's namespace system to deploy the same infrastructure across multiple environments with environment-specific configurations, security policies, and resource sizing.

## Overview

The multi-environment infrastructure includes:

- **Environment-Aware Templates**: Automatic adaptation based on namespace
- **Progressive Feature Enablement**: Features enabled as environments mature
- **Cost Optimization**: Right-sized resources per environment
- **Security Scaling**: Security controls appropriate to environment sensitivity
- **Operational Controls**: Monitoring and alerting based on criticality

## Environment Characteristics

### Development
- **Purpose**: Local development and testing
- **Resources**: Minimal (t3.micro instances, single AZ)
- **Security**: Relaxed (open SSH, no SSL required)
- **Features**: Debugging enabled, short log retention
- **Cost**: Lowest

### Staging
- **Purpose**: Pre-production testing
- **Resources**: Moderate (t3.small instances, 2 AZs)
- **Security**: Moderate (VPC-only SSH, optional SSL)
- **Features**: Basic monitoring, 7-day backups
- **Cost**: Medium

### Production
- **Purpose**: Live production traffic
- **Resources**: Full (t3.medium+ instances, 3 AZs)
- **Security**: Strict (VPC-only access, SSL required)
- **Features**: CloudFront CDN, WAF, enhanced monitoring
- **Cost**: Highest (but optimized)

## Architecture Comparison

| Feature | Development | Staging | Production |
|---------|------------|---------|------------|
| VPC CIDR | 10.2.0.0/16 | 10.1.0.0/16 | 10.0.0.0/16 |
| Availability Zones | 2 | 2 | 3 |
| NAT Gateways | 1 | 1 | 3 (HA) |
| Instance Type | t3.micro | t3.small | t3.medium |
| Min/Max Instances | 1/3 | 2/6 | 3/20 |
| Database Class | db.t3.micro | db.t3.medium | db.r5.large |
| Multi-AZ Database | No | No | Yes |
| Database Backups | 1 day | 7 days | 30 days |
| Read Replica | No | No | Yes |
| CloudFront CDN | No | No | Yes |
| WAF Protection | No | No | Yes |
| SSL Certificate | No | Optional | Required |
| Monitoring | Basic | Enhanced | Full |
| Log Retention | 7 days | 30 days | 90 days |

## Templates

### 1. Web Application (`web_application`)

Environment-aware web infrastructure:
- VPC with appropriate CIDR ranges
- Load balancer with SSL (production)
- Auto-scaling groups with environment sizing
- CloudWatch monitoring and alarms
- CloudFront CDN (production only)
- WAF protection (production only)

### 2. Database (`database`)

Environment-aware database configuration:
- RDS PostgreSQL with appropriate sizing
- Multi-AZ deployment (production)
- Automated backups with retention
- Read replicas (production)
- Performance Insights (production)
- Enhanced monitoring (production)

## Deployment

### Prerequisites

1. Configure AWS credentials
2. Create S3 buckets for state storage (staging/production)
3. Set up environment-specific variables if needed

### Development Environment

```bash
# Deploy to development (local state)
pangea apply infrastructure.rb

# Or explicitly specify namespace
pangea apply infrastructure.rb --namespace development
```

### Staging Environment

```bash
# Deploy to staging
pangea apply infrastructure.rb --namespace staging

# Review changes first
pangea plan infrastructure.rb --namespace staging
```

### Production Environment

```bash
# Set production-specific variables
export PROD_INSTANCE_TYPE=t3.large
export PROD_DB_INSTANCE_CLASS=db.r5.xlarge

# Deploy with manual approval
pangea apply infrastructure.rb --namespace production --no-auto-approve
```

### Multi-Region Production

```bash
# Deploy to EU region
export AWS_REGION=eu-west-1
pangea apply infrastructure.rb --namespace production_eu
```

## Environment Variables

### Global Variables
- `AWS_REGION`: Target AWS region (default: us-east-1)

### Development Variables
- `DEV_INSTANCE_TYPE`: Override instance type (default: t3.micro)
- `DEV_DB_INSTANCE_CLASS`: Override database class (default: db.t3.micro)

### Staging Variables
- `STAGING_INSTANCE_TYPE`: Override instance type (default: t3.small)
- `STAGING_DB_INSTANCE_CLASS`: Override database class (default: db.t3.medium)

### Production Variables
- `PROD_INSTANCE_TYPE`: Override instance type (default: t3.medium)
- `PROD_DB_INSTANCE_CLASS`: Override database class (default: db.r5.large)

## Cost Management

### Development Environment
- Single NAT Gateway saves ~$45/month
- t3.micro instances save ~$50/month vs production
- No Multi-AZ database saves ~$100/month
- Total monthly cost: ~$150-200

### Staging Environment
- Single NAT Gateway saves ~$90/month vs production
- Smaller instances save ~$100/month
- No read replica saves ~$150/month
- Total monthly cost: ~$300-400

### Production Environment
- Multi-AZ for high availability
- CloudFront for performance
- Enhanced monitoring for observability
- Total monthly cost: ~$800-1200

## Security Considerations

### Network Security
- **Development**: Open SSH for debugging
- **Staging**: VPC + office network SSH only
- **Production**: VPC-only SSH access

### Data Security
- **Development**: Optional encryption
- **Staging**: Encryption at rest
- **Production**: Full encryption + KMS

### Access Control
- **Development**: Relaxed for productivity
- **Staging**: Moderate controls
- **Production**: Strict IAM policies

## Monitoring and Alerting

### Development
- Basic CloudWatch metrics
- 7-day log retention
- No alarms configured

### Staging
- Enhanced CloudWatch metrics
- 30-day log retention
- Basic CPU alarms

### Production
- Full CloudWatch dashboard
- 90-day log retention
- Comprehensive alarms:
  - CPU utilization
  - Database connections
  - Auto-scaling events
  - Application errors

## Disaster Recovery

### Backup Strategy
- **Development**: 1-day retention
- **Staging**: 7-day retention
- **Production**: 30-day retention + point-in-time recovery

### Recovery Time Objectives
- **Development**: Best effort
- **Staging**: 4 hours
- **Production**: 1 hour RTO, 15 minute RPO

## Troubleshooting

### Common Issues

1. **State Lock Conflicts**
   ```bash
   # Force unlock if needed (use carefully)
   terraform force-unlock LOCK_ID
   ```

2. **Resource Limits**
   - Check service quotas in AWS console
   - Request limit increases for production

3. **Cross-Environment References**
   - Ensure no hard-coded environment values
   - Use namespace variable for all resources

## Promoting Between Environments

### Development → Staging
```bash
# Test in development
pangea apply infrastructure.rb --namespace development

# If successful, promote to staging
pangea apply infrastructure.rb --namespace staging
```

### Staging → Production
```bash
# Validate in staging
pangea plan infrastructure.rb --namespace staging

# Deploy to production with approval
pangea apply infrastructure.rb --namespace production --no-auto-approve
```

## Clean Up

Remove infrastructure in each environment:

```bash
# Development (least critical)
pangea destroy infrastructure.rb --namespace development

# Staging
pangea destroy infrastructure.rb --namespace staging

# Production (requires approval)
pangea destroy infrastructure.rb --namespace production --no-auto-approve
```

## Best Practices

1. **Always test in development first**
2. **Use staging for integration testing**
3. **Require manual approval for production**
4. **Monitor costs across environments**
5. **Regular disaster recovery testing**

## Next Steps

1. Add more environments (QA, performance testing)
2. Implement blue/green deployments
3. Add container orchestration (ECS/EKS)
4. Integrate with CI/CD pipelines
5. Implement GitOps workflows