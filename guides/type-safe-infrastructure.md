# Type-Safe Infrastructure: Catching Errors Before Deployment

One of Pangea's most powerful features is its type-safe approach to infrastructure as code. By leveraging Ruby's type system with RBS definitions and dry-struct validation, Pangea catches configuration errors at compile-time and runtime, preventing costly deployment failures and misconfigurations.

## The Problem with Dynamic Configuration

### Traditional HCL Challenges

Terraform's HCL is dynamically typed, leading to runtime errors:

```hcl
# terraform/main.tf
resource "aws_instance" "web" {
  ami           = "ami-12345"
  instance_type = "t3.micro"
  
  # Typo in attribute name - won't be caught until apply
  enable_monitoring = true  # Should be "monitoring"
  
  # Wrong data type - will fail at runtime
  security_groups = "sg-12345"  # Should be a list
  
  # Invalid reference - terraform plan will fail
  vpc_id = aws_vpc.main.vpc_id  # Should be "id", not "vpc_id"
}
```

**Problems:**
- Typos in attribute names aren't caught until deployment
- Incorrect data types cause runtime failures
- Invalid references fail during terraform plan
- No IDE support for autocompletion or validation
- Documentation is separate from code

### Ruby Without Type Safety

Even Ruby without type checking has issues:

```ruby
# Without type safety
resource :aws_instance, :web do
  ami "ami-12345"
  instance_type "t3.micro"
  enable_monitoring true  # Typo - should be "monitoring"
  security_groups "sg-12345"  # Wrong type - should be array
end
```

These errors only surface during Terraform execution, wasting time and potentially affecting production.

## Pangea's Type-Safe Approach

### Three Layers of Type Safety

Pangea provides comprehensive type safety through three layers:

1. **RBS Type Definitions**: Compile-time type checking with IDE support
2. **Dry-Struct Validation**: Runtime type validation and coercion
3. **Resource Function Interfaces**: Consistent, documented API for all resources

### Layer 1: RBS Type Definitions

RBS (Ruby Signature) files define types for every resource function:

```ruby
# sig/pangea/resources/aws_instance.rbs
module Pangea
  module Resources
    module AWS
      def aws_instance: (Symbol name, InstanceAttributes attributes) -> ResourceReference
      
      class InstanceAttributes < BaseAttributes
        attr_accessor ami: String
        attr_accessor instance_type: String
        attr_accessor monitoring: bool?
        attr_accessor security_groups: Array[String]?
        attr_accessor vpc_security_group_ids: Array[String]?
        attr_accessor tags: Hash[String, String]?
      end
    end
  end
end
```

**Benefits:**
- IDE autocompletion and error detection
- Steep type checker validation
- Self-documenting code
- Catch typos before running code

### Layer 2: Dry-Struct Validation

Runtime validation ensures data integrity:

```ruby
# lib/pangea/resources/aws_instance/types.rb
module Pangea
  module Resources
    class AWSInstanceAttributes < Dry::Struct
      transform_keys(&:to_sym)
      
      # Required attributes with validation
      attribute :ami, Types::Strict::String.constrained(
        format: /^ami-[0-9a-f]{8,17}$/
      )
      attribute :instance_type, Types::Strict::String.constrained(
        included_in: %w[t3.nano t3.micro t3.small t3.medium t3.large]
      )
      
      # Optional attributes with defaults
      attribute :monitoring, Types::Bool.optional.default(false)
      attribute :security_groups, Types::Array.of(Types::String).optional
      attribute :vpc_security_group_ids, Types::Array.of(Types::String).optional
      
      # Complex nested validation
      attribute :block_device_mappings, Types::Array.of(BlockDeviceMapping).optional
      
      # Custom validation logic
      def self.validate_security_groups(attrs)
        if attrs[:security_groups] && attrs[:vpc_security_group_ids]
          raise ArgumentError, "Cannot specify both security_groups and vpc_security_group_ids"
        end
        attrs
      end
    end
  end
end
```

