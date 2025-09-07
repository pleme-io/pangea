# Pangea Architecture

## Core Concept

Pangea is a scalable, automation-first infrastructure management tool that addresses key Terraform/OpenTofu scalability challenges through:

- **Template-level state isolation** (more granular than industry standard directory-based approaches)
- **Configuration-driven namespace management** for multi-environment backends  
- **Ruby DSL compilation** to Terraform JSON for enhanced abstraction capabilities
- **Automation-first design** with auto-approval and automatic initialization
- **Non-interactive operation** designed explicitly for CI/CD and automation workflows

This approach enables infrastructure management that scales with team size and complexity while reducing operational overhead. Unlike traditional Terraform approaches that rely on directory structures or monolithic state files, Pangea provides template-level granularity that matches how teams actually think about and manage infrastructure components.

## Resource Abstraction System

**Type-Safe Resource Functions**: Pangea provides pure, type-safe functions for infrastructure resources that replace raw DSL blocks with strongly-typed interfaces:

### Traditional Approach (Raw DSL)
```ruby
resource :aws_vpc, :main do
  cidr_block "10.0.0.0/16"
  enable_dns_hostnames true
  enable_dns_support true
  tags do
    Name "main-vpc"
    Environment "production"
  end
end
```

### Pangea Resource Functions (Type-Safe)
```ruby
aws_vpc(:main, {
  cidr_block: "10.0.0.0/16",
  enable_dns_hostnames: true,
  enable_dns_support: true,
  tags: {
    Name: "main-vpc",
    Environment: "production"
  }
})
```

**Benefits of Resource Abstraction:**
- **Type Safety**: RBS definitions provide compile-time checking, dry-struct provides runtime validation
- **IDE Support**: Better autocomplete, parameter hints, and error detection
- **Pure Functions**: No side effects, easier to test and reason about
- **Consistent Interface**: All resources follow the same `resource_type(name, attributes)` pattern
- **Default Values**: Functions provide sensible defaults and computed attributes
- **Custom Validation**: Beyond basic types, functions can enforce business rules

**Resource Function Architecture:**
- Functions accept a symbol name and a typed attributes hash
- Attributes are validated using dry-struct for runtime safety
- RBS type definitions provide compile-time safety in IDEs
- Functions generate standard terraform-synthesizer resource blocks
- Complete documentation available in `lib/pangea/resources/CLAUDE.md`

## Template Structure

Ruby files contain one or more template declarations using type-safe resource functions:

```ruby
template :networking do
  provider :aws do
    region "us-east-1"
  end

  # Type-safe VPC creation with validation
  aws_vpc(:main, {
    cidr_block: "10.0.0.0/16",
    enable_dns_hostnames: true,
    enable_dns_support: true,
    tags: { Name: "main-vpc", Environment: "production" }
  })
  
  # Type-safe subnet creation with references
  aws_subnet(:public_a, {
    vpc_id: ref(:aws_vpc, :main, :id),
    cidr_block: "10.0.1.0/24",
    availability_zone: "us-east-1a",
    map_public_ip_on_launch: true,
    tags: { Name: "public-subnet-a", Type: "public" }
  })
end

template :compute do
  provider :aws do
    region "us-east-1"
  end

  # Type-safe EC2 instance with strict attribute validation
  aws_instance(:web, {
    ami: "ami-12345678",
    instance_type: "t3.micro",
    subnet_id: ref(:aws_subnet, :public_a, :id),
    tags: { Name: "web-server", Type: "application" }
  })
end
```

## Scalable Workspace Management

**Template-Level Isolation Pattern:**
- Each `template :name` block creates a separate workspace with isolated state
- Workspace name = template name for clear identification
- All workspaces within a namespace share backend configuration but have separate state files
- Complete isolation prevents template conflicts and reduces blast radius
- Each template gets its own Terraform workspace directory and state file

**Key Innovation - Template-Based State Isolation:**
This is more granular than industry standard approaches:
- **Industry Standard**: Directory-based (one directory = one state file)
- **Pangea Approach**: Template-based (multiple templates in one file = multiple state files)
- **Result**: Better organization, clearer ownership, reduced state conflicts

**Scalability Benefits:**
- **Parallel Development**: Teams can work on different templates simultaneously without state conflicts
- **Granular Deployments**: Deploy/rollback individual infrastructure components independently
- **Reduced Risk**: Template failures don't affect other templates due to complete state isolation
- **State Management**: Automatic state key generation prevents conflicts across templates and namespaces
- **Component Ownership**: Teams can own specific templates within shared infrastructure files

