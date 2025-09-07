# Migration from Terraform: Your Path to Scalable Infrastructure

Migrating from traditional Terraform to Pangea unlocks significant benefits: template-level state isolation, type-safe resource configuration, and automation-first design. This guide provides a comprehensive strategy for migrating existing Terraform codebases to Pangea while maintaining infrastructure availability and team productivity.

## Understanding the Migration Benefits

### What You Gain with Pangea

**Before (Traditional Terraform):**
```
terraform/
├── vpc/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfstate
│   └── outputs.tf
├── compute/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfstate
│   └── outputs.tf
└── database/
    ├── main.tf
    ├── variables.tf
    ├── terraform.tfstate
    └── outputs.tf
```

**After (Pangea):**
```ruby
# infrastructure.rb - Single file, multiple isolated templates
template :vpc do
  aws_vpc(:main, { cidr_block: "10.0.0.0/16" })
end

template :compute do
  aws_instance(:web, { ami: "ami-123", instance_type: "t3.micro" })
end

template :database do
  aws_rds_instance(:main, { engine: "postgres", instance_class: "db.t3.micro" })
end
```

**Key Benefits:**
- **90% less configuration overhead** - No separate variable files, state configuration per directory
- **Template-level isolation** - More granular than directory-based isolation
- **Type safety** - Catch configuration errors before deployment
- **Single source of truth** - All templates in one file, with isolated state
- **Automation-first** - Built for CI/CD from day one

## Migration Strategy Overview

### Three Migration Approaches

**1. Greenfield Migration (Recommended for new projects)**
- Start fresh with Pangea
- Import existing resources using data sources
- Gradually migrate resources to Pangea management

**2. Blue-Green Migration (Best for production systems)**
- Deploy parallel infrastructure with Pangea
- Gradual traffic switching
- Decomission old infrastructure

**3. In-Place Migration (Most complex, highest risk)**
- Directly convert Terraform state to Pangea
- Requires careful state file manipulation
- Only recommended for development environments

## Phase 1: Assessment and Planning

### Terraform Inventory Analysis

First, understand your current Terraform structure:

```bash
# Run this analysis script to understand your codebase
#!/bin/bash
# terraform-inventory.sh

echo "=== Terraform Codebase Analysis ==="

# Count resources by type
echo "Resource Types:"
find . -name "*.tf" -exec grep -h "^resource" {} \; | \
  awk '{print $2}' | sed 's/"//g' | sort | uniq -c | sort -nr

# Count modules
echo -e "\nModules:"
find . -name "*.tf" -exec grep -h "^module" {} \; | \
  awk '{print $2}' | sed 's/"//g' | sort | uniq -c

# Find data sources
echo -e "\nData Sources:"
find . -name "*.tf" -exec grep -h "^data" {} \; | \
  awk '{print $2}' | sed 's/"//g' | sort | uniq -c

# Count variables
echo -e "\nVariables:"
find . -name "variables.tf" -exec wc -l {} \; | awk '{sum+=$1} END {print "Total variable lines:", sum}'

# State files
echo -e "\nState Files:"
find . -name "terraform.tfstate" | wc -l
```

### Dependency Mapping

Create a dependency graph of your infrastructure:

```bash
#!/bin/bash
# dependency-analysis.sh

# Find cross-references between directories
echo "=== Cross-Directory Dependencies ==="
for dir in */; do
  if [ -f "$dir/main.tf" ]; then
    echo "Directory: $dir"
    grep -h "data\." "$dir"*.tf | grep -v "^#" | head -5
    echo ""
  fi
done
```

### Migration Complexity Assessment

Classify your resources by migration complexity:

**Low Complexity (Direct 1:1 mapping):**
- aws_instance → aws_instance()
- aws_vpc → aws_vpc()  
- aws_subnet → aws_subnet()
- aws_security_group → aws_security_group()

**Medium Complexity (Some restructuring needed):**
- Modules → Components or Architecture functions
- Complex data sources → Cross-template references
- Local values → Ruby variables/methods

**High Complexity (Significant refactoring):**
- Custom providers → May need custom resource functions
- Complex count/for_each logic → Ruby iteration
- External data sources → Custom Ruby logic

## Phase 2: Development Environment Migration

### Step 1: Set Up Pangea Environment

Install Pangea and create initial configuration:

