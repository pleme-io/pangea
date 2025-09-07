# Multi-Environment Management: One Codebase, Multiple Environments

Modern applications require multiple environments - development, staging, production, and often specialized environments like security testing, performance testing, and disaster recovery. Pangea's namespace system makes it effortless to manage the same infrastructure across all these environments while maintaining proper isolation and security boundaries.

## The Multi-Environment Challenge

### Traditional Terraform Struggles

Traditional Terraform approaches to multi-environment management are cumbersome:

**Approach 1: Directory Duplication**
```
terraform/
├── environments/
│   ├── development/
│   │   ├── main.tf (duplicated code)
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf (duplicated code)
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── production/
│       ├── main.tf (duplicated code)
│       ├── variables.tf
│       └── terraform.tfvars
```

**Problems:**
- Code duplication across environments
- Difficult to maintain consistency
- Changes require updates in multiple places
- No guarantee environments are actually the same

**Approach 2: Terraform Workspaces**
```bash
terraform workspace new development
terraform workspace new staging
terraform workspace new production
```

**Problems:**
- Shared backend configuration
- Risk of workspace state corruption
- Difficult to implement different security policies
- No per-environment backend customization

## Pangea's Namespace Solution

Pangea solves multi-environment management through **namespaces** - configuration-driven environment management where the same infrastructure templates deploy to different environments with appropriate customizations.

### Core Concept: One Template, Many Namespaces

```ruby
# infrastructure.rb - ONE file for ALL environments
template :web_application do
  provider :aws do
    region "us-east-1"
  end
  
  resource :aws_instance, :web do
    ami "ami-0c7217cdde317cfec"
    instance_type "t3.micro"  # Will be overridden per environment
    
    tags do
      Name "WebServer"
      Environment "#{namespace}"  # Automatically set per environment
    end
  end
end
```

```yaml
# pangea.yml - Environment configuration
default_namespace: development

namespaces:
  development:
    description: "Local development environment"
    state:
      type: local
      path: "terraform.tfstate"
    
  staging:
    description: "Staging environment"
    state:
      type: s3
      bucket: "terraform-state-staging"
      key: "pangea/staging/terraform.tfstate"
      region: "us-east-1"
      dynamodb_table: "terraform-locks-staging"
    
  production:
    description: "Production environment"
    state:
      type: s3
      bucket: "terraform-state-prod"
      key: "pangea/production/terraform.tfstate"
      region: "us-east-1"
      dynamodb_table: "terraform-locks-prod"
      encrypt: true
      kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/prod-key"
```

### Deploy to Any Environment

```bash
# Development (uses default namespace)
pangea apply infrastructure.rb

# Staging
pangea apply infrastructure.rb --namespace staging

# Production
pangea apply infrastructure.rb --namespace production
```

## Environment-Specific Configurations

### Method 1: Configuration-Driven Customization

Use environment variables and configuration to customize behavior:

```ruby
# infrastructure.rb
template :web_application do
  provider :aws do
    region ENV['AWS_REGION'] || 'us-east-1'
  end
  
  resource :aws_instance, :web do
    ami "ami-0c7217cdde317cfec"
    instance_type ENV['INSTANCE_TYPE'] || 't3.micro'
    
    tags do
      Name "WebServer-#{namespace}"
      Environment namespace
      CostCenter ENV['COST_CENTER'] || 'development'
    end
  end
  
  resource :aws_autoscaling_group, :web do
    name_prefix "web-#{namespace}-"
    min_size ENV['MIN_INSTANCES']&.to_i || 1
    max_size ENV['MAX_INSTANCES']&.to_i || 3
    desired_capacity ENV['DESIRED_INSTANCES']&.to_i || 1
  end
end
```

Set environment-specific variables:

```bash
# Development
export INSTANCE_TYPE=t3.micro
export MIN_INSTANCES=1
export MAX_INSTANCES=2
pangea apply infrastructure.rb

# Production  
export INSTANCE_TYPE=t3.large
export MIN_INSTANCES=3
export MAX_INSTANCES=10
export COST_CENTER=production
pangea apply infrastructure.rb --namespace production
```

### Method 2: Namespace-Aware Templates

Templates can access the current namespace and adapt accordingly:

```ruby
template :database do
  provider :aws do
    region "us-east-1"
  end
  
  # Environment-specific database configuration
  database_config = case namespace
  when 'development'
    {
      instance_class: 'db.t3.micro',
      allocated_storage: 20,
      multi_az: false,
      backup_retention_period: 1,
      skip_final_snapshot: true
    }
  when 'staging'
    {
      instance_class: 'db.t3.small',
      allocated_storage: 100,
      multi_az: false,
      backup_retention_period: 7,
      skip_final_snapshot: false
    }
  when 'production'
    {
      instance_class: 'db.r5.large',
      allocated_storage: 500,
      multi_az: true,
      backup_retention_period: 30,
      skip_final_snapshot: false,
      performance_insights_enabled: true
    }
  else
    raise "Unknown namespace: #{namespace}"
  end
  
  resource :aws_db_instance, :main do
    identifier_prefix "webapp-#{namespace}-"
    engine "postgresql"
    engine_version "14.9"
    
    # Apply environment-specific configuration
    instance_class database_config[:instance_class]
    allocated_storage database_config[:allocated_storage]
    multi_az database_config[:multi_az]
    backup_retention_period database_config[:backup_retention_period]
    skip_final_snapshot database_config[:skip_final_snapshot]
    performance_insights_enabled database_config[:performance_insights_enabled]
    
    tags do
      Name "WebApp-Database-#{namespace}"
      Environment namespace
    end
  end
end
```

### Method 3: Environment-Specific Templates

Create templates that only deploy in specific environments:

```ruby
# Only deploy monitoring in staging and production
template :monitoring do
  # Skip monitoring in development
  next if namespace == 'development'
  
  provider :aws do
    region "us-east-1"
  end
  
  resource :aws_cloudwatch_dashboard, :main do
    dashboard_name "WebApp-#{namespace}"
    
    dashboard_body jsonencode({
      widgets: [
        {
          type: "metric",
          properties: {
            metrics: [
              ["AWS/EC2", "CPUUtilization"]
            ],
            period: 300,
            stat: "Average",
            region: "us-east-1",
            title: "CPU Utilization - #{namespace}"
          }
        }
      ]
    })
  end
end

# Production-only security monitoring
template :security_monitoring do
  # Only deploy in production
  next unless namespace == 'production'
  
  resource :aws_guardduty_detector, :main do
    enable = true
    
    datasources do
      s3_logs do
        enable = true
      end
      kubernetes do
        audit_logs do
          enable = true
        end
      end
    end
    
    tags do
      Name "GuardDuty-Production"
      Environment "production"
    end
  end
end
```

## Advanced Namespace Configurations

### Backend Customization Per Environment

```yaml
# pangea.yml
namespaces:
  development:
    state:
      type: local
      path: "dev.tfstate"
  
  staging:
    state:
      type: s3
      bucket: "staging-terraform-state"
      key: "infrastructure/staging.tfstate"
      region: "us-east-1"
      dynamodb_table: "staging-locks"
  
  production:
    state:
      type: s3
      bucket: "prod-terraform-state"  
      key: "infrastructure/production.tfstate"
      region: "us-east-1"
      dynamodb_table: "prod-locks"
      encrypt: true
      kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/prod-state-key"
      
  # Disaster recovery environment
  production_dr:
    state:
      type: s3
      bucket: "prod-dr-terraform-state"
      key: "infrastructure/production-dr.tfstate"
      region: "us-west-2"  # Different region
      dynamodb_table: "prod-dr-locks"
      encrypt: true
```

### Template-Specific Namespace Configuration

Configure different backends for different templates within the same namespace:

```yaml
namespaces:
  production:
    default_state:
      type: s3
      bucket: "prod-terraform-state"
      region: "us-east-1"
      
    templates:
      networking:
        state:
          bucket: "prod-networking-state"  # Separate bucket for networking
          key: "networking/production.tfstate"
          kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/network-key"
          
      security:
        state:
          bucket: "prod-security-state"   # Highly secure bucket for security resources
          key: "security/production.tfstate"
          kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/security-key"
          
      application:
        state:
          bucket: "prod-app-state"        # App team manages their own state
          key: "application/production.tfstate"
```

## Real-World Environment Patterns

### Pattern 1: Standard Three-Tier Environments

```ruby
# shared-infrastructure.rb
template :vpc_networking do
  provider :aws do
    region "us-east-1"
  end
  
  # Environment-specific CIDR blocks
  cidr_blocks = {
    'development' => '10.0.0.0/16',
    'staging' => '10.1.0.0/16', 
    'production' => '10.2.0.0/16'
  }
  
  resource :aws_vpc, :main do
    cidr_block cidr_blocks[namespace]
    enable_dns_hostnames true
    enable_dns_support true
    
    tags do
      Name "VPC-#{namespace}"
      Environment namespace
    end
  end
  
  # Create subnets across AZs
  ['a', 'b', 'c'].each_with_index do |az, index|
    resource :"aws_subnet", :"public_#{az}" do
      vpc_id ref(:aws_vpc, :main, :id)
      cidr_block "#{cidr_blocks[namespace].split('/')[0].split('.')[0..2].join('.')}.#{index + 1}.0/24"
      availability_zone "us-east-1#{az}"
      map_public_ip_on_launch true
      
      tags do
        Name "Public-#{az.upcase}-#{namespace}"
        Environment namespace
        Tier "public"
      end
    end
  end
end
```