**Directory Structure:**
```
~/.pangea/workspaces/
├── production/
│   ├── web_infrastructure/     # Template workspace
│   ├── database/              # Template workspace  
│   ├── monitoring/            # Template workspace
│   └── cdn/                   # Template workspace
└── development/
    ├── web_infrastructure/
    └── database/
```

## Multi-Environment Namespace Management

**Configuration-Driven Backend Pattern:**
Namespaces define environment-specific state backend configurations, enabling scalable multi-environment management:

```yaml
default_namespace: development  # Reduces CLI verbosity

namespaces:
  # Local development - fast iteration
  development:
    description: "Local development environment"
    state:
      type: local
      path: "terraform.tfstate"
    
  # Staging - production-like testing
  staging:
    description: "Staging environment with production backend"
    state:
      type: s3
      bucket: "terraform-state-staging"
      key: "pangea/staging/terraform.tfstate"
      region: "us-east-1"
      dynamodb_table: "terraform-state-lock-staging"
      encrypt: true
  
  # Production - high security, separate AWS account
  production:
    description: "Production environment"
    state:
      type: s3
      bucket: "terraform-state-prod"
      key: "pangea/production/terraform.tfstate"
      region: "us-east-1"
      dynamodb_table: "terraform-state-lock-prod"
      encrypt: true
      kms_key_id: "arn:aws:kms:us-east-1:...:key/..."
      
  # Multi-region production
  production_eu:
    description: "Production EU region"
    state:
      type: s3
      bucket: "terraform-state-prod-eu"
      key: "pangea/production-eu/terraform.tfstate"
      region: "eu-west-1"
      dynamodb_table: "terraform-state-lock-prod-eu"
```

**Backend State Key Generation:**
For each template, Pangea automatically generates unique state keys:
- S3 Backend: `${configured_key}/${template_name}/terraform.tfstate`
- Local Backend: Separate directories per template

**Scalability Advantages:**
- **Environment Proliferation**: Easy to add new environments (DR, testing, etc.)
- **Security Boundaries**: Different backends for different security requirements
- **Cost Optimization**: Local backends for development, S3 for production
- **Geographic Distribution**: Support for multi-region deployments

## Commands

**Minimalist Command Set**: Only three commands exist for focused, automation-first operation:

### `pangea plan <file> [--namespace <ns>] [--template <name>]`

- **Purpose**: Preview infrastructure changes without applying them
- **Template Processing**: If `--template` omitted, processes all templates in the file
- **Namespace**: If `--namespace` omitted, uses `default_namespace` from configuration
- **Output**: Colorized Terraform plan showing proposed changes
- **Automation**: Safe to run in CI/CD pipelines - no state changes

### `pangea apply <file> [--namespace <ns>] [--template <name>] [--no-auto-approve]`

- **Purpose**: Apply infrastructure changes for specified template(s)
- **Auto-Approval**: Auto-approves by default for streamlined automation
- **Manual Confirmation**: Use `--no-auto-approve` for rare cases requiring explicit confirmation
- **Template Isolation**: Each template applies to its own isolated workspace
- **Backend Management**: Automatic backend initialization and configuration

### `pangea destroy <file> [--namespace <ns>] [--template <name>] [--no-auto-approve]`

- **Purpose**: Destroy infrastructure for specified template(s)  
- **Auto-Approval**: Auto-approves by default for automation workflows
- **Safety**: Template isolation limits blast radius to single template's resources
- **Manual Confirmation**: Use `--no-auto-approve` when human oversight is required
- **Cleanup**: Automatic workspace and state cleanup after successful destruction

## Implementation Notes

**Design Philosophy**: Automation-first, non-interactive infrastructure management

- **No `init` command** - initialization happens automatically when needed, reducing operational steps
- **Non-interactive design** - all operations are argument-driven for seamless CI/CD compatibility
- **Auto-approval by default** - streamlined automation with explicit opt-in confirmation (`--no-auto-approve`)
- **Default namespace support** - eliminates repetitive `--namespace` flags through configuration
- **Template-based workspace isolation** - more granular than industry standard directory-based approaches
- **Cross-provider templates** - templates can reference different providers/regions within same file
- **Automatic state separation** - prevents template interference through completely isolated state files
- **Ruby DSL compilation** - templates compiled to Terraform JSON using terraform-synthesizer library
- **Configuration-driven backends** - namespace configuration automatically manages state backends