```bash
# Install Pangea
gem install pangea

# Create configuration
cat > pangea.yml << EOF
default_namespace: development

namespaces:
  development:
    description: "Development environment - local state"
    state:
      type: local
      path: "terraform.tfstate"
  
  staging:
    description: "Staging environment - S3 remote state"  
    state:
      type: s3
      bucket: "your-terraform-state-staging"
      key: "pangea/staging/terraform.tfstate"
      region: "us-east-1"
      dynamodb_table: "terraform-locks-staging"
EOF
```

### Step 2: Convert Simple Resources First

Start with stateless resources that are easy to migrate:

**Original Terraform:**
```hcl
# vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "MainVPC"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "Public-${count.index + 1}"
    Type = "public"
  }
}
```

**Converted Pangea:**
```ruby
# infrastructure.rb
template :networking do
  provider :aws do
    region "us-east-1"
  end
  
  # VPC with type-safe attributes
  vpc_ref = aws_vpc(:main, {
    cidr_block: "10.0.0.0/16",
    enable_dns_hostnames: true,
    enable_dns_support: true,
    tags: {
      Name: "MainVPC",
      Environment: namespace
    }
  })
  
  # Create subnets using Ruby iteration
  availability_zones = ["us-east-1a", "us-east-1b"]
  availability_zones.each_with_index do |az, index|
    aws_subnet(:"public_#{index + 1}", {
      vpc_id: vpc_ref.id,
      cidr_block: "10.0.#{index + 1}.0/24",
      availability_zone: az,
      map_public_ip_on_launch: true,
      tags: {
        Name: "Public-#{index + 1}",
        Type: "public"
      }
    })
  end
end
```

### Step 3: Handle Data Sources and Cross-References

**Original Terraform with cross-directory references:**
```hcl
# compute/main.tf
data "aws_vpc" "main" {
  tags = {
    Name = "MainVPC"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  
  tags = {
    Type = "public"
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.public.ids[0]
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name = "WebServer"
  }
}
```

**Converted Pangea with cross-template references:**
```ruby
template :compute do
  provider :aws do
    region "us-east-1"
  end
  
  # Reference VPC from networking template
  data :aws_vpc, :main do
    filter do
      name "tag:Name"
      values ["MainVPC"]
    end
  end
  
  # Find public subnets
  data :aws_subnets, :public do
    filter do
      name "vpc-id"
      values [data(:aws_vpc, :main, :id)]
    end
    
    filter do
      name "tag:Type"
      values ["public"]
    end
  end
  
  # Create security group in this template
  sg_ref = aws_security_group(:web, {
    name_prefix: "web-",
    vpc_id: data(:aws_vpc, :main, :id),
    ingress_rules: [
      {
        from_port: 80,
        to_port: 80,
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"]
      }
    ]
  })
  
  # Web server instance
  aws_instance(:web, {
    ami: "ami-0c7217cdde317cfec",
    instance_type: "t3.micro",
    subnet_id: data(:aws_subnets, :public, :ids, 0),
    vpc_security_group_ids: [sg_ref.id],
    tags: {
      Name: "WebServer"
    }
  })
end
```

### Step 4: Test Development Migration

Deploy and validate:

```bash
# Plan networking template
pangea plan infrastructure.rb --template networking

# Apply networking
pangea apply infrastructure.rb --template networking

# Plan compute (depends on networking)
pangea plan infrastructure.rb --template compute

# Apply compute  
pangea apply infrastructure.rb --template compute

# Validate resources exist
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=MainVPC"
aws ec2 describe-instances --filters "Name=tag:Name,Values=WebServer"
```

## Phase 3: Module to Component Migration

### Converting Terraform Modules

**Original Terraform Module:**
```hcl
# modules/web-app/main.tf
variable "app_name" { type = string }
variable "instance_type" { default = "t3.micro" }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }

resource "aws_security_group" "app" {
  name_prefix = "${var.app_name}-"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.app_name}-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.app.id]
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.app_name}-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}
```