Deploy across environments:

```bash
# Create networking in all environments
pangea apply shared-infrastructure.rb --template vpc_networking --namespace development
pangea apply shared-infrastructure.rb --template vpc_networking --namespace staging  
pangea apply shared-infrastructure.rb --template vpc_networking --namespace production
```

### Pattern 2: Feature Branch Environments

```ruby
# feature-environments.rb
template :feature_environment do
  # Only deploy if FEATURE_BRANCH is set
  feature_branch = ENV['FEATURE_BRANCH']
  next unless feature_branch
  
  provider :aws do
    region "us-east-1"
  end
  
  # Use development VPC for feature branches
  data :aws_vpc, :main do
    filter do
      name "tag:Environment"
      values ["development"]
    end
  end
  
  resource :aws_instance, :feature do
    ami "ami-0c7217cdde317cfec"
    instance_type "t3.nano"  # Minimal resources for feature testing
    
    tags do
      Name "Feature-#{feature_branch}"
      Environment "feature"
      FeatureBranch feature_branch
      AutoDestroy "true"  # Mark for automatic cleanup
    end
  end
  
  # Feature-specific load balancer
  resource :aws_lb, :feature do
    name_prefix "feat-"
    load_balancer_type "application"
    
    tags do
      Name "Feature-LB-#{feature_branch}"
      FeatureBranch feature_branch
    end
  end
end
```

Deploy feature environments:

```bash
# Deploy feature branch environment
export FEATURE_BRANCH=user-auth-redesign
pangea apply feature-environments.rb --namespace development
```

### Pattern 3: Multi-Region Environments

```yaml
# pangea.yml
namespaces:
  production_us:
    description: "Production US East"
    state:
      type: s3
      bucket: "prod-us-terraform-state"
      key: "infrastructure/production-us.tfstate"
      region: "us-east-1"
      
  production_eu:
    description: "Production Europe"
    state:
      type: s3
      bucket: "prod-eu-terraform-state"
      key: "infrastructure/production-eu.tfstate"
      region: "eu-west-1"
```

```ruby
# multi-region.rb
template :regional_infrastructure do
  # Region mapping
  regions = {
    'production_us' => 'us-east-1',
    'production_eu' => 'eu-west-1'
  }
  
  provider :aws do
    region regions[namespace]
  end
  
  resource :aws_vpc, :main do
    cidr_block "10.0.0.0/16"
    
    tags do
      Name "VPC-#{regions[namespace]}"
      Environment namespace
      Region regions[namespace]
    end
  end
end
```

## Environment Promotion Workflows

### Basic Promotion

```bash
# 1. Deploy to development
pangea apply infrastructure.rb --namespace development

# 2. Test and validate in development

# 3. Promote to staging
pangea apply infrastructure.rb --namespace staging

# 4. Test and validate in staging

# 5. Promote to production
pangea apply infrastructure.rb --namespace production
```

### Advanced Promotion with Validation

```bash
#!/bin/bash
# deploy.sh - Environment promotion script

set -e

TEMPLATE_FILE=$1
TARGET_NAMESPACE=$2

echo "Promoting infrastructure to ${TARGET_NAMESPACE}..."

# 1. Plan the deployment
echo "Planning deployment..."
pangea plan $TEMPLATE_FILE --namespace $TARGET_NAMESPACE

# 2. Manual approval for production
if [ "$TARGET_NAMESPACE" = "production" ]; then
    read -p "Deploy to PRODUCTION? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Deployment cancelled"
        exit 1
    fi
fi

# 3. Deploy infrastructure
echo "Applying changes..."
pangea apply $TEMPLATE_FILE --namespace $TARGET_NAMESPACE

# 4. Run post-deployment tests
echo "Running post-deployment validation..."
./validate-environment.sh $TARGET_NAMESPACE

echo "Deployment to ${TARGET_NAMESPACE} completed successfully!"
```

### Blue-Green Deployments

