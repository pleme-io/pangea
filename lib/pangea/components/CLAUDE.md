# Pangea Component Abstraction System

## Overview

Pangea's component system provides a middle abstraction layer between individual resources and complete architectures. Components are reusable, type-safe building blocks that either enhance single resources with specialized configurations or compose multiple related resources into common patterns.

## Component Hierarchy

```
Architectures (Complete Infrastructure Solutions)
    ↓ uses
Components (Reusable Building Blocks)
    ↓ uses
Resources (Individual AWS Resources)
    ↓ uses
Terraform Synthesizer (Raw Terraform DSL)
```

## Component Design Principles

### 1. Type Safety Requirements
**All components MUST be typed using both:**
- **RBS definitions** for compile-time type checking
- **dry-struct libraries** for runtime validation

```ruby
# Component type definition (required)
module Pangea
  module Components
    class SecureVpcAttributes < Dry::Struct
      attribute :name, Types::String
      attribute :cidr_block, Types::String
      attribute :availability_zones, Types::Array.of(Types::String)
      attribute :enable_flow_logs, Types::Bool.default(true)
      attribute :tags, Types::Hash.default({})
    end
  end
end
```

### 2. Resource Function Constraints
**Components can ONLY call our typed resource functions:**
- ✅ `aws_vpc(:main, { cidr_block: "10.0.0.0/16" })`
- ✅ `aws_subnet(:public, { vpc_id: vpc.id })`
- ❌ Direct terraform-synthesizer calls
- ❌ Raw terraform resource blocks

### 3. Component Categories

**Specialized Resource Components:**
- Enhanced versions of single resources with security/best practices
- Example: `secure_vpc` (VPC with flow logs, encryption, monitoring)

**Composite Resource Components:**
- Groups of related resources forming reusable patterns
- Example: `public_private_subnets` (subnet pair with routing and NAT)

## Component vs Resource vs Architecture

### Resource Functions
- **Scope**: Single AWS resource abstraction
- **Purpose**: Type-safe interface to individual terraform resources
- **Example**: `aws_vpc`, `aws_subnet`, `aws_security_group`
- **Returns**: ResourceReference for single resource

### Components
- **Scope**: Specialized resource or small group of related resources
- **Purpose**: Reusable patterns and best-practice configurations
- **Example**: `secure_vpc`, `web_tier_subnets`, `application_load_balancer`
- **Returns**: ComponentReference with multiple resource references

### Architectures
- **Scope**: Complete infrastructure solutions
- **Purpose**: Full application/system deployment patterns
- **Example**: `web_application_architecture`, `data_lake_architecture`
- **Returns**: ArchitectureReference with complete infrastructure

## Implementation Pattern

### Component Function Structure
```ruby
module Pangea
  module Components
    def secure_vpc(name, attributes = {})
      # 1. Validate input attributes
      component_attrs = SecureVpcAttributes.new(attributes)
      
      # 2. Call only typed resource functions
      vpc_ref = aws_vpc(:"#{name}_vpc", {
        cidr_block: component_attrs.cidr_block,
        enable_dns_hostnames: true,
        enable_dns_support: true,
        tags: component_attrs.tags.merge({
          Component: "SecureVpc",
          Security: "Enhanced"
        })
      })
      
      # 3. Add security enhancements
      flow_logs = aws_flow_log(:"#{name}_flow_logs", {
        resource_type: "VPC",
        resource_id: vpc_ref.id,
        traffic_type: "ALL",
        log_destination: "cloud-watch-logs"
      }) if component_attrs.enable_flow_logs
      
      # 4. Return ComponentReference
      ComponentReference.new(
        type: 'secure_vpc',
        name: name,
        component_attributes: component_attrs.to_h,
        resources: {
          vpc: vpc_ref,
          flow_logs: flow_logs
        },
        outputs: {
          vpc_id: vpc_ref.id,
          vpc_cidr: vpc_ref.cidr_block,
          flow_logs_enabled: !!flow_logs
        }
      )
    end
  end
end
```

### RBS Type Definitions (Required)
```ruby
# sig/pangea/components.rbs
module Pangea
  module Components
    type secure_vpc_attributes = {
      name: String,
      cidr_block: String,
      availability_zones: Array[String],
      enable_flow_logs: bool,
      tags: Hash[Symbol, String]
    }
    
    def secure_vpc: (Symbol, secure_vpc_attributes) -> ComponentReference
  end
end
```

## Component Reference System

### ComponentReference Class
```ruby
class ComponentReference
  attr_reader :type, :name, :component_attributes, :resources, :outputs
  
  def initialize(type:, name:, component_attributes:, resources:, outputs:)
    @type = type
    @name = name
    @component_attributes = component_attributes
    @resources = resources
    @outputs = outputs
  end
  
  # Access individual resources
  def vpc
    resources[:vpc]
  end
  
  # Access computed outputs
  def vpc_id
    outputs[:vpc_id]
  end
  
  # Helper methods
  def security_features
    features = []
    features << "VPC Flow Logs" if resources[:flow_logs]
    features << "DNS Resolution" if resources[:vpc].enable_dns_support
    features
  end
end
```

## Component Categories

