# Pangea Architecture Abstraction System

## Overview

Pangea's architecture abstraction system provides the highest level of infrastructure composition, building on top of type-safe resource functions to create complete, production-ready infrastructure patterns. Architecture functions are pure functions that compose multiple resource functions and other architectures to create complex, reusable infrastructure solutions.

## Architecture Hierarchy

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
```

**Resource Functions** (Mid Level):
```ruby
vpc_ref = aws_vpc(:main, {
  cidr_block: "10.0.0.0/16",
  enable_dns_hostnames: true
})
```

**Architecture Functions** (Highest Level):
```ruby
web_app = web_application_architecture(:myapp, {
  domain: "myapp.com",
  environment: "production",
  high_availability: true,
  auto_scaling: { min: 2, max: 10 }
})
```

## Architecture Function Characteristics

### 1. Pure Functions
- **No Side Effects**: Only create infrastructure, no global state changes
- **Predictable**: Same inputs always produce same infrastructure
- **Testable**: Can be unit tested independently
- **Composable**: Can be combined with other architectures

### 2. Type Safety
- **Input Validation**: dry-struct validation of architecture parameters
- **Return Values**: Rich ArchitectureReference objects with all created resources
- **RBS Support**: Compile-time type checking for all architecture functions
- **Runtime Checks**: Validate configuration compatibility and constraints

### 3. Override and Customization
- **Parameter Override**: All architecture aspects can be customized
- **Resource Override**: Replace individual resources with custom implementations
- **Composition Override**: Modify how resources are connected
- **Extension Points**: Add custom resources to standard architectures

### 4. Multi-Resource Composition
- **Cross-Resource Dependencies**: Automatic wiring of resource references
- **Resource Collections**: Manage groups of related resources together
- **Computed Outputs**: Derive architecture-level outputs from resource properties
- **Health Checks**: Built-in monitoring and alerting for architecture patterns

## Architecture Function Patterns

### Basic Architecture Function Structure

```ruby
def web_application_architecture(name, attributes = {})
  # 1. Validate and set defaults
  arch_attrs = WebApplicationAttributes.new(attributes)
  arch_ref = ArchitectureReference.new('web_application', name)
  
  # 2. Create foundational resources
  arch_ref.network = vpc_with_subnets(:"#{name}_network",
    vpc_cidr: arch_attrs.vpc_cidr,
    availability_zones: arch_attrs.availability_zones
  )
  
  # 3. Create application tier
  arch_ref.load_balancer = aws_application_load_balancer(:"#{name}_alb", {
    vpc_id: arch_ref.network.vpc.id,
    subnet_ids: arch_ref.network.public_subnet_ids,
    security_group_ids: [arch_ref.web_security_group.id]
  })
  
  # 4. Create compute tier
  arch_ref.web_tier = auto_scaling_web_tier(:"#{name}_web",
    vpc_ref: arch_ref.network.vpc,
    subnet_refs: arch_ref.network.private_subnets,
    load_balancer_ref: arch_ref.load_balancer
  )
  
  # 5. Create data tier (if enabled)
  if arch_attrs.database_enabled
    arch_ref.database = rds_cluster(:"#{name}_db", {
      vpc_ref: arch_ref.network.vpc,
      subnet_refs: arch_ref.network.private_subnets,
      engine: arch_attrs.database_engine
    })
  end
  
  # 6. Create monitoring tier
  arch_ref.monitoring = monitoring_stack(:"#{name}_monitoring", {
    resources: arch_ref.all_resources,
    alerts: arch_attrs.alert_config
  })
  
  # 7. Return architecture reference
  arch_ref
end
```

### Architecture Reference Objects

Architecture functions return `ArchitectureReference` objects that provide:

1. **Resource Collections**: Access to all created resources by tier/function
2. **Cross-Architecture References**: Use outputs in other architectures
3. **Computed Properties**: Architecture-level derived attributes
4. **Override Methods**: Customize or replace parts of the architecture
5. **Validation Methods**: Health checks and configuration validation

```ruby
# Architecture function returns ArchitectureReference
web_app = web_application_architecture(:myapp, {
  domain: "myapp.com",
  environment: "production"
})

# Access resource collections
web_app.network.vpc.id                    # VPC from network tier
web_app.web_tier.instances                # Auto-scaling group instances
web_app.database.endpoint                 # Database connection endpoint
web_app.monitoring.dashboard_url          # CloudWatch dashboard

