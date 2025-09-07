# AWS ElastiCache Cluster Implementation

## Overview

The `aws_elasticache_cluster` resource provides a type-safe interface for managing AWS ElastiCache clusters supporting both Redis and Memcached engines with comprehensive validation and engine-specific optimizations.

## Architecture

### Type System

The implementation uses `ElastiCacheClusterAttributes` dry-struct for validation:

```ruby
class ElastiCacheClusterAttributes < Dry::Struct
  attribute :cluster_id, Types::String
  attribute :engine, Types::String.enum("redis", "memcached")
  attribute :node_type, Types::String.enum(/* comprehensive node type list */)
  # ... additional attributes
end
```

### Engine-Specific Validation

The resource implements sophisticated validation logic that enforces engine-specific constraints:

#### Redis Constraints
- Single node clusters (replication groups handle scaling)
- Auth tokens require transit encryption
- At-rest encryption requires engine version 3.2.6+
- Snapshot features only available for Redis

#### Memcached Constraints
- Multi-node cluster support (1-40 nodes)
- No encryption capabilities
- No backup/snapshot features
- No authentication support

### Node Type Support

Comprehensive support for AWS ElastiCache node types across all families:

- **Burstable Performance**: T4g, T3 instances for variable workloads
- **General Purpose**: M6g, M5 instances for balanced compute/memory
- **Memory Optimized**: R6g, R5 instances for memory-intensive applications

## Key Features

### 1. Multi-Engine Architecture

```ruby
def is_redis?
  engine == "redis"
end

def is_memcached?
  engine == "memcached"
end
```

Engine detection enables conditional feature availability and validation.

### 2. Encryption Support

Redis-specific encryption with comprehensive validation:

```ruby
# Auth token requires transit encryption
if attrs.auth_token && !attrs.transit_encryption_enabled
  raise Dry::Struct::Error, "Auth token requires transit_encryption_enabled=true"
end
```

### 3. Version Compatibility

Engine version validation for encryption features:

```ruby
def engine_supports_encryption?
  return false unless is_redis?
  return true unless engine_version
  
  version_parts = engine_version.split('.').map(&:to_i)
  major, minor, patch = version_parts[0], version_parts[1], version_parts[2] || 0
  
  major > 3 || (major == 3 && minor > 2) || (major == 3 && minor == 2 && patch >= 6)
end
```

### 4. Multi-AZ Configuration

Supports both single-AZ and multi-AZ deployments with appropriate validation:

```ruby
# Multi-AZ requires multiple nodes for Memcached
if attrs.engine == "memcached" && attrs.preferred_availability_zones.any? && attrs.num_cache_nodes < 2
  raise Dry::Struct::Error, "Multi-AZ deployment requires at least 2 cache nodes for Memcached"
end
```

## Implementation Patterns

### 1. Resource Function Structure

The function follows Pangea's standard resource pattern:

```ruby
def aws_elasticache_cluster(name, attributes = {})
  # 1. Validate attributes
  cluster_attrs = ElastiCacheClusterAttributes.new(attributes)
  
  # 2. Generate terraform resource
  resource(:aws_elasticache_cluster, name) do
    # Conditional configuration based on engine
  end
  
  # 3. Return ResourceReference
  ResourceReference.new(...)
end
```

### 2. Conditional Configuration

Engine-specific terraform resource configuration:

```ruby
# Redis-specific configuration
if cluster_attrs.is_redis?
  snapshot_retention_limit cluster_attrs.snapshot_retention_limit if cluster_attrs.snapshot_retention_limit > 0
  at_rest_encryption_enabled cluster_attrs.at_rest_encryption_enabled if cluster_attrs.at_rest_encryption_enabled
end
```

### 3. Default Value Assignment

Dynamic default value assignment based on engine:

```ruby
# Port default for Redis
attrs = attrs.copy_with(port: attrs.port || 6379)
```

## Configuration Helpers

### Pre-defined Configurations

`ElastiCacheConfigs` module provides common configurations:

```ruby
module ElastiCacheConfigs
  def self.redis(version: "7.0", node_type: "cache.t4g.micro")
    {
      engine: "redis",
      engine_version: version,
      node_type: node_type,
      at_rest_encryption_enabled: true,
      transit_encryption_enabled: true
    }
  end
end
```

### Cost Estimation

Built-in cost estimation based on node type and configuration:

```ruby
def estimated_monthly_cost
  hourly_rate = case node_type
               when /t4g.micro/ then 0.032
               when /r6g.large/ then 0.101
               # ... additional mappings
               end
               
  total_cost = hourly_rate * 730 * num_cache_nodes
  "~$#{total_cost.round(2)}/month"
end
```

## Resource Outputs

The resource provides comprehensive outputs for integration:

```ruby
outputs: {
  id: "${aws_elasticache_cluster.#{name}.id}",
  cluster_address: "${aws_elasticache_cluster.#{name}.cluster_address}",
  configuration_endpoint: "${aws_elasticache_cluster.#{name}.configuration_endpoint}",
  port: "${aws_elasticache_cluster.#{name}.port}",
  cache_nodes: "${aws_elasticache_cluster.#{name}.cache_nodes}"
}
```

## Computed Properties

Rich computed properties for infrastructure logic:

```ruby
computed_properties: {
  is_redis: cluster_attrs.is_redis?,
  supports_encryption: cluster_attrs.supports_encryption?,
  engine_supports_encryption: cluster_attrs.engine_supports_encryption?,
  estimated_monthly_cost: cluster_attrs.estimated_monthly_cost
}
```

## Best Practices Encoded

### 1. Security by Default
- Encryption enabled by default for Redis
- Auth token validation
- Security group requirement validation

### 2. Engine Optimization
- Single-node Redis for replication group compatibility
- Multi-node Memcached for distribution
- Engine-specific port defaults

### 3. Cost Awareness
- Instance type validation
- Cost estimation helpers
- Right-sizing guidance

## Integration Points

### Network Integration
- Subnet group requirement for VPC placement
- Security group integration for access control
- Multi-AZ placement support

### Monitoring Integration
- CloudWatch logs delivery configuration
- Performance insights support
- Notification topic integration

### Backup Integration
- Redis snapshot configuration
- Automated backup retention
- Final snapshot management

This implementation provides a production-ready, type-safe interface for ElastiCache clusters with comprehensive validation, engine-specific optimizations, and integration capabilities.