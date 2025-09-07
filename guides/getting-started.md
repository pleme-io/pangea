# Getting Started with Pangea: Infrastructure as Code, Simplified

Pangea transforms infrastructure management by combining the power of Ruby with the reliability of Terraform, offering template-level state isolation that scales with your team and complexity. This guide will walk you through your first Pangea deployment and show you why it's different from traditional infrastructure tools.

## What Makes Pangea Different?

Before diving into the code, let's understand what makes Pangea unique:

- **Template-Level State Isolation**: Each template gets its own workspace and state file, preventing conflicts and enabling parallel development
- **Ruby DSL Power**: Write infrastructure using Ruby's expressive syntax while generating standard Terraform JSON
- **Automation-First**: Built for CI/CD with auto-approval by default and non-interactive operation
- **Type Safety**: Compile-time validation prevents configuration errors before deployment

## Prerequisites

Before starting, ensure you have:

```bash
# Ruby 3.1 or higher (3.3+ recommended)
ruby --version

# Terraform or OpenTofu
terraform --version
# OR
tofu --version

# AWS CLI (for AWS resources)
aws --version
```

## Installation

Install Pangea via RubyGems:

```bash
gem install pangea
```

Or add to your Gemfile:

```ruby
gem 'pangea'
```

Verify the installation:

```bash
pangea --version
```

## Your First Infrastructure Template

Let's start with a simple web server that demonstrates Pangea's core concepts.

### Step 1: Create Your First Template

Create a file called `web-server.rb`:

```ruby
# web-server.rb
template :web_infrastructure do
  provider :aws do
    region "us-east-1"
  end
  
  # VPC for our infrastructure
  resource :aws_vpc, :main do
    cidr_block "10.0.0.0/16"
    enable_dns_hostnames true
    enable_dns_support true
    
    tags do
      Name "WebServer-VPC"
      Environment "development"
    end
  end
  
  # Internet gateway for public access
  resource :aws_internet_gateway, :main do
    vpc_id ref(:aws_vpc, :main, :id)
    
    tags do
      Name "WebServer-IGW"
    end
  end
  
  # Public subnet
  resource :aws_subnet, :public do
    vpc_id ref(:aws_vpc, :main, :id)
    cidr_block "10.0.1.0/24"
    availability_zone "us-east-1a"
    map_public_ip_on_launch true
    
    tags do
      Name "WebServer-Public-Subnet"
    end
  end
  
  # Route table for internet access
  resource :aws_route_table, :public do
    vpc_id ref(:aws_vpc, :main, :id)
    
    route do
      cidr_block "0.0.0.0/0"
      gateway_id ref(:aws_internet_gateway, :main, :id)
    end
    
    tags do
      Name "WebServer-Public-RT"
    end
  end
  
  # Associate subnet with route table
  resource :aws_route_table_association, :public do
    subnet_id ref(:aws_subnet, :public, :id)
    route_table_id ref(:aws_route_table, :public, :id)
  end
  
  # Security group for web traffic
  resource :aws_security_group, :web do
    name_prefix "webserver-"
    vpc_id ref(:aws_vpc, :main, :id)
    description "Security group for web server"
    
    ingress do
      from_port 80
      to_port 80
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
    end
    
    ingress do
      from_port 443
      to_port 443
      protocol "tcp"
      cidr_blocks ["0.0.0.0/0"]
    end
    
    ingress do
      from_port 22
      to_port 22
      protocol "tcp"
      cidr_blocks ["10.0.0.0/16"]  # Only from VPC
    end
    
    egress do
      from_port 0
      to_port 0
      protocol "-1"
      cidr_blocks ["0.0.0.0/0"]
    end
    
    tags do
      Name "WebServer-SG"
    end
  end
  
  # Web server instance
  resource :aws_instance, :web do
    ami "ami-0c7217cdde317cfec"  # Ubuntu 22.04 LTS
    instance_type "t3.micro"
    subnet_id ref(:aws_subnet, :public, :id)
    vpc_security_group_ids [ref(:aws_security_group, :web, :id)]
    
    user_data <<~EOF
      #!/bin/bash
      apt-get update
      apt-get install -y nginx
      systemctl start nginx
      systemctl enable nginx
      echo '<h1>Hello from Pangea!</h1>' > /var/www/html/index.html
    EOF
    
    tags do
      Name "WebServer-Instance"
      Environment "development"
    end
  end
end
```

### Step 2: Configure Your Environment

Create a `pangea.yml` file in the same directory:

```yaml
default_namespace: development

namespaces:
  development:
    description: "Local development environment"
    state:
      type: local
      path: "terraform.tfstate"
  
  production:
    description: "Production environment with remote state"
    state:
      type: s3
      bucket: "your-terraform-state-bucket"
      key: "pangea/production/terraform.tfstate"
      region: "us-east-1"
      dynamodb_table: "terraform-state-locks"
      encrypt: true
```

### Step 3: Plan Your Infrastructure

Preview what Pangea will create:

```bash
pangea plan web-server.rb
```

You'll see output similar to:

```
Planning template: web_infrastructure
Namespace: development (local state)

Terraform will perform the following actions:
  # aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + cidr_block           = "10.0.0.0/16"
      + enable_dns_hostnames = true
      + enable_dns_support   = true
      ...
    }
  
  # aws_instance.web will be created
  + resource "aws_instance" "web" {
      + ami                    = "ami-0c7217cdde317cfec"
      + instance_type          = "t3.micro"
      ...
    }

Plan: 7 to add, 0 to change, 0 to destroy.
```

### Step 4: Deploy Your Infrastructure

Apply the changes to create your infrastructure:

```bash
pangea apply web-server.rb
```

Pangea will automatically approve and deploy your infrastructure. Within a few minutes, you'll have a running web server!

## Understanding What Just Happened

### Template Isolation
Notice that your infrastructure is defined in a `template :web_infrastructure` block. This creates a completely isolated workspace with its own state file. If you had multiple templates in the same file, each would be deployed independently.

### Resource References
The `ref(:aws_vpc, :main, :id)` syntax creates Terraform references like `${aws_vpc.main.id}`. This ensures proper dependency ordering and resource relationships.

### Automatic Workspace Management
Pangea automatically:
- Created a workspace directory
- Generated Terraform JSON from your Ruby code
- Initialized the Terraform backend
- Planned and applied the changes

## Next Steps: Adding a Database

Let's extend our infrastructure by adding a database in a separate template:

```ruby
# Add this to your web-server.rb file
template :database do
  provider :aws do
    region "us-east-1"
  end
  
  # Reference the VPC from the other template
  data :aws_vpc, :main do
    filter do
      name "tag:Name"
      values ["WebServer-VPC"]
    end
  end
  
  # Private subnet for database
  resource :aws_subnet, :private do
    vpc_id data(:aws_vpc, :main, :id)
    cidr_block "10.0.2.0/24"
    availability_zone "us-east-1b"
    
    tags do
      Name "Database-Private-Subnet"
    end
  end
  
  # Database subnet group
  resource :aws_db_subnet_group, :main do
    name_prefix "db-subnet-group-"
    subnet_ids [
      data(:aws_subnet, :public, :id),  # Reference from web_infrastructure
      ref(:aws_subnet, :private, :id)   # From this template
    ]
    
    tags do
      Name "Database-Subnet-Group"
    end
  end
  
  # Database instance
  resource :aws_db_instance, :main do
    identifier_prefix "webapp-db-"
    engine "mysql"
    engine_version "8.0"
    instance_class "db.t3.micro"
    allocated_storage 20
    storage_type "gp2"
    
    db_name "webapp"
    username "admin"
    password "changeme123!"  # Use AWS Secrets Manager in production!
    
    db_subnet_group_name ref(:aws_db_subnet_group, :main, :name)
    skip_final_snapshot true
    
    tags do
      Name "WebApp-Database"
      Environment "development"
    end
  end
end
```

Deploy just the database template:

```bash
pangea apply web-server.rb --template database
```

## Key Concepts Demonstrated

### 1. Template Isolation
Each template (`web_infrastructure` and `database`) has its own state file and can be deployed independently. This prevents conflicts and enables parallel development.

### 2. Cross-Template References
Templates can reference resources from other templates using data sources, enabling modular infrastructure design.

### 3. Selective Deployment
Use `--template` to deploy specific parts of your infrastructure, enabling incremental deployments and rollbacks.

### 4. Environment Management
The same templates work across environments by changing the namespace in your configuration.

## Environment Promotion

Deploy to production by switching namespaces:

```bash
# Plan production deployment
pangea plan web-server.rb --namespace production

# Deploy to production
pangea apply web-server.rb --namespace production
```

The same templates will deploy to production with remote state management automatically configured.

## Cleaning Up

Remove your infrastructure when you're done:

```bash
# Remove database first (due to dependencies)
pangea destroy web-server.rb --template database

# Then remove web infrastructure
pangea destroy web-server.rb --template web_infrastructure
```

## What's Next?

Now that you understand the basics, explore:

1. **[Template Isolation Guide](template-isolation.md)** - Deep dive into Pangea's isolation model
2. **[Multi-Environment Management](multi-environment-management.md)** - Managing dev, staging, and production
3. **[Type-Safe Infrastructure](type-safe-infrastructure.md)** - Leveraging Ruby's type system
4. **[CI/CD Integration](cicd-integration.md)** - Automating deployments

## Summary

In this guide, you've learned:

- How to install and configure Pangea
- The template-based infrastructure model
- Resource references and dependency management
- Environment promotion patterns
- Template isolation benefits

Pangea's template-level isolation and Ruby DSL provide a powerful foundation for scaling infrastructure management from simple projects to enterprise deployments. The automation-first design ensures your infrastructure code works seamlessly in CI/CD pipelines while the type-safe approach prevents configuration errors.

Ready to dive deeper? Check out the [Template Isolation Guide](template-isolation.md) to understand how Pangea's unique approach solves traditional infrastructure scaling challenges.