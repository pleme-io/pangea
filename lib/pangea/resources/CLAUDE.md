# Pangea Resource Abstraction System

## Overview

Pangea's resource abstraction system provides type-safe, pure function interfaces for infrastructure resources. Instead of using raw DSL blocks, developers can use strongly-typed functions that provide better IDE support, compile-time type checking via RBS, and runtime validation through dry-* libraries.

## Architecture

### Traditional DSL (Before)
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

### Resource Function (After)
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

## Benefits

### 1. Type Safety
- **RBS Definitions**: Compile-time type checking in IDEs and with Steep
- **Runtime Validation**: dry-struct enforces attribute types and constraints
- **IDE Support**: Better autocomplete, parameter hints, and error detection

### 2. Developer Experience
- **Pure Functions**: No side effects, easier to test and reason about
- **Consistent Interface**: All resources follow same function signature pattern
- **Documentation**: Types serve as living documentation for resource attributes

### 3. Abstraction Power
- **Default Values**: Functions can provide sensible defaults for optional attributes
- **Computed Values**: Functions can derive attributes from other attributes
- **Validation**: Custom validation logic beyond basic types

## Implementation Strategy

### 1. Resource Type Definitions

Each AWS resource gets a corresponding dry-struct definition:

```ruby
# lib/pangea/resources/aws/types/vpc.rb
module Pangea
  module Resources
    module AWS
      module Types
        class VpcAttributes < Dry::Struct
          attribute :cidr_block, Types::String
          attribute :enable_dns_hostnames, Types::Bool.default(true)
          attribute :enable_dns_support, Types::Bool.default(true)
          attribute :instance_tenancy, Types::String.default("default")
          attribute :tags, Types::Hash.default({})
          
          # Custom validation
          def self.new(attributes)
            # Validate CIDR block format
            if attributes[:cidr_block] && !valid_cidr?(attributes[:cidr_block])
              raise Dry::Struct::Error, "Invalid CIDR block format"
            end
            
            super
          end
          
          private
          
          def self.valid_cidr?(cidr)
            # CIDR validation logic
            cidr.match?(/\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/)
          end
        end
      end
    end
  end
end
```

### 2. Resource Functions

Pure functions that accept a name and typed attributes:

```ruby
# lib/pangea/resources/aws/vpc.rb
module Pangea
  module Resources
    module AWS
      def aws_vpc(name, attributes = {})
        # Validate and coerce attributes
        vpc_attrs = Types::VpcAttributes.new(attributes)
        
        # Generate Terraform resource block
        resource(:aws_vpc, name) do
          cidr_block vpc_attrs.cidr_block
          enable_dns_hostnames vpc_attrs.enable_dns_hostnames
          enable_dns_support vpc_attrs.enable_dns_support
          instance_tenancy vpc_attrs.instance_tenancy
          
          if vpc_attrs.tags.any?
            tags do
              vpc_attrs.tags.each do |key, value|
                send(key, value)
              end
            end
          end
        end
      end
    end
  end
end
```

### 3. RBS Type Definitions

```ruby
# sig/pangea/resources/aws.rbs
module Pangea
  module Resources
    module AWS
      type vpc_attributes = {
        cidr_block: String,
        enable_dns_hostnames: bool,
        enable_dns_support: bool,
        instance_tenancy: String,
        tags: Hash[Symbol, String]
      }
      
      def aws_vpc: (Symbol, vpc_attributes) -> void
    end
  end
end
```

## Usage Patterns

### 1. Simple Resource Creation
```ruby
template :networking do
  provider :aws do
    region "us-east-1"
  end
  
  # Type-safe VPC creation
  aws_vpc(:main, {
    cidr_block: "10.0.0.0/16",
    tags: { Name: "main-vpc", Environment: "production" }
  })
  
  # Type-safe subnet creation
  aws_subnet(:public_a, {
    vpc_id: ref(:aws_vpc, :main, :id),
    cidr_block: "10.0.1.0/24",
    availability_zone: "us-east-1a",
    map_public_ip_on_launch: true,
    tags: { Name: "public-subnet-a", Type: "public" }
  })
end
```

### 2. Resource with Computed Attributes
```ruby
def aws_subnet(name, attributes = {})
  subnet_attrs = Types::SubnetAttributes.new(attributes)
  
  # Computed values
  computed_tags = {
    Name: "#{name}-subnet",
    Type: subnet_attrs.map_public_ip_on_launch ? "public" : "private"
  }.merge(subnet_attrs.tags)
  
  resource(:aws_subnet, name) do
    vpc_id subnet_attrs.vpc_id
    cidr_block subnet_attrs.cidr_block
    availability_zone subnet_attrs.availability_zone
    map_public_ip_on_launch subnet_attrs.map_public_ip_on_launch
    
    tags do
      computed_tags.each do |key, value|
        send(key, value)
      end
    end
  end
end
```

