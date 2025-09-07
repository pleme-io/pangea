# Web Application Architecture

Production-ready 3-tier web application architecture with load balancing, auto-scaling, database, monitoring, and optional caching/CDN capabilities.

## Overview

The Web Application Architecture creates a complete, production-ready infrastructure for web applications. It automatically configures networking, security, compute resources, database, monitoring, and optional performance enhancements based on environment and requirements.

## Architecture Components

### Core Infrastructure
- **VPC with Public/Private Subnets**: Multi-AZ network foundation with proper isolation
- **Application Load Balancer**: SSL termination, health checks, and traffic distribution  
- **Auto Scaling Group**: Elastic compute capacity with configurable scaling policies
- **RDS Database**: Managed database with backups, encryption, and multi-AZ support
- **Security Groups**: Least-privilege security rules for each tier

### Optional Components
- **ElastiCache Redis**: In-memory caching for improved performance
- **CloudFront CDN**: Global content delivery network
- **Route53 DNS**: Custom domain management
- **ACM SSL Certificate**: Automatic SSL certificate provisioning
- **CloudWatch Monitoring**: Comprehensive monitoring, logging, and alerting

## Usage

### Basic Web Application

```ruby
web_app = web_application_architecture(:myapp, {
  domain_name: "myapp.com",
  environment: "production"
})

# Architecture automatically configures:
# - Multi-AZ VPC with public/private subnets
# - Application Load Balancer with SSL termination
# - Auto Scaling Group (min: 2, max: 10)
# - MySQL RDS database with Multi-AZ
# - CloudWatch monitoring and alarms
# - Security groups with proper isolation
```

### Development Environment

```ruby
dev_app = web_application_architecture(:myapp_dev, {
  domain_name: "dev.myapp.com",
  environment: "development",
  auto_scaling: { min: 1, max: 2 },
  instance_type: "t3.micro",
  database_instance_class: "db.t3.micro",
  high_availability: false
})
```

### Production with Performance Features

```ruby
prod_app = web_application_architecture(:myapp_prod, {
  domain_name: "myapp.com",
  environment: "production",
  
  # High performance configuration
  instance_type: "c5.large",
  auto_scaling: { min: 3, max: 20, desired: 5 },
  
  # Database optimization
  database_engine: "aurora-mysql",
  database_instance_class: "db.r5.xlarge",
  
  # Performance features
  enable_caching: true,
  enable_cdn: true,
  
  # Security enhancements
  security: {
    enable_waf: true,
    enable_ddos_protection: true,
    compliance_standards: ["PCI-DSS"]
  }
})
```

## Configuration Parameters

### Required Parameters

- **domain_name**: Primary domain for the application
- **environment**: Deployment environment (`development`, `staging`, `production`)

### Network Configuration

```ruby
# Network settings
region: "us-east-1",
vpc_cidr: "10.0.0.0/16", 
availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"]
```

### Compute Configuration

```ruby
# Instance and scaling settings
instance_type: "t3.medium",
auto_scaling: {
  min: 2,
  max: 10,
  desired: 3
}
```

### Database Configuration

```ruby
# Database settings
database_enabled: true,
database_engine: "mysql",  # mysql, postgresql, aurora
database_instance_class: "db.t3.small",
database_allocated_storage: 100,
high_availability: true  # Enables Multi-AZ
```

### Performance Features

```ruby
# Performance optimization
enable_caching: true,      # ElastiCache Redis cluster
enable_cdn: true,          # CloudFront distribution
ssl_certificate_arn: "...", # Custom SSL cert (optional)
```

### Security Configuration

```ruby
security: {
  encryption_at_rest: true,
  encryption_in_transit: true,
  enable_waf: true,
  enable_ddos_protection: true,
  compliance_standards: ["SOC2", "PCI-DSS"]
}
```

### Monitoring Configuration

```ruby
monitoring: {
  detailed_monitoring: true,
  enable_logging: true,
  log_retention_days: 30,
  enable_alerting: true,
  enable_tracing: false
}
```

### Backup Configuration

```ruby
backup: {
  backup_schedule: "daily",
  retention_days: 30,
  cross_region_backup: true,
  point_in_time_recovery: true
}
```

## Environment Defaults

The architecture automatically applies environment-appropriate defaults:

### Development
- **Instance Type**: t3.micro
- **Auto Scaling**: min=1, max=2
- **Database**: db.t3.micro
- **High Availability**: false  
- **Caching**: disabled
- **CDN**: disabled
- **Backup Retention**: 1 day

### Staging  
- **Instance Type**: t3.small
- **Auto Scaling**: min=1, max=4
- **Database**: db.t3.small
- **High Availability**: true
- **Caching**: enabled
- **CDN**: disabled
- **Backup Retention**: 3 days

