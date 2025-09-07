# Template Isolation: Pangea's Secret to Scalable Infrastructure

One of Pangea's most powerful features is template-level state isolation - a more granular approach than the industry-standard directory-based isolation used by traditional Terraform setups. This guide explores how template isolation solves real-world scaling challenges and enables teams to work on infrastructure without stepping on each other's toes.

## The Problem with Traditional Approaches

### Directory-Based Terraform Struggles

In traditional Terraform, teams typically organize infrastructure using directories:

```
terraform/
├── networking/
│   ├── main.tf
│   ├── terraform.tfstate
│   └── variables.tf
├── compute/
│   ├── main.tf
│   ├── terraform.tfstate
│   └── variables.tf
└── database/
    ├── main.tf
    ├── terraform.tfstate
    └── variables.tf
```

**Problems with this approach:**

1. **File Sprawl**: Infrastructure logic scattered across many directories
2. **Manual State Management**: Each directory needs separate backend configuration
3. **Coordination Overhead**: Teams must coordinate which directories to modify
4. **Limited Granularity**: One directory = one state file, regardless of logical components
5. **Difficult Refactoring**: Moving resources between directories requires state migration

### Terraform Workspaces Are Not the Answer

Terraform workspaces seem like a solution but have critical limitations:

```bash
terraform workspace new development
terraform workspace new staging
```

**Workspace limitations:**

- **Shared Backend**: All workspaces share the same backend configuration
- **No True Isolation**: Risk of workspace state corruption
- **Security Boundaries**: Difficult to implement different access controls per workspace
- **Naming Conflicts**: Resource names must be unique across all workspaces

## Pangea's Template Isolation Solution

### What Is Template Isolation?

Template isolation means each `template` block in your Ruby files gets:

1. **Its Own Workspace Directory**: Completely separate Terraform working directory
2. **Isolated State File**: No shared state, no conflicts
3. **Independent Lifecycle**: Deploy, update, and destroy independently
4. **Separate Backend Configuration**: Each template can have different backend settings

### Template Isolation in Action

Here's a single Pangea file with multiple isolated templates:

```ruby
# infrastructure.rb

template :networking do
  provider :aws do
    region "us-east-1"
  end
  
  resource :aws_vpc, :main do
    cidr_block "10.0.0.0/16"
    enable_dns_hostnames true
    
    tags do
      Name "Main-VPC"
      Team "platform"
    end
  end
  
  resource :aws_subnet, :public_a do
    vpc_id ref(:aws_vpc, :main, :id)
    cidr_block "10.0.1.0/24"
    availability_zone "us-east-1a"
    
    tags do
      Name "Public-Subnet-A"
    end
  end
end

template :compute do
  provider :aws do
    region "us-east-1"
  end
  
  # Reference VPC from networking template via data source
  data :aws_vpc, :main do
    filter do
      name "tag:Name"
      values ["Main-VPC"]
    end
  end
  
  data :aws_subnet, :public_a do
    filter do
      name "tag:Name"
      values ["Public-Subnet-A"]
    end
  end
  
  resource :aws_launch_template, :web do
    name_prefix "web-"
    image_id "ami-0c7217cdde317cfec"
    instance_type "t3.micro"
    
    vpc_security_group_ids [ref(:aws_security_group, :web, :id)]
    
    tag_specifications do
      resource_type "instance"
      tags do
        Name "WebServer"
        Team "frontend"
      end
    end
  end
  
  resource :aws_autoscaling_group, :web do
    name_prefix "web-asg-"
    min_size 1
    max_size 3
    desired_capacity 2
    
    vpc_zone_identifier [data(:aws_subnet, :public_a, :id)]
    
    launch_template do
      id ref(:aws_launch_template, :web, :id)
      version "$Latest"
    end
    
    tag do
      key "Name"
      value "WebServer-ASG"
      propagate_at_launch true
    end
  end
end

template :monitoring do
  provider :aws do
    region "us-east-1"
  end
  
  resource :aws_cloudwatch_dashboard, :main do
    dashboard_name "WebApp-Dashboard"
    
    dashboard_body jsonencode({
      widgets: [
        {
          type: "metric",
          properties: {
            metrics: [
              ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "web-asg-*"]
            ],
            period: 300,
            stat: "Average",
            region: "us-east-1",
            title: "EC2 CPU Utilization"
          }
        }
      ]
    })
  end
end
```

### Workspace Directory Structure

When you run Pangea commands, it creates this structure:

```
~/.pangea/workspaces/development/
├── networking/              # Template workspace
│   ├── main.tf.json        # Generated Terraform
│   ├── terraform.tfstate   # Isolated state
│   └── .terraform/         # Terraform working directory
├── compute/                # Template workspace
│   ├── main.tf.json
│   ├── terraform.tfstate
│   └── .terraform/
└── monitoring/             # Template workspace
    ├── main.tf.json
    ├── terraform.tfstate
    └── .terraform/
```

### Template Operations

Each template can be operated on independently:

```bash
# Plan all templates
pangea plan infrastructure.rb

# Plan specific template
pangea plan infrastructure.rb --template networking

# Deploy templates in dependency order
pangea apply infrastructure.rb --template networking
pangea apply infrastructure.rb --template compute
pangea apply infrastructure.rb --template monitoring

# Update just monitoring
pangea apply infrastructure.rb --template monitoring

# Destroy in reverse dependency order
pangea destroy infrastructure.rb --template monitoring
pangea destroy infrastructure.rb --template compute
pangea destroy infrastructure.rb --template networking
```

## Benefits of Template Isolation

### 1. Parallel Development

**Scenario**: Frontend team needs to update load balancer configuration while platform team updates VPC settings.

**Traditional Terraform**:
```bash
# Teams must coordinate to avoid state conflicts
# Only one team can work at a time
cd networking/
terraform apply  # Platform team

cd ../compute/
terraform apply  # Frontend team (must wait)
```

**With Pangea**:
```bash
# Teams work independently
pangea apply infrastructure.rb --template networking  # Platform team
pangea apply infrastructure.rb --template compute     # Frontend team (parallel)
```

### 2. Granular Deployments

**Scenario**: Need to update monitoring without touching production networking.

```bash
# Only update monitoring template
pangea apply infrastructure.rb --template monitoring

# Rollback just monitoring if needed
pangea destroy infrastructure.rb --template monitoring
```

### 3. Template-Specific Backend Configuration

Different templates can use different backends based on security requirements:

```yaml
# pangea.yml
namespaces:
  production:
    templates:
      networking:
        state:
          type: s3
          bucket: "secure-networking-state"
          key: "prod/networking.tfstate"
          kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/network-key"
      
      compute:
        state:
          type: s3
          bucket: "app-team-state"
          key: "prod/compute.tfstate"
      
      monitoring:
        state:
          type: local  # Development team preference
          path: "monitoring.tfstate"
```

### 4. Blast Radius Reduction

**Template isolation limits the impact of failures:**

```ruby
template :experimental_feature do
  # New experimental infrastructure
  # If this fails, it doesn't affect other templates
  
  resource :aws_instance, :experimental do
    ami "ami-experimental"  # Might fail
    instance_type "x1.large"
  end
end

template :production_core do
  # Critical production infrastructure
  # Isolated from experimental changes
  
  resource :aws_rds_instance, :main do
    # Production database - protected from experimental failures
  end
end
```

If the experimental template fails, production core continues running unaffected.

### 5. Team Ownership

Templates naturally align with team boundaries:

```ruby
# Platform team owns networking
template :networking do
  # VPC, subnets, security groups
end

# Application team owns compute
template :application do
  # EC2, load balancers, auto scaling
end

# Data team owns analytics
template :analytics do
  # Redshift, Kinesis, Lambda
end

# DevOps team owns monitoring
template :observability do
  # CloudWatch, alerts, dashboards
end
```

Each team can deploy their templates independently while maintaining integration through data sources.

## Cross-Template Communication

### Using Data Sources

Templates communicate through Terraform data sources, not direct references:

```ruby
template :networking do
  resource :aws_vpc, :main do
    cidr_block "10.0.0.0/16"
    tags do
      Name "Production-VPC"
      Environment "production"
    end
  end
end

template :compute do
  # Find VPC created by networking template
  data :aws_vpc, :main do
    filter do
      name "tag:Name"
      values ["Production-VPC"]
    end
  end
  
  # Use the VPC ID
  resource :aws_instance, :web do
    subnet_id data(:aws_subnet, :public, :id)
    vpc_security_group_ids [ref(:aws_security_group, :web, :id)]
  end
end
```

### Benefits of Data Source Communication

1. **Loose Coupling**: Templates don't directly depend on each other
2. **Independent Deployment**: Each template can be deployed separately
3. **Flexible References**: Can reference existing resources not managed by Pangea
4. **Error Isolation**: Communication failures are contained to individual templates

## Advanced Template Patterns

### 1. Environment-Specific Templates

```ruby
template :database_development do
  # Development database configuration
  resource :aws_db_instance, :main do
    instance_class "db.t3.micro"
    allocated_storage 20
    multi_az false
  end
end

template :database_production do
  # Production database configuration
  resource :aws_db_instance, :main do
    instance_class "db.r5.xlarge"
    allocated_storage 500
    multi_az true
    backup_retention_period 30
  end
end
```

Deploy environment-specific templates:

```bash
pangea apply database.rb --template database_development --namespace development
pangea apply database.rb --template database_production --namespace production
```

### 2. Shared Infrastructure Templates

```ruby
template :shared_services do
  # Shared across all applications
  resource :aws_route53_zone, :main do
    name "company.com"
  end
  
  resource :aws_acm_certificate, :wildcard do
    domain_name "*.company.com"
    validation_method "DNS"
  end
end

template :app_a do
  data :aws_route53_zone, :main do
    name "company.com"
  end
  
  # App A specific resources
  resource :aws_route53_record, :app_a do
    zone_id data(:aws_route53_zone, :main, :zone_id)
    name "app-a.company.com"
    type "A"
    alias do
      name ref(:aws_lb, :app_a, :dns_name)
    end
  end
end
```