## Scalability Patterns Enabled

### 1. Component-Based Infrastructure
```ruby
# Single file, multiple logical components
template :networking do
  # VPC, subnets, security groups
end

template :compute do
  # EC2, ASG, load balancers
end

template :data do
  # RDS, ElastiCache, S3
end
```

### 2. Service-Oriented Infrastructure
```ruby
# user-service.rb
template :api do
  # API infrastructure
end

template :database do
  # Service-specific database
end

template :cache do
  # Service-specific cache
end
```

### 3. Environment Promotion Pattern
```bash
# Develop locally
pangea plan app.rb --namespace development
pangea apply app.rb --namespace development

# Test in staging
pangea plan app.rb --namespace staging  
pangea apply app.rb --namespace staging

# Deploy to production
pangea plan app.rb --namespace production
pangea apply app.rb --namespace production
```

### 4. Incremental Infrastructure Delivery
```bash
# Deploy foundation
pangea apply infrastructure.rb --template networking
pangea apply infrastructure.rb --template security

# Deploy applications incrementally
pangea apply applications.rb --template user_service
pangea apply applications.rb --template order_service
pangea apply applications.rb --template payment_service

# Deploy monitoring after apps are stable
pangea apply observability.rb --template monitoring
```

## Advantages Over Traditional Approaches

**Pangea addresses fundamental scalability challenges in existing Terraform tooling:**

### vs. Directory-Based Terraform
- **Reduced File Sprawl**: Multiple templates in single files vs scattered directories
- **Automatic Backend Management**: No manual backend configuration per component
- **Ruby DSL Power**: Better abstraction than HCL for complex logic and conditionals
- **State Organization**: Template-based isolation vs directory-based organization
- **Code Reuse**: Shared helper methods and logic within files

### vs. Terragrunt
- **Configuration Simplicity**: Single YAML file vs multiple terragrunt.hcl files across directories
- **Template Isolation**: Built-in template-level isolation vs manual workspace management
- **Ruby Ecosystem**: Access to full Ruby library ecosystem for infrastructure logic
- **No DRY Complexity**: Templates handle repetition naturally vs complex DRY configurations
- **Dependency Management**: Remote state references vs complex dependency declarations

### vs. Terraform Workspaces
- **True State Isolation**: Completely separate state files vs shared backend with workspace prefixes
- **Security Boundaries**: No cross-template state access vs potential workspace bleed
- **Template Granularity**: Template-specific configurations vs workspace-level configurations
- **Operational Clarity**: Template names match infrastructure components vs abstract workspace names

### vs. Terraform Cloud/Enterprise
- **Local Control**: No dependency on external SaaS platforms
- **Cost Efficiency**: No per-user or per-run pricing
- **Template Flexibility**: Ruby DSL vs HCL limitations
- **State Backends**: Direct backend control vs platform-managed state
- **Automation Integration**: Direct CLI integration vs API/webhook complexity

## Enterprise Scalability Considerations

### Team Collaboration Patterns
- **Template Ownership**: Teams can own specific templates within shared infrastructure files
- **Independent Deployment**: Templates deploy independently without coordination overhead
- **Code Review**: Ruby DSL enables better code review practices with familiar syntax
- **Parallel Development**: Multiple teams can work simultaneously without state conflicts
- **Knowledge Sharing**: Ruby familiarity reduces infrastructure-as-code learning curve

### Infrastructure Evolution Strategies
- **Gradual Migration**: Migrate infrastructure template by template from existing tools
- **A/B Infrastructure**: Run multiple versions of templates simultaneously for testing
- **Component Lifecycle**: Independent lifecycle management per template enables selective updates
- **Template Versioning**: Ruby files can be version controlled with standard Git workflows
- **Incremental Delivery**: Deploy infrastructure components incrementally as dependencies are satisfied

### Operational Excellence Benefits
- **Blast Radius Reduction**: Template failures are completely isolated to single components
- **Deployment Flexibility**: Deploy subsets of infrastructure based on change requirements
- **State Management**: Automatic state file organization, cleanup, and conflict prevention
- **Monitoring Integration**: Each template can define its own monitoring and alerting resources
- **Rollback Granularity**: Roll back individual templates without affecting entire infrastructure

### CI/CD Integration Patterns
- **Pipeline Efficiency**: Only plan/apply templates that have changed in commits
- **Environment Promotion**: Same template files work across all environments via namespace configuration
- **Approval Workflows**: Use `--no-auto-approve` for production deployments requiring human approval
- **Testing Integration**: Template isolation enables infrastructure testing in parallel
- **Deployment Orchestration**: Template dependencies can be managed through CI/CD pipeline ordering