### 3. Resource with Default Patterns
```ruby
def aws_security_group(name, attributes = {})
  sg_attrs = Types::SecurityGroupAttributes.new(attributes)
  
  # Default ingress/egress rules if none provided
  ingress_rules = sg_attrs.ingress_rules.any? ? sg_attrs.ingress_rules : default_ingress_rules
  egress_rules = sg_attrs.egress_rules.any? ? sg_attrs.egress_rules : default_egress_rules
  
  resource(:aws_security_group, name) do
    name_prefix sg_attrs.name_prefix || "#{name}-sg"
    vpc_id sg_attrs.vpc_id
    
    ingress_rules.each do |rule|
      ingress do
        from_port rule[:from_port]
        to_port rule[:to_port]
        protocol rule[:protocol]
        cidr_blocks rule[:cidr_blocks]
      end
    end
    
    egress_rules.each do |rule|
      egress do
        from_port rule[:from_port]
        to_port rule[:to_port]
        protocol rule[:protocol]
        cidr_blocks rule[:cidr_blocks]
      end
    end
  end
end
```

## File Organization

Pangea uses a **resource-per-directory** organization strategy where each AWS resource type gets its own dedicated directory with comprehensive documentation and modular implementation.

### Directory Structure

```
lib/pangea/resources/
├── CLAUDE.md                    # This documentation (resource system overview)
├── base.rb                      # Base resource functionality
├── types.rb                     # Common types and utilities
├── reference.rb                 # ResourceReference implementation
├── composition.rb               # High-level composition functions
├── aws_vpc/                     # VPC Resource Directory
│   ├── CLAUDE.md               # VPC-specific implementation documentation
│   ├── README.md               # User-facing VPC usage guide
│   ├── resource.rb             # VPC resource function implementation
│   ├── types.rb                # VPC-specific dry-struct types
│   ├── computed_attributes.rb  # VPC computed properties
│   └── examples.rb             # VPC usage examples
├── aws_subnet/                  # Subnet Resource Directory
│   ├── CLAUDE.md               # Subnet-specific implementation documentation
│   ├── README.md               # User-facing Subnet usage guide
│   ├── resource.rb             # Subnet resource function implementation
│   ├── types.rb                # Subnet-specific dry-struct types
│   ├── computed_attributes.rb  # Subnet computed properties
│   └── examples.rb             # Subnet usage examples
├── aws_security_group/          # Security Group Resource Directory
│   ├── CLAUDE.md               # Security Group implementation docs
│   ├── README.md               # User-facing Security Group guide
│   ├── resource.rb             # Security Group function implementation
│   ├── types.rb                # Security Group dry-struct types
│   ├── computed_attributes.rb  # Security Group computed properties
│   └── examples.rb             # Security Group usage examples
└── ... (other AWS resources follow the same pattern)
```

### Resource Directory Pattern

Each resource follows a consistent directory structure:

#### Required Files:
- **`resource.rb`**: Contains the main resource function (e.g., `aws_vpc`, `aws_subnet`)
- **`types.rb`**: dry-struct type definitions for the resource
- **`CLAUDE.md`**: Implementation documentation for developers
- **`README.md`**: User-facing usage documentation

#### Optional Files:
- **`computed_attributes.rb`**: Computed properties specific to this resource
- **`examples.rb`**: Comprehensive usage examples
- **`validations.rb`**: Custom validation logic beyond type checking

### Benefits of Resource-Per-Directory:

1. **Focused Development**: Each resource is self-contained with all related code
2. **Clear Documentation**: Resource-specific docs with implementation details
3. **Modular Loading**: Resources can be loaded independently
4. **Easy Discovery**: Developers can quickly find all files related to a resource
5. **Scalable Organization**: New resources don't clutter existing directories
6. **Team Ownership**: Teams can own specific resource directories
7. **Testing Isolation**: Each resource can have its own test suite

## Resource Loading and Integration

### Loading Resources
Resources are loaded through the main AWS module:

```ruby
# In application code
require 'pangea/resources/aws_resources'

# This automatically loads all implemented AWS resources:
# - aws_vpc (VPC management)
# - aws_subnet (Subnet management) 
# - aws_security_group (Security group management)
# - More resources as they are implemented...
```

### Individual Resource Loading
For selective loading, individual resources can be required:

```ruby
require 'pangea/resources/aws_vpc/resource'      # Just VPC functionality
require 'pangea/resources/aws_subnet/resource'   # Just subnet functionality
```

### Integration with Templates

Resources are automatically available within template blocks:

```ruby
template :infrastructure do
  include Pangea::Resources::AWS  # Makes aws_* functions available
  
  provider :aws do
    region "us-east-1"
  end
  
  # Type-safe resource creation using resource-per-directory implementations
  vpc = aws_vpc(:main, cidr_block: "10.0.0.0/16")
  subnet = aws_subnet(:public, {
    vpc_id: vpc.id, 
    cidr_block: "10.0.1.0/24",
    availability_zone: "us-east-1a"
  })
  
  sg = aws_security_group(:web, {
    name_prefix: "web-",
    vpc_id: vpc.id,
    description: "Web server security group"
  })
  
  instance = aws_instance(:web, {
    ami: "ami-12345678",
    instance_type: "t3.micro",
    subnet_id: subnet.id,
    vpc_security_group_ids: [sg.id]
  })
end
```

## Migration Strategy

The resource system is being migrated from a monolithic `aws.rb` file to the resource-per-directory structure:

### Current Status
✅ **Migrated Resources**:
- `aws_vpc` - VPC management with comprehensive validation
- `aws_subnet` - Subnet creation and management
- `aws_security_group` - Security group with rule validation

🔄 **Pending Migration**:
- `aws_instance` - EC2 instance management
- `aws_internet_gateway` - Internet gateway connectivity
- `aws_route_table` - Custom routing configuration
- `aws_nat_gateway` - NAT gateway for private subnets
- `aws_launch_template` - Launch template for Auto Scaling
- `aws_autoscaling_group` - Auto Scaling group management
- `aws_lb_target_group` - Load balancer target groups
- `aws_autoscaling_attachment` - ASG to target group attachment
- `aws_autoscaling_policy` - Auto Scaling policies
- `aws_cloudwatch_metric_alarm` - CloudWatch alarms

### Migration Process
1. **Create Resource Directory**: `mkdir lib/pangea/resources/aws_[resource_name]`
2. **Extract Resource Function**: Move from `aws.rb` to `resource.rb`
3. **Create Types Definition**: Extract and enhance type validation in `types.rb`
4. **Write Documentation**: Create both `CLAUDE.md` and `README.md`
5. **Update Main Loader**: Add require statement to `aws_resources.rb`
6. **Update Tests**: Ensure tests use new structure
7. **Verify Integration**: Test with terraform-synthesizer

## Development Workflow

### 1. Adding New Resources (New Structure)

1. Create resource directory: `lib/pangea/resources/aws_[resource_name]/`
2. Implement required files:
   - `resource.rb`: Main resource function implementation
   - `types.rb`: dry-struct type definitions with validation
   - `CLAUDE.md`: Implementation documentation for developers
   - `README.md`: User-facing usage documentation
3. Add resource loading to `aws_resources.rb`
4. Write comprehensive tests with terraform-synthesizer integration
5. Add examples and integration patterns

### 2. Type Checking Setup

```bash
# Install Steep for type checking
gem install steep

# Create Steepfile (if not exists)
steep init

# Run type checking
steep check
```

### 3. Testing Resources

```ruby
RSpec.describe Pangea::Resources::AWS do
  describe "#aws_vpc" do
    it "creates VPC with required attributes" do
      result = aws_vpc(:test, cidr_block: "10.0.0.0/16")
      expect(result).to be_a(ResourceDefinition)
    end
    
    it "validates CIDR block format" do
      expect {
        aws_vpc(:test, cidr_block: "invalid")
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "applies default values" do
      result = aws_vpc(:test, cidr_block: "10.0.0.0/16")
      expect(result.attributes[:enable_dns_hostnames]).to be true
    end
  end
end
```

## Benefits Summary

1. **Type Safety**: Compile-time and runtime validation
2. **Developer Experience**: Better IDE support and error messages
3. **Consistency**: Unified interface across all resources
4. **Testability**: Pure functions are easier to test
5. **Documentation**: Types serve as living documentation
6. **Abstraction**: Can provide higher-level patterns and defaults
7. **Evolution**: Easy to extend and modify resource interfaces

This abstraction system maintains the power of the Ruby DSL while providing the safety and developer experience of strongly-typed interfaces.

## Resource Return Values and Composition

### ResourceReference Objects

All resource functions return `ResourceReference` objects that provide:

1. **Terraform References**: Access to all terraform attributes
2. **Computed Properties**: Derived attributes not available in raw terraform  
3. **Type Safety**: Runtime validation and RBS compile-time checking
4. **Rich Metadata**: Original attributes, outputs, and resource type information