### 3. Feature Flag Templates

```ruby
template :feature_new_ui do
  # Only deploy if feature flag is enabled
  
  resource :aws_lb_target_group, :new_ui do
    name_prefix "new-ui-"
    port 3000
    protocol "HTTP"
  end
  
  resource :aws_ecs_service, :new_ui do
    name "new-ui-service"
    cluster ref(:aws_ecs_cluster, :main, :id)
    desired_count 2
  end
end
```

Enable/disable features by deploying/destroying specific templates:

```bash
# Enable new UI
pangea apply features.rb --template feature_new_ui

# Disable new UI
pangea destroy features.rb --template feature_new_ui
```

## Comparison with Other Tools

### vs. Terragrunt

**Terragrunt** requires multiple configuration files:

```
terragrunt/
├── networking/
│   ├── terragrunt.hcl
│   └── main.tf
├── compute/
│   ├── terragrunt.hcl
│   └── main.tf
└── database/
    ├── terragrunt.hcl
    └── main.tf
```

**Pangea** achieves the same isolation in a single file:

```ruby
# All templates in one file with automatic isolation
template :networking do ... end
template :compute do ... end
template :database do ... end
```

### vs. Directory-Based Terraform

**Traditional approach**:
- 3 templates = 3 directories = 3 sets of configuration files
- Manual state management for each directory
- Complex dependency management

**Pangea approach**:
- 3 templates = 3 isolated workspaces = automatic state management
- Single configuration file
- Declarative cross-template communication

## Best Practices

### 1. Template Naming

Use descriptive, consistent names:

```ruby
# Good
template :vpc_networking do ... end
template :web_application do ... end
template :rds_database do ... end

# Better - with environment
template :production_vpc do ... end
template :staging_database do ... end

# Best - with team ownership
template :platform_networking do ... end
template :frontend_application do ... end
template :data_analytics do ... end
```

### 2. Template Size

Keep templates focused and reasonably sized:

```ruby
# Too small - creates unnecessary complexity
template :vpc_only do
  resource :aws_vpc, :main do ... end
end
template :subnet_only do
  resource :aws_subnet, :public do ... end
end

# Too large - violates single responsibility
template :entire_application do
  # 50+ resources mixing networking, compute, database, monitoring
end

# Just right - cohesive functionality
template :networking do
  # VPC, subnets, route tables, security groups (5-10 resources)
end

template :web_tier do
  # Load balancer, auto scaling group, launch template (3-7 resources)
end
```

### 3. Dependency Management

Make dependencies explicit and minimal:

```ruby
template :foundation do
  resource :aws_vpc, :main do
    tags do
      Name "Foundation-VPC"  # Explicit name for data source lookup
    end
  end
end

template :application do
  data :aws_vpc, :main do
    filter do
      name "tag:Name"
      values ["Foundation-VPC"]  # Clear dependency
    end
  end
end
```

### 4. Template Documentation

Document template purpose and dependencies:

```ruby
# Template: networking
# Purpose: Foundation VPC and networking components
# Dependencies: None
# Consumers: compute, database templates
template :networking do
  # VPC and networking resources
end

# Template: compute
# Purpose: Web application compute resources
# Dependencies: networking template (via data sources)
# Consumers: None
template :compute do
  # Compute resources
end
```

## Troubleshooting Template Isolation

### Common Issues

**1. Template Dependencies**

```bash
# Error: Resource not found
Error: No matching VPC found

# Solution: Check template deployment order
pangea apply infrastructure.rb --template networking  # First
pangea apply infrastructure.rb --template compute     # Then
```

**2. State Conflicts**

```bash
# This should never happen with proper template isolation
# If it does, check for duplicate template names
```

**3. Cross-Template References**

```ruby
# Wrong: Direct reference across templates
template :compute do
  resource :aws_instance, :web do
    vpc_id ref(:aws_vpc, :main, :id)  # Can't reference other template
  end
end

# Right: Use data sources
template :compute do
  data :aws_vpc, :main do
    filter do
      name "tag:Name"
      values ["Production-VPC"]
    end
  end
  
  resource :aws_instance, :web do
    vpc_id data(:aws_vpc, :main, :id)  # Reference data source
  end
end
```

## Summary

Template isolation is Pangea's key differentiator, providing:

1. **Granular Control**: Deploy and manage infrastructure components independently
2. **Team Scalability**: Multiple teams can work on infrastructure simultaneously
3. **Reduced Blast Radius**: Template failures don't affect other components
4. **Flexible Architecture**: Mix and match templates based on requirements
5. **Simplified State Management**: Automatic workspace and state isolation

This approach scales from simple single-template deployments to complex multi-team, multi-environment infrastructures while maintaining clarity and reducing operational overhead.

Next, explore [Multi-Environment Management](multi-environment-management.md) to see how template isolation works across development, staging, and production environments.