**Converted Pangea Component:**
```ruby
# Define component with type safety
def web_application_component(name, config)
  # Validate configuration
  validated_config = WebAppConfig.new(config)
  
  # Create security group
  sg_ref = aws_security_group(:"#{name}_sg", {
    name_prefix: "#{name}-",
    vpc_id: validated_config.vpc_id,
    ingress_rules: [
      {
        from_port: 80,
        to_port: 80,
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"]
      }
    ]
  })
  
  # Get latest Ubuntu AMI
  ubuntu_ami = data(:aws_ami, :ubuntu) do
    most_recent true
    owners ["099720109477"] # Canonical
    
    filter do
      name "name"
      values ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    end
  end
  
  # Launch template
  lt_ref = aws_launch_template(:"#{name}_lt", {
    name_prefix: "#{name}-",
    image_id: ubuntu_ami.id,
    instance_type: validated_config.instance_type,
    vpc_security_group_ids: [sg_ref.id]
  })
  
  # Auto scaling group
  asg_ref = aws_autoscaling_group(:"#{name}_asg", {
    name: "#{name}-asg",
    vpc_zone_identifier: validated_config.subnet_ids,
    min_size: validated_config.min_size,
    max_size: validated_config.max_size,
    desired_capacity: validated_config.desired_capacity,
    
    launch_template: {
      id: lt_ref.id,
      version: "$Latest"
    }
  })
  
  # Return component reference
  ComponentReference.new(
    name: name,
    type: 'web_application',
    resources: {
      security_group: sg_ref,
      launch_template: lt_ref,
      autoscaling_group: asg_ref
    }
  )
end

# Type-safe configuration
class WebAppConfig < Dry::Struct
  attribute :vpc_id, Types::String
  attribute :subnet_ids, Types::Array.of(Types::String)
  attribute :instance_type, Types::String.constrained(
    included_in: %w[t3.nano t3.micro t3.small t3.medium]
  ).default("t3.micro")
  attribute :min_size, Types::Integer.constrained(gteq: 1).default(1)
  attribute :max_size, Types::Integer.constrained(gteq: 1).default(3)
  attribute :desired_capacity, Types::Integer.constrained(gteq: 1).default(2)
end
```

**Using the Component:**
```ruby
template :web_applications do
  # Reference networking from other template
  data :aws_vpc, :main do
    filter do
      name "tag:Name"
      values ["MainVPC"]
    end
  end
  
  data :aws_subnets, :public do
    filter do
      name "vpc-id"
      values [data(:aws_vpc, :main, :id)]
    end
  end
  
  # Use component with validation
  web_app = web_application_component(:frontend, {
    vpc_id: data(:aws_vpc, :main, :id),
    subnet_ids: data(:aws_subnets, :public, :ids),
    instance_type: "t3.small",
    min_size: 2,
    max_size: 5,
    desired_capacity: 3
  })
  
  # Create load balancer for the component
  aws_lb(:frontend_lb, {
    name_prefix: "frontend-",
    load_balancer_type: "application",
    subnets: data(:aws_subnets, :public, :ids),
    security_groups: [web_app.resources[:security_group].id]
  })
end
```

## Phase 4: State Migration Strategies

### Strategy 1: Import Existing Resources (Recommended)

Use Terraform import to bring existing resources under Pangea management:

```bash
# 1. Deploy Pangea infrastructure to match existing
pangea plan infrastructure.rb --template networking

# 2. Import existing resources into Pangea's state
cd ~/.pangea/workspaces/development/networking
terraform import aws_vpc.main vpc-12345678
terraform import aws_subnet.public_1 subnet-12345678
terraform import aws_subnet.public_2 subnet-87654321

# 3. Verify state matches
pangea plan infrastructure.rb --template networking
# Should show "No changes"
```

### Strategy 2: Blue-Green Migration

Deploy parallel infrastructure and switch over:

```ruby
# Create new infrastructure with Pangea
template :networking_v2 do
  aws_vpc(:main, {
    cidr_block: "10.1.0.0/16",  # Different CIDR to avoid conflicts
    tags: { Name: "MainVPC-v2" }
  })
end

template :compute_v2 do
  # Reference new VPC
  data :aws_vpc, :main do
    filter do
      name "tag:Name"
      values ["MainVPC-v2"]
    end
  end
  
  # Deploy new compute resources
end
```

Migration process:
```bash
# 1. Deploy new infrastructure
pangea apply infrastructure.rb --template networking_v2
pangea apply infrastructure.rb --template compute_v2

# 2. Test new infrastructure
# 3. Switch DNS/load balancer to new infrastructure
# 4. Decommission old infrastructure
```