## Terraform Resource Processing

**Ruby DSL to Terraform JSON Compilation:**

Template blocks are processed using the underlying `terraform-synthesizer` library to convert Ruby DSL into Terraform-compliant JSON:

### Compilation Flow
1. **Template Extraction**: Parse Ruby files to extract `template :name do...end` blocks
2. **DSL Processing**: Use `TerraformSynthesizer` to evaluate Ruby DSL within template context
3. **JSON Generation**: Convert synthesized Hash to Terraform-compatible JSON
4. **Workspace Isolation**: Write JSON to template-specific workspace directory
5. **Backend Injection**: Automatically inject namespace backend configuration

### Synthesizer Interface
```ruby
synthesizer = TerraformSynthesizer.new
synthesizer.instance_eval(template_content, source_file, 1)

# Backend configuration is automatically injected
backend_config = namespace.to_terraform_backend
backend_config[:s3][:key] = "#{original_key}/#{template_name}"

synthesizer.synthesize do
  terraform do
    backend(backend_config)
  end
end

tf_hash = synthesizer.synthesis  # Returns Hash
tf_json = JSON.pretty_generate(tf_hash)  # Convert to JSON
```

### Template Processing Architecture
- **Isolated Evaluation**: Each template evaluates in its own synthesizer context
- **Automatic Backend Injection**: Namespace configuration automatically generates backend blocks
- **State Key Generation**: Template names automatically generate unique state keys
- **Resource Validation**: Compilation validates resource syntax before Terraform execution
- **Error Handling**: Syntax errors are captured with line number context for debugging

This compilation approach enables the Ruby DSL abstraction while maintaining full Terraform compatibility and feature support.

## Architecture Abstraction System

**Complete Infrastructure Solutions**: Beyond type-safe resource functions, Pangea provides architecture-level abstractions that compose entire infrastructure patterns using pure functions and comprehensive type safety:

### Architecture Hierarchy

```
Architecture Functions    (Highest Level - Complete Solutions)
    ↓ uses
Resource Functions       (Mid Level - Individual Resources)  
    ↓ uses
Terraform Synthesizer    (Low Level - Raw Terraform DSL)
```

### Architecture vs Resource vs Raw DSL

**Raw Terraform DSL** (Lowest Level):
```ruby
resource :aws_vpc, :main do
  cidr_block "10.0.0.0/16"
  enable_dns_hostnames true
end

resource :aws_subnet, :public_a do
  vpc_id ref(:aws_vpc, :main, :id)
  cidr_block "10.0.1.0/24"
  availability_zone "us-east-1a"
end

# ... dozens more resources for complete application
```

**Resource Functions** (Mid Level):
```ruby
vpc_ref = aws_vpc(:main, {
  cidr_block: "10.0.0.0/16",
  enable_dns_hostnames: true
})

subnet_ref = aws_subnet(:public_a, {
  vpc_id: vpc_ref.id,
  cidr_block: "10.0.1.0/24", 
  availability_zone: "us-east-1a"
})

# ... still need to compose many resources manually
```

**Architecture Functions** (Highest Level):
```ruby
web_app = web_application_architecture(:myapp, {
  domain: "myapp.com",
  environment: "production",
  high_availability: true,
  auto_scaling: { min: 2, max: 10 },
  database_engine: "postgresql"
})

# Creates complete 3-tier architecture:
# - VPC with public/private subnets across multiple AZs
# - Application Load Balancer with SSL termination
# - Auto Scaling Group with launch template
# - RDS PostgreSQL database with backups
# - CloudWatch monitoring and alarms
# - Security groups with least privilege access
# - S3 buckets for assets and logs
```

### Architecture Function Categories

**1. Application Architectures**
Complete application stacks with web, app, and data tiers:
- `web_application_architecture`: Standard 3-tier web application with load balancer, auto-scaling, and database
- `single_page_application_architecture`: SPA with CDN and API backend
- `mobile_backend_architecture`: Mobile app backend with push notifications
- `api_first_architecture`: API-centric architecture with multiple frontends

**2. Data Architectures** 
Data processing, storage, and analytics patterns:
- `data_lake_architecture`: S3-based data lake with Kinesis ingestion, Glue ETL, and Athena/Redshift analytics
- `streaming_data_architecture`: Real-time streaming with Kinesis Analytics and multi-destination outputs
- `data_warehouse_architecture`: Redshift/Snowflake analytical warehouse with data pipeline
- `batch_processing_architecture`: EMR/Glue batch data processing with scheduling