### 1. Networking Components
- **secure_vpc**: VPC with flow logs, DNS resolution, security groups
- **public_private_subnets**: Subnet pair with proper routing
- **web_tier_subnets**: Public subnets across multiple AZs for web tier
- **app_tier_subnets**: Private subnets for application tier
- **db_tier_subnets**: Database subnets with subnet groups

### 2. Security Components
- **web_security_group**: Common web server security rules
- **app_security_group**: Application tier security rules
- **db_security_group**: Database security rules
- **bastion_security_group**: Bastion host access rules
- **internal_security_group**: Internal service communication

### 3. Compute Components
- **web_server_instance**: EC2 with web server configuration
- **bastion_host**: Secure jump box with logging
- **auto_scaling_web_servers**: ASG with launch template and policies
- **container_cluster**: ECS cluster with capacity providers
- **serverless_function**: Lambda with IAM role and logging

### 4. Database Components
- **mysql_database**: RDS MySQL with backups and monitoring
- **postgresql_database**: RDS PostgreSQL with security
- **redis_cache**: ElastiCache Redis with encryption
- **dynamodb_table**: DynamoDB with encryption and backups
- **document_database**: DocumentDB cluster with security

### 5. Storage Components
- **secure_s3_bucket**: S3 with encryption, versioning, lifecycle
- **static_website_bucket**: S3 configured for static hosting
- **backup_bucket**: S3 for backups with lifecycle policies
- **data_lake_bucket**: S3 for analytics with partitioning
- **application_file_system**: EFS with encryption and access points

### 6. Load Balancing Components
- **application_load_balancer**: ALB with target groups and health checks
- **network_load_balancer**: NLB for high performance
- **internal_load_balancer**: Internal ALB for service-to-service
- **api_gateway_rest**: REST API Gateway with common configurations
- **api_gateway_websocket**: WebSocket API for real-time communication

## Usage in Templates

### Template Integration
```ruby
template :secure_infrastructure do
  include Pangea::Resources::AWS
  include Pangea::Components
  
  # Use components for reusable patterns
  network = secure_vpc(:main, {
    cidr_block: "10.0.0.0/16",
    availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"]
  })
  
  web_subnets = public_private_subnets(:web_tier, {
    vpc_ref: network.vpc,
    public_cidrs: ["10.0.1.0/24", "10.0.2.0/24"],
    private_cidrs: ["10.0.10.0/24", "10.0.20.0/24"]
  })
  
  load_balancer = application_load_balancer(:web_lb, {
    subnet_refs: web_subnets.public_subnets,
    security_group_refs: [web_subnets.load_balancer_sg]
  })
  
  # Components compose naturally
  database = mysql_database(:app_db, {
    subnet_refs: web_subnets.private_subnets,
    vpc_ref: network.vpc
  })
end
```

### Architecture Integration
Components are designed to be used by architectures:

```ruby
def web_application_architecture(name, attributes = {})
  # Architectures use components as building blocks
  network = secure_vpc(:"#{name}_network", network_config)
  web_tier = web_tier_infrastructure(:"#{name}_web", web_config)
  db_tier = mysql_database(:"#{name}_db", db_config)
  
  # Architectures provide complete solutions
  # Components provide reusable building blocks
end
```

## Benefits of Components

### 1. Reusability
- Common patterns don't need to be reimplemented
- Best practices are encoded in reusable components
- Teams can share components across projects

### 2. Consistency
- Security configurations are standardized
- Naming conventions are enforced
- Common mistakes are prevented

### 3. Maintainability
- Changes to patterns are centralized in components
- Updates propagate to all usage locations
- Testing is focused on component level

### 4. Composability
- Components can be used together naturally
- Components can be used in architectures
- Components can reference each other appropriately

### 5. Type Safety
- All inputs are validated at runtime
- IDE support with compile-time checking
- Meaningful error messages for configuration issues

## Testing Components

### Component Testing Pattern
```ruby
RSpec.describe Pangea::Components do
  describe "#secure_vpc" do
    it "creates VPC with security enhancements" do
      component = secure_vpc(:test, {
        cidr_block: "10.0.0.0/16",
        availability_zones: ["us-east-1a", "us-east-1b"]
      })
      
      expect(component).to be_a(ComponentReference)
      expect(component.type).to eq('secure_vpc')
      expect(component.resources[:vpc]).to be_present
      expect(component.resources[:flow_logs]).to be_present
      expect(component.security_features).to include("VPC Flow Logs")
    end
    
    it "validates required attributes" do
      expect {
        secure_vpc(:test, { cidr_block: "invalid" })
      }.to raise_error(Dry::Struct::Error)
    end
  end
end
```

## File Organization

Components follow the same resource-per-directory pattern:

```
lib/pangea/components/
├── CLAUDE.md                     # This documentation
├── base.rb                       # ComponentReference base class
├── types.rb                      # Common component types
├── secure_vpc/                   # Secure VPC component
│   ├── CLAUDE.md                # Implementation docs
│   ├── README.md                # Usage guide
│   ├── component.rb             # Component implementation
│   ├── types.rb                 # Component-specific types
│   └── examples.rb              # Usage examples
├── public_private_subnets/       # Subnet pair component
│   ├── CLAUDE.md
│   ├── README.md
│   ├── component.rb
│   └── types.rb
└── ... (other components follow same pattern)
```

This component system provides the perfect middle ground between individual resources and complete architectures, enabling teams to build reusable infrastructure patterns with complete type safety and consistent best practices.