### Strategy 3: Gradual Resource Migration

Migrate resources one template at a time:

```ruby
# Phase 1: Migrate VPC only
template :networking do
  # Import existing VPC
  aws_vpc(:main, {
    cidr_block: "10.0.0.0/16",
    tags: { Name: "MainVPC" }
  })
end

# Phase 2: Add subnets (after VPC is managed by Pangea)
template :networking do
  vpc_ref = aws_vpc(:main, {
    cidr_block: "10.0.0.0/16",
    tags: { Name: "MainVPC" }
  })
  
  # Import existing subnets
  aws_subnet(:public_1, {
    vpc_id: vpc_ref.id,
    cidr_block: "10.0.1.0/24",
    tags: { Name: "Public-1" }
  })
end
```

## Phase 5: Production Migration

### Pre-Migration Checklist

- [ ] All templates tested in development
- [ ] State backup procedures verified
- [ ] Rollback plan documented
- [ ] Team trained on Pangea operations
- [ ] Monitoring and alerting configured
- [ ] Change control approval obtained

### Production Migration Process

```bash
# 1. Backup all Terraform state files
mkdir -p backups/$(date +%Y%m%d)
find . -name "terraform.tfstate*" -exec cp {} backups/$(date +%Y%m%d)/ \;

# 2. Create Pangea configuration
cat > pangea.yml << EOF
default_namespace: production

namespaces:
  production:
    state:
      type: s3
      bucket: "terraform-state-prod"
      key: "pangea/production/terraform.tfstate"
      region: "us-east-1"
      dynamodb_table: "terraform-locks-prod"
      encrypt: true
EOF

# 3. Plan each template
pangea plan infrastructure.rb --template networking --namespace production
pangea plan infrastructure.rb --template compute --namespace production

# 4. Import existing resources (critical step)
# Use terraform import commands for each resource

# 5. Verify no changes needed
pangea plan infrastructure.rb --namespace production
# Should show "No changes"

# 6. Make first Pangea-managed change (small, safe change)
# For example, add a tag
pangea apply infrastructure.rb --template networking --namespace production
```

### Post-Migration Validation

```bash
# Validate all resources still exist and function
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=MainVPC"
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"

# Test application functionality
curl -f https://your-app.com/health

# Verify monitoring and alerting still work
# Check dashboard for any anomalies
```

## Common Migration Challenges and Solutions

### Challenge 1: Complex Count Logic

**Terraform:**
```hcl
resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
```

**Pangea Solution:**
```ruby
template :networking do
  vpc_ref = aws_vpc(:main, { cidr_block: "10.0.0.0/16" })
  
  # Use Ruby's native iteration
  az_count = ENV['AZ_COUNT']&.to_i || 3
  availability_zones = data(:aws_availability_zones, :available, :names)
  
  az_count.times do |index|
    aws_subnet(:"private_#{index}", {
      vpc_id: vpc_ref.id,
      cidr_block: "10.0.#{index + 10}.0/24",  # Ruby string interpolation
      availability_zone: availability_zones[index]
    })
  end
end
```

### Challenge 2: Conditional Resources

**Terraform:**
```hcl
resource "aws_nat_gateway" "main" {
  count           = var.create_nat_gateway ? var.az_count : 0
  allocation_id   = aws_eip.nat[count.index].id
  subnet_id       = aws_subnet.public[count.index].id
}
```

**Pangea Solution:**
```ruby
template :networking do
  create_nat_gateway = ENV['CREATE_NAT_GATEWAY'] == 'true'
  
  if create_nat_gateway
    availability_zones.each_with_index do |az, index|
      # Create EIP
      eip_ref = aws_eip(:"nat_#{index}", {
        domain: "vpc",
        tags: { Name: "NAT-Gateway-EIP-#{index}" }
      })
      
      # Create NAT Gateway
      aws_nat_gateway(:"main_#{index}", {
        allocation_id: eip_ref.id,
        subnet_id: ref(:aws_subnet, :"public_#{index}", :id)
      })
    end
  end
end
```

### Challenge 3: Local Values and Functions

**Terraform:**
```hcl
locals {
  environment_config = {
    development = {
      instance_type = "t3.micro"
      min_size     = 1
      max_size     = 2
    }
    production = {
      instance_type = "t3.large"
      min_size     = 3
      max_size     = 10
    }
  }
  
  config = local.environment_config[var.environment]
}
```