**3. Microservices Architectures**
Service-oriented and microservices patterns:
- `microservices_platform_architecture`: Service mesh with ECS/EKS, service discovery, and shared services
- `microservice_architecture`: Individual microservice with database, monitoring, and platform integration
- `event_driven_architecture`: Event-sourcing with SQS/SNS message queues
- `serverless_microservices_architecture`: Lambda-based microservices with API Gateway

### Architecture Function Benefits

**1. Complete Solutions**: Production-ready infrastructure patterns out of the box
- All necessary resources created automatically
- Best practices encoded in architecture functions
- Security, monitoring, and scaling built-in by default

**2. Type Safety and Validation**
- `dry-struct` validation of architecture parameters
- Rich `ArchitectureReference` return values with all created resources
- RBS support for compile-time type checking
- Runtime validation of configuration compatibility

**3. Override and Customization**
- Override any component while maintaining overall pattern
- Extend architectures with additional resources
- Compose multiple architectures together
- Parameter-driven customization for all aspects

**4. Multi-Architecture Composition**
- Cross-architecture resource sharing and references
- Computed outputs derived from resource properties
- Architecture-level health checks and validation
- Cost estimation and security compliance scoring

### Architecture Function Usage in Templates

Architecture functions integrate seamlessly with Pangea templates:

```ruby
template :complete_ecommerce_platform do
  include Pangea::Architectures::Patterns

  # Create complete e-commerce platform with web app, microservices, and analytics
  platform = ecommerce_platform_architecture(:mystore, {
    domain: "mystore.com",
    environment: "production",
    regions: ["us-east-1", "us-west-2"]
  })

  # Override specific components
  platform.web_application.override(:database) do |arch_ref|
    aurora_serverless_cluster(:"#{arch_ref.name}_db", {
      engine: "aurora-postgresql",
      vpc_ref: arch_ref.network.vpc,
      scaling: { min_capacity: 2, max_capacity: 16 }
    })
  end

  # Template outputs from architecture
  output :web_app_url do
    value platform.web_application.load_balancer.dns_name
  end

  output :microservices_cluster do
    value platform.microservices_platform.compute[:cluster].name
  end

  output :analytics_bucket do
    value platform.analytics.storage[:processed_bucket].bucket
  end

  output :estimated_monthly_cost do
    value platform.estimated_monthly_cost
    description "Estimated monthly AWS cost for complete platform"
  end
end
```

### Real-World Architecture Examples

**Complete E-commerce Platform**:
```ruby
ecommerce = ecommerce_platform_architecture(:mystore, {
  domain: "mystore.com",
  environment: "production"
})

# Creates:
# - Web application (ALB + Auto Scaling + RDS)
# - Microservices platform (ECS + service mesh)
# - Individual services (user, inventory, order, payment)
# - Data analytics pipeline (data lake + streaming)
# - Cross-service communication and monitoring
```

**Multi-Region SaaS Platform**:
```ruby
saas = multi_region_saas_architecture(:saas_app, {
  primary_region: "us-east-1",
  secondary_region: "us-west-2",
  domain: "saas-app.com"
})

# Creates:
# - Primary region deployment with full stack
# - Secondary region for disaster recovery
# - Global streaming data architecture
# - Cross-region data replication
```

**AI/ML Platform**:
```ruby
ml_platform = ml_platform_architecture(:ai_platform, {
  domain: "ml.company.com",
  environment: "production"
})

# Creates:
# - Data lake with S3 + processing pipelines
# - Real-time streaming for model inference
# - Web application for model management
# - SageMaker training and inference endpoints
# - Model registry and versioning
```

### Architecture System Location

All architecture abstractions are located in:
- **Base Framework**: `lib/pangea/architectures/base.rb`
- **Architecture Patterns**: `lib/pangea/architectures/patterns/`
  - `web_application.rb`: 3-tier web application patterns
  - `microservices.rb`: Service mesh and microservice patterns  
  - `data_processing.rb`: Data lake and streaming patterns
- **Composition Examples**: `lib/pangea/architectures/examples.rb`
- **Documentation**: `lib/pangea/architectures/CLAUDE.md`

This architecture abstraction system represents the highest level of infrastructure composition in Pangea, enabling teams to deploy production-ready infrastructure patterns with a single function call while maintaining full customization and override capabilities.