### Production
- **Instance Type**: t3.medium
- **Auto Scaling**: min=2, max=10
- **Database**: db.r5.large
- **High Availability**: true
- **Caching**: enabled
- **CDN**: enabled  
- **Backup Retention**: 30 days
- **WAF & DDoS Protection**: enabled

## Architecture Outputs

### Primary Outputs
```ruby
web_app.application_url          # https://myapp.com
web_app.load_balancer_dns        # myapp-alb-123.us-east-1.elb.amazonaws.com
web_app.database_endpoint        # myapp-db.cluster-xyz.rds.amazonaws.com
```

### Optional Outputs
```ruby
web_app.cdn_domain              # d1234567890.cloudfront.net
web_app.monitoring_dashboard_url # CloudWatch dashboard URL
web_app.estimated_monthly_cost   # $247.50
```

### Architecture Capabilities
```ruby
web_app.capabilities = {
  high_availability: true,
  auto_scaling: true,
  caching: true,
  cdn: true,
  ssl_termination: true,
  monitoring: true,
  backup: true
}
```

## Architecture Validation

### Security Compliance Score
```ruby
web_app.security_compliance_score  # 95.2
```

### High Availability Score  
```ruby
web_app.high_availability_score    # 88.0
```

### Performance Score
```ruby
web_app.performance_score          # 92.5
```

## Cost Estimation

### Monthly Cost Breakdown
```ruby
web_app.cost_breakdown = {
  components: {
    load_balancer: 22.0,
    web_servers: 204.0,    # 3 x t3.medium
    database: 180.0,       # db.r5.large Multi-AZ  
    cache: 15.0,           # ElastiCache
    cdn: 10.0              # CloudFront
  },
  total: 431.0
}
```

## Customization and Overrides

### Override Database with Aurora Serverless
```ruby
web_app.override(:database) do |arch_ref|
  aurora_serverless_cluster(:"#{arch_ref.name}_db", {
    engine: "aurora-mysql",
    vpc_ref: arch_ref.network.vpc,
    scaling: { min_capacity: 2, max_capacity: 16 }
  })
end
```

### Extend with Additional Components
```ruby
web_app.extend_with({
  api_gateway: aws_api_gateway_rest_api(:"#{web_app.name}_api", {
    description: "API Gateway for #{web_app.name}"
  }),
  
  lambda_functions: aws_lambda_function(:"#{web_app.name}_processor", {
    runtime: "python3.9",
    handler: "lambda_function.lambda_handler"
  })
})
```

### Compose with Other Architectures
```ruby
web_app.compose_with do |arch_ref|
  # Add data analytics pipeline
  arch_ref.analytics = data_lake_architecture(:"#{arch_ref.name}_analytics", {
    vpc_ref: arch_ref.network.vpc,
    source_database: arch_ref.database
  })
end
```

## Template Integration

### Basic Template Usage
```ruby
template :web_application do
  include Pangea::Architectures
  
  web_app = web_application_architecture(:myapp, {
    domain_name: "myapp.com",
    environment: "production"
  })
  
  output :application_url do
    value web_app.application_url
  end
  
  output :monthly_cost do
    value web_app.estimated_monthly_cost
  end
end
```

### Multi-Environment Deployment
```ruby
template :multi_environment_web_app do
  include Pangea::Architectures
  
  environments = ["development", "staging", "production"]
  
  environments.each do |env|
    web_app = web_application_architecture(:"myapp_#{env}", {
      domain_name: "#{env == 'production' ? '' : env + '.'}myapp.com",
      environment: env
    })
    
    output :"#{env}_url" do
      value web_app.application_url
    end
  end
end
```

## Best Practices

1. **Environment Separation**: Use separate architectures per environment
2. **Domain Strategy**: Use subdomains for non-production environments  
3. **Scaling Configuration**: Set appropriate min/max based on traffic patterns
4. **Database Sizing**: Choose instance classes based on performance requirements
5. **Security**: Enable WAF and DDoS protection for production
6. **Monitoring**: Always enable detailed monitoring and alerting
7. **Backup Strategy**: Configure appropriate retention for your RPO requirements
8. **Cost Optimization**: Use spot instances for development environments
9. **SSL Certificates**: Let the architecture manage ACM certificates automatically
10. **Tags**: Use consistent tagging for cost allocation and management

## Troubleshooting

### High Costs
- Review instance types and auto scaling settings
- Consider using spot instances for non-production
- Optimize database instance class selection

### Performance Issues  
- Enable caching with ElastiCache
- Add CloudFront CDN for static content
- Consider upgrading instance types

### Security Compliance
- Enable WAF and DDoS protection
- Ensure encryption at rest and in transit
- Review security group rules

### High Availability Issues
- Verify Multi-AZ database configuration
- Ensure auto scaling spans multiple availability zones
- Check load balancer health check configuration