```ruby
# blue-green.rb
template :application_blue do
  next unless ENV['DEPLOY_COLOR'] == 'blue'
  
  resource :aws_autoscaling_group, :app do
    name_prefix "app-blue-#{namespace}-"
    # Blue configuration
  end
end

template :application_green do
  next unless ENV['DEPLOY_COLOR'] == 'green'
  
  resource :aws_autoscaling_group, :app do
    name_prefix "app-green-#{namespace}-"
    # Green configuration
  end
end

template :load_balancer do
  # Switch traffic between blue and green
  active_color = ENV['ACTIVE_COLOR'] || 'blue'
  
  resource :aws_lb_target_group, :active do
    name_prefix "app-#{active_color}-#{namespace}-"
    # Target group points to active color
  end
end
```

Deploy blue-green:

```bash
# Deploy green version
export DEPLOY_COLOR=green
pangea apply blue-green.rb --namespace production

# Switch traffic to green
export ACTIVE_COLOR=green
pangea apply blue-green.rb --template load_balancer --namespace production

# Remove blue version
export DEPLOY_COLOR=blue
pangea destroy blue-green.rb --template application_blue --namespace production
```

## Environment Management Best Practices

### 1. Consistent Naming

```ruby
# Use consistent naming patterns across environments
template :web_application do
  resource :aws_instance, :web do
    tags do
      Name "WebServer-#{namespace}"
      Environment namespace
      Application "myapp"
    end
  end
end
```

### 2. Environment Validation

```ruby
template :production_safeguards do
  # Ensure production meets security requirements
  if namespace == 'production'
    # Require encryption
    resource :aws_db_instance, :main do
      storage_encrypted true
      kms_key_id "arn:aws:kms:us-east-1:123456789012:key/prod-key"
    end
  else
    resource :aws_db_instance, :main do
      # Development can skip encryption for cost
    end
  end
end
```

### 3. Resource Tagging Strategy

```ruby
template :resource_tagging do
  standard_tags = {
    Environment: namespace,
    ManagedBy: 'Pangea',
    Project: ENV['PROJECT_NAME'] || 'webapp',
    CostCenter: ENV['COST_CENTER'] || namespace,
    Owner: ENV['TEAM_EMAIL'] || 'devops@company.com'
  }
  
  resource :aws_instance, :web do
    tags standard_tags.merge({
      Name: "WebServer-#{namespace}",
      Type: 'compute'
    })
  end
  
  resource :aws_rds_instance, :db do
    tags standard_tags.merge({
      Name: "Database-#{namespace}",
      Type: 'database'
    })
  end
end
```

### 4. Environment-Specific Security

```yaml
# pangea.yml
namespaces:
  development:
    state:
      type: local
    allowed_regions: ["us-east-1"]
    
  production:
    state:
      type: s3
      encrypt: true
      kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/prod-key"
    allowed_regions: ["us-east-1", "us-west-2"]
    required_tags: ["Environment", "Owner", "CostCenter"]
```

## Troubleshooting Multi-Environment Issues

### Common Problems

**1. State File Conflicts**
```bash
# Error: State locked
Error: Error acquiring the state lock

# Solution: Check which environment you're in
pangea plan infrastructure.rb --namespace staging  # Not development
```

**2. Environment Cross-Contamination**
```ruby
# Wrong: Hardcoded values
resource :aws_instance, :web do
  vpc_id "vpc-12345"  # This will break in other environments
end

# Right: Environment-aware references
data :aws_vpc, :main do
  filter do
    name "tag:Environment"
    values [namespace]
  end
end

resource :aws_instance, :web do
  vpc_id data(:aws_vpc, :main, :id)
end
```

**3. Missing Environment Configuration**
```bash
# Error: Unknown namespace
Error: Namespace 'staging' not found in pangea.yml

# Solution: Add namespace to configuration
# pangea.yml
namespaces:
  staging:
    state:
      type: s3
      bucket: "staging-state"
```

## Summary

Pangea's namespace system provides powerful multi-environment management:

1. **Single Source of Truth**: One codebase works across all environments
2. **Environment-Specific Configuration**: Customize behavior per environment
3. **Proper Isolation**: Each environment has its own state and backend
4. **Flexible Deployment**: Deploy all or specific templates per environment
5. **Promotion Workflows**: Safe, validated environment promotion

This approach scales from simple dev/prod setups to complex multi-region, multi-team infrastructures while maintaining consistency and reducing operational overhead.

Next, explore [Type-Safe Infrastructure](type-safe-infrastructure.md) to learn how Pangea's Ruby DSL and type system prevent configuration errors before deployment.