### Layer 3: Resource Function Interface

Type-safe functions replace raw DSL blocks:

```ruby
# Type-safe resource function
def aws_instance(name, attributes)
  # 1. Validate input types
  validated_attrs = AWSInstanceAttributes.new(attributes)
  
  # 2. Generate Terraform resource
  resource :aws_instance, name do
    ami validated_attrs.ami
    instance_type validated_attrs.instance_type
    monitoring validated_attrs.monitoring
    
    # 3. Handle optional attributes safely
    security_groups validated_attrs.security_groups if validated_attrs.security_groups
    vpc_security_group_ids validated_attrs.vpc_security_group_ids if validated_attrs.vpc_security_group_ids
    
    # 4. Generate tags with defaults
    tags validated_attrs.tags || {}
  end
  
  # 5. Return typed reference
  ResourceReference.new(
    type: 'aws_instance',
    name: name,
    attributes: validated_attrs
  )
end
```

## Type Safety in Action

### Before: Error-Prone HCL

```hcl
resource "aws_instance" "web" {
  ami                    = "ami-invalid"
  instance_type         = "invalid.type"
  enable_monitoring     = true           # Wrong attribute name
  security_groups       = "sg-12345"     # Wrong type
  availability_zone     = "us-east-1z"   # Invalid AZ
  
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = "20GB"                 # Wrong type
    encrypted   = "yes"                  # Wrong type
  }
}
```

**Result**: Multiple runtime errors, failed deployments, debugging time.

### After: Type-Safe Pangea

```ruby
# This code won't compile/run with errors
template :web_server do
  aws_instance(:web, {
    ami: "ami-0c7217cdde317cfec",           # ✓ Valid AMI format
    instance_type: "t3.micro",             # ✓ Valid instance type
    monitoring: true,                      # ✓ Correct attribute name and type
    vpc_security_group_ids: ["sg-12345"], # ✓ Correct type (array)
    availability_zone: "us-east-1a",      # ✓ Valid AZ
    
    block_device_mappings: [{             # ✓ Properly nested and typed
      device_name: "/dev/sda1",
      ebs: {
        volume_size: 20,                   # ✓ Correct type (integer)
        encrypted: true                    # ✓ Correct type (boolean)
      }
    }]
  })
end
```

**Result**: Errors caught immediately, no deployment failures, confident deployments.

## Advanced Type Safety Features

### 1. Conditional Validation

```ruby
class AWSInstanceAttributes < Dry::Struct
  # Instance type affects available options
  attribute :instance_type, Types::String
  attribute :placement_tenancy, Types::String.optional
  
  # Custom validation based on instance type
  def self.validate_tenancy(attrs)
    if attrs[:placement_tenancy] == 'dedicated' 
      dedicated_types = %w[m5.large m5.xlarge m5.2xlarge]
      unless dedicated_types.include?(attrs[:instance_type])
        raise ArgumentError, "Dedicated tenancy requires larger instance types"
      end
    end
    attrs
  end
end
```

### 2. Resource Reference Validation

```ruby
def aws_instance(name, attributes)
  validated_attrs = AWSInstanceAttributes.new(attributes)
  
  # Validate resource references
  if validated_attrs.subnet_id.is_a?(ResourceReference)
    unless validated_attrs.subnet_id.type == 'aws_subnet'
      raise ArgumentError, "subnet_id must reference an aws_subnet resource"
    end
  end
  
  resource :aws_instance, name do
    # Safe to use validated reference
    subnet_id validated_attrs.subnet_id
  end
end
```

### 3. Environment-Specific Validation

```ruby
class AWSInstanceAttributes < Dry::Struct
  attribute :instance_type, Types::String
  
  def self.validate_production_requirements(attrs, namespace)
    if namespace == 'production'
      # Production instances must be at least t3.small
      small_or_larger = %w[t3.small t3.medium t3.large t3.xlarge]
      unless small_or_larger.include?(attrs[:instance_type])
        raise ArgumentError, "Production requires t3.small or larger instances"
      end
      
      # Production requires monitoring
      unless attrs[:monitoring]
        raise ArgumentError, "Production instances must have monitoring enabled"
      end
    end
    attrs
  end
end
```

