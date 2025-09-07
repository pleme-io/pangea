# Multi-Tier Architecture Infrastructure

This example demonstrates Pangea's template isolation pattern with a classic three-tier web application architecture. Each tier is managed as a separate template with its own state file, enabling independent deployment and scaling.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└─────────────────────────────────────────────────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │  Application Load   │
                    │     Balancer        │
                    │  (Public Subnets)   │
                    └──────────┬──────────┘
                               │
┌──────────────────────────────┼──────────────────────────────┐
│                              │              Networking Layer  │
│  ┌────────────────┐ ┌────────┴────────┐ ┌────────────────┐ │
│  │ Public Subnet  │ │  Public Subnet  │ │ Public Subnet  │ │
│  │    Zone A      │ │    Zone B       │ │    Zone C      │ │
│  │                │ │                 │ │                │ │
│  │ NAT Gateway A  │ │ NAT Gateway B   │ │ NAT Gateway C  │ │
│  └────────┬───────┘ └────────┬────────┘ └────────┬───────┘ │
└───────────┼──────────────────┼───────────────────┼──────────┘
            │                  │                    │
┌───────────┼──────────────────┼───────────────────┼──────────┐
│           │                  │                    │  App Layer│
│  ┌────────┴────────┐ ┌──────┴─────────┐ ┌───────┴────────┐ │
│  │ Private App     │ │ Private App    │ │ Private App    │ │
│  │ Subnet Zone A   │ │ Subnet Zone B  │ │ Subnet Zone C  │ │
│  │                 │ │                │ │                │ │
│  │ ┌─────────────┐ │ │ ┌────────────┐ │ │ ┌────────────┐ │ │
│  │ │ EC2 Instance│ │ │ │EC2 Instance│ │ │ │EC2 Instance│ │ │
│  │ │ (App Server)│ │ │ │(App Server)│ │ │ │(App Server)│ │ │
│  │ └─────────────┘ │ │ └────────────┘ │ │ └────────────┘ │ │
│  └─────────────────┘ └────────────────┘ └─────────────────┘ │
└──────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────────────┐
│                              │                    Data Layer │
│  ┌────────────────┐ ┌────────┴────────┐ ┌────────────────┐ │
│  │ Private DB     │ │ Private DB      │ │ Private DB     │ │
│  │ Subnet Zone A  │ │ Subnet Zone B   │ │ Subnet Zone C  │ │
│  └────────────────┘ └─────────────────┘ └────────────────┘ │
│                                                              │
│                    ┌─────────────────┐                       │
│                    │   RDS MySQL     │                       │
│                    │  (Primary DB)   │                       │
│                    └─────────────────┘                       │
└──────────────────────────────────────────────────────────────┘
```

## Templates

### 1. Networking Template (`networking`)
- **Purpose**: Creates foundational network infrastructure
- **Resources**:
  - VPC with DNS support
  - 3 Public subnets (one per AZ)
  - 3 Private application subnets
  - 3 Private database subnets
  - NAT Gateways for each AZ (high availability)
  - Security groups for each tier
  - Route tables and associations
- **State**: Isolated in `networking` workspace

### 2. Application Template (`application`)
- **Purpose**: Manages web application infrastructure
- **Resources**:
  - Application Load Balancer
  - Auto Scaling Group with launch template
  - Target groups and health checks
  - IAM roles for EC2 instances
  - CloudWatch log groups
  - Target tracking auto-scaling policies
- **State**: Isolated in `application` workspace
- **Dependencies**: Reads outputs from `networking` template

### 3. Database Template (`database`)
- **Purpose**: Manages data persistence layer
- **Resources**:
  - RDS MySQL instance
  - Database subnet group
  - Automated backups
  - CloudWatch alarms for monitoring
  - SSM Parameter Store for credentials
  - CloudWatch log groups for database logs
- **State**: Isolated in `database` workspace
- **Dependencies**: Reads outputs from `networking` template

## Directory Structure

```
multi-tier-architecture/
├── pangea.yaml          # Namespace configuration
├── infrastructure.rb    # All three templates
└── README.md           # This file
```

## Deployment Order

Due to cross-template dependencies, deploy in this order:

1. **Networking** - Creates VPC and security groups
2. **Database** - Creates RDS instance
3. **Application** - Creates app servers (optionally reads database endpoint)

## Usage

### Deploy All Templates

```bash
# Deploy networking layer
pangea apply infrastructure.rb --template networking

# Deploy database layer
pangea apply infrastructure.rb --template database