**Pangea Solution:**
```ruby
template :compute do
  # Ruby hash with environment-specific configuration
  environment_config = {
    'development' => {
      instance_type: 't3.micro',
      min_size: 1,
      max_size: 2
    },
    'production' => {
      instance_type: 't3.large',
      min_size: 3,
      max_size: 10
    }
  }
  
  config = environment_config[namespace]
  
  aws_autoscaling_group(:web, {
    min_size: config[:min_size],
    max_size: config[:max_size],
    launch_template: {
      id: ref(:aws_launch_template, :web, :id),
      version: "$Latest"
    }
  })
end
```

## Migration Timeline Template

### Week 1-2: Assessment and Planning
- [ ] Inventory existing Terraform
- [ ] Identify dependencies
- [ ] Plan template structure
- [ ] Set up Pangea development environment

### Week 3-4: Development Environment Migration
- [ ] Convert simple resources
- [ ] Test template isolation
- [ ] Handle cross-template references
- [ ] Validate functionality

### Week 5-6: Component Development
- [ ] Convert modules to components
- [ ] Add type safety
- [ ] Test component composition
- [ ] Document new patterns

### Week 7-8: Staging Migration
- [ ] Apply lessons learned to staging
- [ ] Full staging environment migration
- [ ] Performance testing
- [ ] Team training

### Week 9-10: Production Migration
- [ ] Final production planning
- [ ] Execute production migration
- [ ] Validation and monitoring
- [ ] Rollback procedures if needed

### Week 11-12: Optimization and Documentation
- [ ] Optimize templates based on experience
- [ ] Complete documentation
- [ ] Team knowledge transfer
- [ ] Decommission old Terraform

## Post-Migration Benefits

### Operational Improvements

**Before Terraform:**
```bash
# Deploy networking changes
cd terraform/networking
terraform plan
terraform apply

# Deploy compute changes (must wait for networking)
cd ../compute  
terraform plan
terraform apply

# Deploy database changes
cd ../database
terraform plan
terraform apply
```

**After Pangea:**
```bash
# Deploy all changes in parallel (template isolation)
pangea apply infrastructure.rb --template networking &
pangea apply infrastructure.rb --template compute &
pangea apply infrastructure.rb --template database &
wait

# Or deploy everything
pangea apply infrastructure.rb
```

### Development Workflow Improvements

**Team Collaboration:**
- Multiple developers can work on different templates simultaneously
- No more conflicts over terraform.tfstate files
- Clear ownership boundaries with template isolation

**CI/CD Integration:**
- Built-in auto-approval for automation
- Template-specific deployments for faster pipelines
- Type safety prevents configuration errors in CI

**Code Quality:**
- Type-safe resource functions prevent typos
- IDE integration with autocomplete
- Self-documenting code with type definitions

## Troubleshooting Migration Issues

### State Import Failures
```bash
# If import fails, check resource ID format
terraform show | grep "vpc-"  # Find actual resource ID
terraform import aws_vpc.main vpc-actual-id-here
```

### Template Reference Issues
```ruby
# If cross-template references fail, check data source filters
data :aws_vpc, :main do
  filter do
    name "tag:Name"
    values ["MainVPC"]  # Ensure tag exists and matches
  end
end
```

### Type Validation Errors
```ruby
# If validation fails, check attribute types
aws_instance(:web, {
  ami: "ami-123",
  instance_type: "t3.micro",
  monitoring: true,  # Boolean, not string
  vpc_security_group_ids: ["sg-123"]  # Array, not string
})
```

## Summary

Migrating from Terraform to Pangea provides:

1. **Simplified Operations**: Single-file management with template isolation
2. **Better Scalability**: Team-friendly development with parallel workflows
3. **Type Safety**: Catch errors before deployment, not during
4. **Automation-First**: Built for CI/CD from the ground up
5. **Maintainable Code**: Ruby's expressiveness with infrastructure patterns

The migration investment pays dividends in reduced operational overhead, faster development cycles, and more reliable infrastructure deployments.

Next, explore [CI/CD Integration](cicd-integration.md) to learn how to automate your newly migrated Pangea infrastructure in your deployment pipelines.