# Access computed properties  
web_app.estimated_monthly_cost            # Cost estimation
web_app.availability_zones.count          # AZ distribution
web_app.is_highly_available?              # HA validation
web_app.security_compliance_score         # Security assessment

# Override specific components
web_app.override_database do
  # Custom database configuration
  aurora_serverless_cluster(:"#{name}_db", {
    engine: "aurora-postgresql",
    scaling: { min_capacity: 2, max_capacity: 16 }
  })
end

# Use in other architectures
data_pipeline = data_processing_architecture(:analytics, {
  vpc_ref: web_app.network.vpc,           # Reuse network
  database_ref: web_app.database,         # Connect to existing DB
  source_bucket: web_app.storage.logs_bucket
})
```

## Architecture Categories

### 1. Application Architectures
Complete application stacks with web, app, and data tiers:

- **web_application_architecture**: Standard 3-tier web application
- **single_page_application_architecture**: SPA with CDN and API backend
- **mobile_backend_architecture**: Mobile app backend with push notifications
- **api_first_architecture**: API-centric architecture with multiple frontends

### 2. Data Architectures
Data processing, storage, and analytics patterns:

- **data_lake_architecture**: S3-based data lake with processing pipelines
- **data_warehouse_architecture**: Redshift/Snowflake analytical warehouse
- **real_time_streaming_architecture**: Kinesis/Kafka streaming processing
- **batch_processing_architecture**: EMR/Glue batch data processing

### 3. Microservices Architectures
Service-oriented and microservices patterns:

- **microservices_platform_architecture**: Service mesh with discovery and routing
- **event_driven_architecture**: Event-sourcing with message queues
- **serverless_microservices_architecture**: Lambda-based microservices
- **container_orchestration_architecture**: EKS/ECS container platform

### 4. Infrastructure Architectures
Platform and infrastructure service patterns:

- **monitoring_architecture**: Complete observability stack
- **security_architecture**: Security services and compliance framework
- **networking_architecture**: Advanced networking with transit gateways
- **backup_disaster_recovery_architecture**: Backup and DR solutions

## Architecture Composition Patterns

### Layered Architecture Composition

```ruby
# Foundation layer
foundation = networking_architecture(:foundation, {
  vpc_cidr: "10.0.0.0/16",
  regions: ["us-east-1", "us-west-2"],
  transit_gateway: true
})

# Security layer
security = security_architecture(:security, {
  foundation_ref: foundation,
  compliance: "pci-dss",
  threat_detection: true
})

# Application layer
web_app = web_application_architecture(:app, {
  foundation_ref: foundation,
  security_ref: security,
  domain: "myapp.com"
})

# Data layer
data_platform = data_processing_architecture(:analytics, {
  foundation_ref: foundation,
  security_ref: security,
  source_app_ref: web_app
})
```

### Microservices Ecosystem

```ruby
# Platform foundation
platform = microservices_platform_architecture(:platform, {
  vpc_cidr: "10.0.0.0/16",
  service_mesh: "istio",
  observability: true
})

# Individual services using platform
user_service = microservice_architecture(:user_service, {
  platform_ref: platform,
  runtime: "nodejs",
  database: "postgresql"
})

order_service = microservice_architecture(:order_service, {
  platform_ref: platform,
  runtime: "java",
  database: "postgresql",
  depends_on: [user_service]
})

payment_service = microservice_architecture(:payment_service, {
  platform_ref: platform,
  runtime: "golang", 
  database: "postgresql",
  security_level: "high",
  depends_on: [user_service, order_service]
})
```

### Multi-Environment Architecture

```ruby
# Define architecture function
def deploy_web_app_to_environment(name, environment, base_config = {})
  config = base_config.merge(
    environment: environment,
    high_availability: environment == "production",
    auto_scaling: environment == "production" ? { min: 3, max: 20 } : { min: 1, max: 3 },
    database_backup_retention: environment == "production" ? 30 : 7
  )
  
  web_application_architecture(name, config)
end

# Deploy to multiple environments
dev_app = deploy_web_app_to_environment(:myapp_dev, "development", {
  domain: "dev.myapp.com",
  instance_type: "t3.micro"
})

staging_app = deploy_web_app_to_environment(:myapp_staging, "staging", {
  domain: "staging.myapp.com", 
  instance_type: "t3.small"
})

