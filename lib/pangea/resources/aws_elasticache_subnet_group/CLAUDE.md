# AWS ElastiCache Subnet Group Implementation

## Overview

The `aws_elasticache_subnet_group` resource provides a type-safe interface for managing AWS ElastiCache Subnet Groups, which define VPC subnet placement for ElastiCache clusters with comprehensive validation and Multi-AZ support.

## Architecture

### Type System

The implementation uses `ElastiCacheSubnetGroupAttributes` dry-struct for validation:

```ruby
class ElastiCacheSubnetGroupAttributes < Dry::Struct
  attribute :name, Types::String
  attribute? :description, Types::String.optional
  attribute :subnet_ids, Types::Array.of(Types::String).constrained(min_size: 1)
  attribute :tags, Types::AwsTags.default({})
end
```

### Validation Strategy

Comprehensive validation ensures AWS compatibility and best practices:

#### Name Validation
```ruby
unless attrs.name.match?(/\A[a-z0-9\-]+\z/)
  raise Dry::Struct::Error, "Subnet group name must contain only lowercase letters, numbers, and hyphens"
end
```

#### Subnet ID Format Validation
```ruby
attrs.subnet_ids.each do |subnet_id|
  unless subnet_id.match?(/\Asubnet-[a-f0-9]{8,17}\z/)
    raise Dry::Struct::Error, "Invalid subnet ID format: #{subnet_id}"
  end
end
```

#### Multi-AZ Considerations
```ruby
def supports_multi_az?
  subnet_count >= 2
end

def is_single_az?
  subnet_count == 1
end
```

## Key Features

### 1. Subnet Group Naming

Enforces AWS naming requirements:
- Lowercase letters, numbers, and hyphens only
- Cannot start or end with hyphen
- 1-255 character length
- Unique per region per account

### 2. Subnet Validation

Validates subnet configuration:
- Minimum 1 subnet required
- Maximum 20 subnets supported
- Subnet ID format validation
- All subnets must be in same VPC (enforced by AWS)

### 3. Multi-AZ Assessment

Automatic Multi-AZ capability detection:

```ruby
def supports_multi_az?
  subnet_count >= 2
end
```

Enables informed deployment decisions for high availability.

### 4. Configuration Warnings

Built-in configuration analysis:

```ruby
def validate_configuration
  errors = []
  
  if is_single_az?
    errors << "Single subnet limits cluster to single-AZ deployment"
  end
  
  if subnet_count > 20
    errors << "Maximum of 20 subnets supported per subnet group"
  end
  
  errors
end
```

## Implementation Patterns

### 1. Resource Function Structure

Follows Pangea's standard pattern with subnet-specific considerations:

```ruby
def aws_elasticache_subnet_group(name, attributes = {})
  # 1. Validate attributes
  subnet_group_attrs = ElastiCacheSubnetGroupAttributes.new(attributes)
  
  # 2. Generate terraform resource
  resource(:aws_elasticache_subnet_group, name) do
    name subnet_group_attrs.name
    subnet_ids subnet_group_attrs.subnet_ids
    description subnet_group_attrs.description if subnet_group_attrs.description
  end
  
  # 3. Return ResourceReference
  ResourceReference.new(...)
end
```

### 2. Default Description Generation

Automatic description generation when not provided:

```ruby
unless attrs.description
  attrs = attrs.copy_with(description: "ElastiCache subnet group for #{attrs.name}")
end
```

### 3. Cost Transparency

Clear communication of cost implications:

```ruby
def has_cost_implications?
  false
end

def estimated_monthly_cost
  "$0.00/month (subnet groups are free)"
end
```

## Configuration Helpers

### Pre-defined Configurations

`ElastiCacheSubnetGroupConfigs` module provides common patterns:

```ruby
module ElastiCacheSubnetGroupConfigs
  def self.multi_az(name, subnet_ids, description: nil)
    {
      name: name,
      subnet_ids: subnet_ids,
      description: description || "Multi-AZ subnet group for #{name}"
    }
  end
  
  def self.private_subnets(name, private_subnet_ids)
    {
      name: "#{name}-private",
      subnet_ids: private_subnet_ids,
      description: "Private subnet group for #{name} ElastiCache clusters"
    }
  end
end
```

## Resource Outputs

Comprehensive outputs for integration with other resources:

```ruby
outputs: {
  id: "${aws_elasticache_subnet_group.#{name}.id}",
  name: "${aws_elasticache_subnet_group.#{name}.name}",
  arn: "${aws_elasticache_subnet_group.#{name}.arn}",
  vpc_id: "${aws_elasticache_subnet_group.#{name}.vpc_id}",
  subnet_ids: "${aws_elasticache_subnet_group.#{name}.subnet_ids}"
}
```

## Computed Properties

Rich metadata for deployment decisions:

```ruby
computed_properties: {
  subnet_count: subnet_group_attrs.subnet_count,
  supports_multi_az: subnet_group_attrs.supports_multi_az?,
  is_single_az: subnet_group_attrs.is_single_az?,
  configuration_warnings: subnet_group_attrs.validate_configuration,
  estimated_monthly_cost: subnet_group_attrs.estimated_monthly_cost
}
```

## Integration Patterns

### 1. VPC Integration

Subnet groups bridge VPC subnets and ElastiCache clusters:

```ruby
# VPC subnet references
subnet_ids = [
  private_subnet_a.id,
  private_subnet_b.id,
  private_subnet_c.id
]

# Subnet group creation
cache_subnets = aws_elasticache_subnet_group(:cache_subnets, {
  name: "app-cache-subnets",
  subnet_ids: subnet_ids
})
```

### 2. ElastiCache Cluster Integration

Direct integration with cluster resources:

```ruby
cache_cluster = aws_elasticache_cluster(:redis, {
  cluster_id: "app-redis",
  engine: "redis", 
  node_type: "cache.r6g.large",
  subnet_group_name: cache_subnets.name  # Reference subnet group
})
```

### 3. Security Group Coordination

Works with security groups for network access control:

```ruby
# Subnet group defines placement
cache_subnets = aws_elasticache_subnet_group(:subnets, {...})

# Security group defines access
cache_sg = aws_security_group(:cache_sg, {...})

# Both used in cluster
cluster = aws_elasticache_cluster(:cluster, {
  subnet_group_name: cache_subnets.name,
  security_group_ids: [cache_sg.id]
})
```

## Best Practices Encoded

### 1. Security Guidance
- Validates subnet configuration for private placement
- Encourages private subnet usage through naming conventions

### 2. High Availability Support
- Multi-AZ detection and recommendations
- Configuration warning system

### 3. Naming Conventions
- Enforces AWS naming requirements
- Provides consistent naming patterns through helpers

## AWS Service Integration

### ElastiCache Service
- Defines subnet placement for clusters
- Enables VPC-based ElastiCache deployments
- Supports both Redis and Memcached engines

### VPC Service
- Integrates with VPC subnets
- Maintains VPC boundary constraints
- Supports Multi-AZ subnet selection

### IAM Integration
- Subnet groups inherit VPC permissions
- No additional IAM configuration required

This implementation provides a foundation for secure, scalable ElastiCache deployments with proper subnet group management and comprehensive validation.