### 4. Complex Nested Validation

```ruby
# Load balancer with comprehensive validation
class AWSLoadBalancerAttributes < Dry::Struct
  attribute :load_balancer_type, Types::String.constrained(
    included_in: %w[application network gateway]
  )
  attribute :scheme, Types::String.constrained(
    included_in: %w[internet-facing internal]
  )
  attribute :listeners, Types::Array.of(ListenerConfiguration)
  
  # Validate listener configuration based on LB type
  def self.validate_listeners(attrs)
    if attrs[:load_balancer_type] == 'network'
      attrs[:listeners].each do |listener|
        unless %w[TCP UDP TLS].include?(listener.protocol)
          raise ArgumentError, "Network LB supports TCP, UDP, TLS protocols only"
        end
      end
    elsif attrs[:load_balancer_type] == 'application'
      attrs[:listeners].each do |listener|
        unless %w[HTTP HTTPS].include?(listener.protocol)
          raise ArgumentError, "Application LB supports HTTP, HTTPS protocols only"
        end
      end
    end
    attrs
  end
end

class ListenerConfiguration < Dry::Struct
  attribute :port, Types::Integer.constrained(gteq: 1, lteq: 65535)
  attribute :protocol, Types::String
  attribute :ssl_policy, Types::String.optional
  
  # SSL policy required for HTTPS/TLS
  def self.validate_ssl_requirements(attrs)
    if %w[HTTPS TLS].include?(attrs[:protocol]) && !attrs[:ssl_policy]
      raise ArgumentError, "SSL policy required for #{attrs[:protocol]} listeners"
    end
    attrs
  end
end
```

## IDE Integration and Developer Experience

### VS Code with Ruby LSP

Type definitions enable rich IDE features:

```ruby
# As you type, get autocomplete for:
aws_instance(:web, {
  ami: "ami-123",
  # IDE suggests: instance_type, monitoring, security_groups, etc.
  instance_|  # Cursor here shows completions
})

# Hover over functions to see documentation:
aws_instance  # Shows: aws_instance(name: Symbol, attrs: InstanceAttributes) -> ResourceReference
```

### Steep Type Checking

Run type checking before deployment:

```bash
# Check types across entire codebase
steep check

# Output shows type errors before deployment
lib/infrastructure.rb:15:4: [error] Type mismatch
  Expected: Array[String]
  Actual: String
```

### Runtime Error Messages

When validation fails, get helpful error messages:

```ruby
aws_instance(:web, {
  ami: "invalid-ami-format",
  instance_type: "invalid.type"
})

# Runtime error with clear message:
# ArgumentError: 
#   ami: "invalid-ami-format" does not match format /^ami-[0-9a-f]{8,17}$/
#   instance_type: "invalid.type" is not included in allowed values: [t3.nano, t3.micro, ...]
```

## Type-Safe Resource Composition

### Building Complex Infrastructure

```ruby
template :web_application do
  # 1. Create VPC with validation
  vpc_ref = aws_vpc(:main, {
    cidr_block: "10.0.0.0/16",
    enable_dns_hostnames: true,
    enable_dns_support: true
  })
  
  # 2. Create subnet with validated VPC reference
  subnet_ref = aws_subnet(:public, {
    vpc_id: vpc_ref.id,                    # Type-safe reference
    cidr_block: "10.0.1.0/24",
    availability_zone: "us-east-1a",
    map_public_ip_on_launch: true
  })
  
  # 3. Security group with validated rules
  sg_ref = aws_security_group(:web, {
    name_prefix: "web-",
    vpc_id: vpc_ref.id,
    
    ingress_rules: [
      {
        from_port: 80,
        to_port: 80,
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"]
      },
      {
        from_port: 443,
        to_port: 443,
        protocol: "tcp", 
        cidr_blocks: ["0.0.0.0/0"]
      }
    ]
  })
  
  # 4. Instance with all validated references
  aws_instance(:web, {
    ami: "ami-0c7217cdde317cfec",
    instance_type: "t3.micro",
    subnet_id: subnet_ref.id,              # Type-safe reference
    vpc_security_group_ids: [sg_ref.id],   # Type-safe reference array
    monitoring: true,
    
    tags: {
      Name: "WebServer",
      Environment: "production"
    }
  })
end
```