prod_app = deploy_web_app_to_environment(:myapp_prod, "production", {
  domain: "myapp.com",
  instance_type: "c5.large",
  cdn_enabled: true,
  waf_enabled: true
})
```

## Override and Extension Patterns

### Resource Override

```ruby
web_app = web_application_architecture(:myapp, base_config)

# Override database with custom implementation
web_app.override(:database) do |arch_ref|
  # Replace RDS with Aurora Serverless
  aurora_serverless_cluster(:"#{arch_ref.name}_db", {
    engine: "aurora-postgresql",
    vpc_ref: arch_ref.network.vpc,
    subnet_refs: arch_ref.network.private_subnets,
    scaling: { min_capacity: 2, max_capacity: 16 },
    auto_pause: true
  })
end

# Add additional resources
web_app.extend do |arch_ref|
  # Add Redis cache
  arch_ref.cache = elasticache_redis_cluster(:"#{arch_ref.name}_cache", {
    vpc_ref: arch_ref.network.vpc,
    subnet_refs: arch_ref.network.private_subnets,
    node_type: "cache.t3.micro"
  })
  
  # Connect web tier to cache
  arch_ref.web_tier.add_environment_variable("REDIS_URL", arch_ref.cache.endpoint)
end
```

### Architecture Composition Override

```ruby
# Custom web application with specific data processing needs
custom_web_app = web_application_architecture(:custom_app, {
  domain: "custom.com"
}).compose_with do |arch_ref|
  
  # Add data processing pipeline
  arch_ref.data_pipeline = data_processing_architecture(:"#{arch_ref.name}_data", {
    vpc_ref: arch_ref.network.vpc,
    source_database_ref: arch_ref.database,
    processing_schedule: "daily"
  })
  
  # Add machine learning inference
  arch_ref.ml_inference = ml_inference_architecture(:"#{arch_ref.name}_ml", {
    vpc_ref: arch_ref.network.vpc,
    model_s3_path: "s3://models/production/",
    instance_type: "ml.m5.large"
  })
end
```

## Integration with Templates

Architecture functions integrate seamlessly with Pangea templates:

```ruby
template :complete_web_application do
  include Pangea::Architectures::Patterns  # Enable architecture functions
  
  # Create complete web application architecture
  web_app = web_application_architecture(:myapp, {
    domain: "myapp.com",
    environment: "production",
    high_availability: true,
    auto_scaling: { min: 3, max: 15 },
    database_engine: "postgresql",
    cdn_enabled: true,
    waf_enabled: true
  })
  
  # Override specific components as needed
  web_app.override(:monitoring) do |arch_ref|
    # Custom monitoring with external service
    datadog_monitoring_stack(:"#{arch_ref.name}_monitoring", {
      api_key: var(:datadog_api_key),
      resources: arch_ref.all_resources
    })
  end
  
  # Template outputs from architecture
  output :application_url do
    value web_app.load_balancer.dns_name
    description "Application load balancer URL"
  end
  
  output :database_endpoint do
    value web_app.database.endpoint
    description "Database connection endpoint"
  end
  
  output :architecture_summary do
    value {
      name: web_app.name,
      type: web_app.architecture_type,
      availability_zones: web_app.availability_zones.count,
      estimated_cost: web_app.estimated_monthly_cost,
      high_availability: web_app.is_highly_available?,
      security_score: web_app.security_compliance_score
    }
    description "Complete architecture summary"
  end
end
```

## Benefits of Architecture Functions

1. **Complete Solutions**: Production-ready infrastructure patterns out of the box
2. **Best Practices**: Encode architectural best practices and patterns
3. **Consistency**: Standardized approaches across teams and projects
4. **Customization**: Override and extend any aspect while maintaining patterns
5. **Composition**: Combine multiple architectures into complex systems
6. **Cost Optimization**: Built-in cost estimation and optimization recommendations
7. **Security**: Security best practices baked into architecture patterns
8. **Monitoring**: Comprehensive monitoring and alerting included by default
9. **Scalability**: Auto-scaling and performance optimization built-in
10. **Documentation**: Self-documenting infrastructure through architecture types

This approach elevates infrastructure management from resource-by-resource construction to complete architecture composition, dramatically reducing complexity while maintaining full flexibility and customization capabilities.