# Deploy application layer
pangea apply infrastructure.rb --template application
```

### Environment-Specific Deployment

```bash
# Deploy to staging
pangea apply infrastructure.rb --template networking --namespace staging
pangea apply infrastructure.rb --template database --namespace staging
pangea apply infrastructure.rb --template application --namespace staging

# Deploy to production
pangea apply infrastructure.rb --template networking --namespace production
pangea apply infrastructure.rb --template database --namespace production
pangea apply infrastructure.rb --template application --namespace production
```

### Update Individual Layers

```bash
# Update only the application layer
pangea plan infrastructure.rb --template application
pangea apply infrastructure.rb --template application

# Scale the database independently
pangea apply infrastructure.rb --template database --var db_instance_class=db.t3.medium
```

## Cross-Template Communication

Templates communicate through Terraform remote state data sources:

```ruby
# In application template, read networking outputs
data :terraform_remote_state, :networking do
  backend "local"
  config do
    path "../.terraform/workspaces/${var(:environment)}/networking/terraform.tfstate"
  end
end

# Use the outputs
locals do
  vpc_id data(:terraform_remote_state, :networking, :outputs, :vpc_id)
  subnet_ids data(:terraform_remote_state, :networking, :outputs, :private_app_subnet_ids)
end
```

## Variables

### Global Variables (all templates)
- `environment` - Environment name (development/staging/production)
- `aws_region` - AWS region for deployment

### Networking Variables
- `vpc_cidr` - CIDR block for VPC (default: 10.0.0.0/16)
- `availability_zones` - List of AZ suffixes (default: ["a", "b", "c"])

### Application Variables
- `instance_type` - EC2 instance type (default: t3.small)
- `min_size` - Minimum ASG instances (default: 2)
- `max_size` - Maximum ASG instances (default: 10)
- `desired_capacity` - Desired ASG instances (default: 3)

### Database Variables
- `db_instance_class` - RDS instance class (default: db.t3.micro)
- `db_allocated_storage` - Storage in GB (default: 20)
- `db_name` - Database name (default: appdatabase)
- `backup_retention_period` - Backup retention days (default: 7)
- `multi_az` - Enable Multi-AZ (default: false)

## Security

- **Network Isolation**: Each tier in separate subnets
- **Security Groups**: Strict ingress rules between tiers
- **Encryption**: RDS encryption at rest enabled
- **Secrets Management**: Database password in SSM Parameter Store
- **IAM Roles**: Least-privilege access for EC2 instances

## Monitoring

### Application Layer
- CloudWatch Logs for Apache access and error logs
- Custom metrics via CloudWatch Agent
- Auto-scaling based on CPU utilization

### Database Layer
- RDS Performance Insights
- CloudWatch alarms for CPU and storage
- Slow query logs exported to CloudWatch

## High Availability

- **Multi-AZ**: Resources spread across 3 availability zones
- **Auto-Scaling**: Application scales based on load
- **NAT Gateway HA**: One NAT Gateway per AZ
- **Load Balancing**: ALB distributes traffic across healthy instances
- **Database**: Optional Multi-AZ deployment for production

## Cost Optimization

### Development
```ruby
# Single NAT Gateway to save costs
availability_zones = ["a"]  # Only use one AZ
instance_type = "t3.micro"
multi_az = false
```

### Production
```ruby
# High availability configuration
availability_zones = ["a", "b", "c"]
instance_type = "t3.medium"
multi_az = true
backup_retention_period = 30
```

## Disaster Recovery

- **Automated Backups**: RDS automated backups with point-in-time recovery
- **Snapshots**: Manual snapshots before major changes
- **Multi-AZ**: Enable for production RDS instances
- **State Backup**: S3 backend with versioning for state files

## Template Benefits

1. **Independent Scaling**: Scale each tier independently
2. **Isolated State**: Failures in one tier don't affect others
3. **Team Ownership**: Different teams can own different tiers
4. **Gradual Rollout**: Deploy changes tier by tier
5. **Cost Control**: Destroy non-essential tiers when not needed

## Troubleshooting

### State Not Found Error
If you get "state not found" errors when deploying application/database templates:
1. Ensure networking template is deployed first
2. Check the state file path matches your backend configuration
3. Verify the namespace matches between templates

### Connection Issues
- Check security group rules allow traffic between tiers
- Verify subnets have proper route table associations
- Ensure NAT Gateways are functioning for outbound traffic

### Database Connection
- Database endpoint is output from database template
- Application servers read this via remote state
- Check SSM Parameter Store for database password