```ruby
# Resource function returns ResourceReference
vpc_ref = aws_vpc(:main, {
  cidr_block: "10.0.0.0/16",
  enable_dns_hostnames: true,
  tags: { Name: "main-vpc" }
})

# Access terraform references
vpc_id = vpc_ref.id                    # "${aws_vpc.main.id}"
vpc_cidr = vpc_ref.cidr_block         # "${aws_vpc.main.cidr_block}"

# Access computed properties
is_private = vpc_ref.is_private_cidr?        # Computed: true
subnet_capacity = vpc_ref.estimated_subnet_capacity  # Computed: 256

# Multiple access patterns
vpc_ref.ref(:default_security_group_id)     # Method call
vpc_ref[:default_security_group_id]         # Array-style access
vpc_ref.default_security_group_id          # Direct property access
```

### Resource Chaining and Composition

Resource references enable natural chaining and composition:

```ruby
# Create VPC
vpc_ref = aws_vpc(:main, { cidr_block: "10.0.0.0/16" })

# Create subnet using VPC reference
subnet_ref = aws_subnet(:public, {
  vpc_id: vpc_ref.id,                 # Use returned reference
  cidr_block: "10.0.1.0/24",
  availability_zone: "us-east-1a",
  map_public_ip_on_launch: true
})

# Create instance using subnet reference
instance_ref = aws_instance(:web, {
  ami: "ami-12345678",
  instance_type: "t3.micro",
  subnet_id: subnet_ref.id,           # Chain references
  tags: { 
    Name: "web-server",
    SubnetType: subnet_ref.subnet_type  # Use computed property
  }
})

# Access nested computed properties
puts "Instance in #{instance_ref.compute_family} family"  # "t3"
puts "Subnet has #{subnet_ref.ip_capacity} available IPs"  # 251
```

### Composition Functions

High-level composition functions create multiple related resources:

```ruby
# Create VPC with subnets across multiple AZs
network = vpc_with_subnets(:myapp,
  vpc_cidr: "10.0.0.0/16",
  availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
  attributes: {
    vpc_tags: { Environment: "production" },
    public_subnet_tags: { Tier: "web" },
    private_subnet_tags: { Tier: "app" }
  }
)

# Access composite results
puts "Created VPC: #{network.vpc.id}"
puts "Public subnets: #{network.public_subnet_ids}"
puts "Private subnets: #{network.private_subnet_ids}"
puts "Availability zones: #{network.availability_zone_count}"

# Use in other resources
web_server = web_server(:frontend,
  subnet_ref: network.public_subnets.first,
  attributes: { instance_type: "t3.small" }
)
```

### Computed Properties by Resource Type

Each resource type provides specific computed properties:

#### VPC Computed Properties
```ruby
vpc_ref.is_private_cidr?              # RFC1918 validation
vpc_ref.estimated_subnet_capacity     # Subnet planning
vpc_ref.default_security_group_id     # AWS defaults
vpc_ref.main_route_table_id           # Default routing
```

#### Subnet Computed Properties
```ruby
subnet_ref.is_public?                 # Public IP assignment check
subnet_ref.subnet_type               # "public" or "private"
subnet_ref.ip_capacity               # Available IP addresses (total - 5)
```

#### Instance Computed Properties
```ruby
instance_ref.compute_family          # "t3", "c5", "r5", etc.
instance_ref.compute_size            # "micro", "small", "large", etc.
instance_ref.will_have_public_ip?    # Public IP prediction
```

### Benefits of Resource Return Values

1. **Reference Chaining**: Natural resource dependencies without manual interpolation
2. **Type Safety**: All references validated at runtime and compile-time
3. **Computed Intelligence**: Access to derived properties not in terraform
4. **Composition Patterns**: Build higher-level abstractions easily  
5. **Rich Outputs**: Use computed properties in template outputs
6. **IDE Support**: Full autocomplete and type checking for all properties
7. **Resource Metadata**: Inspect original attributes and terraform outputs

### Integration with Templates

Resource functions and return values integrate seamlessly with templates:

```ruby
template :infrastructure do
  include Pangea::Resources::AWS         # Enable resource functions
  include Pangea::Resources::Composition # Enable composition helpers
  
  # Create resources with return values
  vpc_ref = aws_vpc(:main, { cidr_block: "10.0.0.0/16" })
  subnet_ref = aws_subnet(:public, { vpc_id: vpc_ref.id, ... })
  
  # Use in outputs with computed properties
  output :network_info do
    value {
      vpc_id: vpc_ref.id,
      is_private: vpc_ref.is_private_cidr?,
      subnet_capacity: subnet_ref.ip_capacity,
      subnet_type: subnet_ref.subnet_type
    }
    description "Network information with computed properties"
  end
end
```

This approach transforms infrastructure code from procedural terraform generation into object-oriented resource composition with rich return values and type safety.