### Component-Level Type Safety

```ruby
# Component with validated configuration
def secure_web_application(name, config)
  # Validate component configuration
  validated_config = SecureWebAppConfig.new(config)
  
  # Create components with type safety
  vpc_component = secure_vpc(:"#{name}_vpc", {
    cidr_block: validated_config.vpc_cidr,
    enable_flow_logs: validated_config.enable_audit_logging
  })
  
  web_component = auto_scaling_web_servers(:"#{name}_web", {
    vpc_ref: vpc_component.vpc,
    instance_type: validated_config.instance_type,
    min_size: validated_config.min_instances,
    max_size: validated_config.max_instances
  })
  
  database_component = managed_database(:"#{name}_db", {
    vpc_ref: vpc_component.vpc,
    engine: validated_config.database_engine,
    instance_class: validated_config.database_instance_class,
    backup_retention_days: validated_config.backup_retention
  })
  
  # Return typed component reference
  ComponentReference.new(
    name: name,
    type: 'secure_web_application',
    components: {
      vpc: vpc_component,
      web: web_component,
      database: database_component
    }
  )
end

class SecureWebAppConfig < Dry::Struct
  attribute :vpc_cidr, Types::String.constrained(
    format: /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$/
  )
  attribute :instance_type, Types::String.constrained(
    included_in: %w[t3.small t3.medium t3.large m5.large m5.xlarge]
  )
  attribute :min_instances, Types::Integer.constrained(gteq: 1, lteq: 10)
  attribute :max_instances, Types::Integer.constrained(gteq: 1, lteq: 50)
  attribute :database_engine, Types::String.constrained(
    included_in: %w[mysql postgres]
  )
  attribute :database_instance_class, Types::String
  attribute :backup_retention, Types::Integer.constrained(gteq: 1, lteq: 35)
  
  # Custom validation: max must be >= min
  def self.validate_scaling_bounds(attrs)
    if attrs[:max_instances] < attrs[:min_instances]
      raise ArgumentError, "max_instances must be >= min_instances"
    end
    attrs
  end
end
```

## Testing Type-Safe Infrastructure

### Unit Tests for Validation

```ruby
RSpec.describe AWSInstanceAttributes do
  describe "AMI validation" do
    it "accepts valid AMI IDs" do
      expect {
        AWSInstanceAttributes.new(
          ami: "ami-0c7217cdde317cfec",
          instance_type: "t3.micro"
        )
      }.not_to raise_error
    end
    
    it "rejects invalid AMI format" do
      expect {
        AWSInstanceAttributes.new(
          ami: "invalid-ami",
          instance_type: "t3.micro"
        )
      }.to raise_error(Dry::Struct::Error, /does not match format/)
    end
  end
  
  describe "instance type validation" do
    it "accepts valid instance types" do
      %w[t3.nano t3.micro t3.small].each do |type|
        expect {
          AWSInstanceAttributes.new(
            ami: "ami-123",
            instance_type: type
          )
        }.not_to raise_error
      end
    end
    
    it "rejects invalid instance types" do
      expect {
        AWSInstanceAttributes.new(
          ami: "ami-123",
          instance_type: "invalid.type"
        )
      }.to raise_error(Dry::Struct::Error, /not included in/)
    end
  end
end
```

### Integration Tests with Type Safety

