# Basic Web Application Infrastructure

This example demonstrates a complete web application infrastructure using Pangea with template-level isolation and multi-environment support.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
└─────────────────────────────────────────────────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │  Application Load   │
                    │     Balancer        │
                    └──────────┬──────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
┌───────┴────────┐    ┌────────┴───────┐    ┌────────┴───────┐
│  Public Subnet │    │  Public Subnet  │    │   NAT Gateway  │
│   (Zone A)     │    │   (Zone B)      │    │                │
└────────────────┘    └─────────────────┘    └────────┬───────┘
                                                       │
        ┌──────────────────────┬──────────────────────┘
        │                      │
┌───────┴────────┐    ┌────────┴───────┐
│ Private Subnet │    │ Private Subnet │
│   (Zone A)     │    │   (Zone B)     │
│                │    │                │
│  ┌─────────┐   │    │  ┌─────────┐  │
│  │   EC2   │   │    │  │   EC2   │  │
│  │Instance │   │    │  │Instance │  │
│  └─────────┘   │    │  └─────────┘  │
└────────────────┘    └─────────────────┘
```

## Features

- **Multi-AZ deployment** for high availability
- **Auto Scaling Group** with CPU-based scaling policies
- **Application Load Balancer** for traffic distribution
- **NAT Gateways** for outbound internet access from private subnets
- **CloudWatch monitoring** with custom metrics
- **S3 bucket** for centralized logging
- **Security groups** with least-privilege access

## Directory Structure

```
basic-web-app/
├── pangea.yaml          # Pangea configuration with namespace definitions
├── infrastructure.rb    # Main infrastructure template
└── README.md           # This file
```

## Configuration

The `pangea.yaml` file defines three environments:

1. **development** - Local state for development
2. **staging** - S3 backend for staging environment
3. **production** - S3 backend with KMS encryption for production

## Usage

### Local Development

```bash
# Preview changes
pangea plan infrastructure.rb

# Apply infrastructure
pangea apply infrastructure.rb
```

### Staging Deployment

```bash
# Preview changes
pangea plan infrastructure.rb --namespace staging

# Apply infrastructure
pangea apply infrastructure.rb --namespace staging
```

### Production Deployment

```bash
# Preview changes
pangea plan infrastructure.rb --namespace production

# Apply infrastructure
pangea apply infrastructure.rb --namespace production
```

## Customization

### Variables

The template supports several variables for customization:

- `environment` - Environment name (default: "development")
- `aws_region` - AWS region for deployment (default: "us-east-1")
- `app_name` - Application name for resource naming (default: "basic-web-app")
- `instance_type` - EC2 instance type (default: "t3.micro")
- `min_instances` - Minimum ASG instances (default: 1)
- `max_instances` - Maximum ASG instances (default: 4)
- `desired_instances` - Desired ASG instances (default: 2)

### Override Variables

You can override variables when running Pangea:

```bash
# Deploy with custom instance type
pangea apply infrastructure.rb --var instance_type=t3.small

# Deploy to different region
pangea apply infrastructure.rb --var aws_region=us-west-2
```

## Outputs

After deployment, the following outputs are available:

- `alb_dns_name` - DNS name of the load balancer
- `alb_url` - Full URL to access the application
- `vpc_id` - VPC identifier
- `public_subnet_ids` - List of public subnet IDs
- `private_subnet_ids` - List of private subnet IDs
- `asg_name` - Auto Scaling Group name
- `log_bucket` - S3 bucket for logs

## Scaling

The infrastructure automatically scales based on CPU utilization:

- **Scale Up**: When average CPU > 70% for 10 minutes
- **Scale Down**: When average CPU < 30% for 10 minutes

## Security

- All instances are in private subnets
- Security groups restrict access to only necessary ports
- ALB handles public traffic termination
- S3 bucket encryption enabled for logs
- IAM instance profiles use least-privilege principles

## Cost Optimization

For development/testing:
- Use smaller instance types (t3.micro)
- Reduce min_instances to 1
- Consider using a single NAT Gateway

For production:
- Use appropriate instance types for workload
- Enable reserved instances for predictable workloads
- Consider Spot instances for non-critical workloads

## Monitoring

CloudWatch metrics are automatically collected:
- CPU utilization
- Memory usage
- Disk usage
- ALB request count and latency
- Auto Scaling Group metrics

## Next Steps

1. Add RDS database (see multi-tier-architecture example)
2. Implement HTTPS with ACM certificate
3. Add CloudFront CDN for static assets
4. Implement centralized logging with CloudWatch Logs
5. Add application deployment pipeline