```ruby
RSpec.describe "web application deployment" do
  it "creates valid Terraform configuration" do
    synthesizer = TerraformSynthesizer.new
    
    synthesizer.instance_eval do
      aws_instance(:web, {
        ami: "ami-0c7217cdde317cfec",
        instance_type: "t3.micro",
        monitoring: true,
        vpc_security_group_ids: ["sg-12345"]
      })
    end
    
    result = synthesizer.synthesis
    
    # Validate generated Terraform structure
    expect(result["resource"]["aws_instance"]["web"]).to include(
      "ami" => "ami-0c7217cdde317cfec",
      "instance_type" => "t3.micro",
      "monitoring" => true,
      "vpc_security_group_ids" => ["sg-12345"]
    )
  end
end
```

## Migration from Untyped Infrastructure

### Step 1: Add Basic Type Definitions

```ruby
# Before: Raw HCL-style resource blocks
template :legacy do
  resource :aws_instance, :web do
    ami "ami-123"
    instance_type "t3.micro"
    # Many more attributes...
  end
end

# After: Type-safe resource functions
template :modernized do
  aws_instance(:web, {
    ami: "ami-0c7217cdde317cfec",
    instance_type: "t3.micro"
  })
end
```

### Step 2: Gradual Type Addition

```ruby
# Start with basic types, add complexity over time
class BasicInstanceAttributes < Dry::Struct
  attribute :ami, Types::String                    # Start simple
  attribute :instance_type, Types::String
end

# Later, add validation
class ValidatedInstanceAttributes < Dry::Struct
  attribute :ami, Types::String.constrained(      # Add constraints
    format: /^ami-[0-9a-f]{8,17}$/
  )
  attribute :instance_type, Types::String.constrained(
    included_in: %w[t3.nano t3.micro t3.small t3.medium]
  )
end
```

### Step 3: Comprehensive Validation

```ruby
# Final: Full validation with business logic
class ProductionInstanceAttributes < Dry::Struct
  # All the validation from earlier examples
  # Plus environment-specific rules
  # Plus security requirements
  # Plus cost optimization checks
end
```

## Best Practices

### 1. Progressive Type Safety

Start simple and add complexity:

```ruby
# Phase 1: Basic types
attribute :instance_type, Types::String

# Phase 2: Add constraints  
attribute :instance_type, Types::String.constrained(
  included_in: %w[t3.micro t3.small t3.medium]
)

# Phase 3: Add business logic
def self.validate_cost_optimization(attrs)
  if attrs[:instance_type].start_with?('t3.') && !attrs[:credit_specification]
    # Suggest CPU credit optimization
  end
end
```

### 2. Clear Error Messages

```ruby
attribute :backup_retention_period, Types::Integer.constrained(
  gteq: 1, 
  lteq: 35
).meta(
  description: "Database backup retention in days (1-35)",
  example: 7
)
```

### 3. Documentation in Types

```ruby
class DatabaseAttributes < Dry::Struct
  # Document each attribute clearly
  attribute :engine, Types::String.constrained(
    included_in: %w[mysql postgres]
  ).meta(
    description: "Database engine type",
    example: "postgres"
  )
  
  attribute :instance_class, Types::String.meta(
    description: "RDS instance class (e.g., db.t3.micro)",
    validation: "Must be a valid RDS instance class"
  )
end
```

## Summary

Pangea's type-safe approach provides:

1. **Compile-Time Safety**: RBS definitions catch errors before runtime
2. **Runtime Validation**: Dry-struct ensures data integrity
3. **IDE Integration**: Rich autocomplete and error detection
4. **Self-Documenting Code**: Types serve as documentation
5. **Confident Deployments**: Eliminate configuration errors

This comprehensive type safety system transforms infrastructure management from error-prone deployments to confident, validated infrastructure deployment.

Next, explore [Migration from Terraform](migration-from-terraform.md) to learn how to migrate existing Terraform codebases to Pangea's type-safe approach.