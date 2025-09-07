# AWS Route53 Record Implementation

## Overview

The `aws_route53_record` resource provides a comprehensive, type-safe interface for managing AWS Route53 DNS records with support for all DNS record types, advanced routing policies, alias records, and health check integration.

## Architecture

### Type System

The implementation uses `Route53RecordAttributes` dry-struct with comprehensive DNS validation:

```ruby
class Route53RecordAttributes < Dry::Struct
  attribute :zone_id, Types::String
  attribute :name, Types::String
  attribute :type, Types::String.enum("A", "AAAA", "CNAME", "MX", "NS", "PTR", "SOA", "SPF", "SRV", "TXT")
  attribute? :ttl, Types::Integer.optional.constrained(gteq: 0, lteq: 2147483647)
  attribute :records, Types::Array.of(Types::String).default([].freeze)
  
  # Routing policies
  attribute? :weighted_routing_policy, Types::Hash.schema(weight: Types::Integer.constrained(gteq: 0, lteq: 255)).optional
  attribute? :latency_routing_policy, Types::Hash.schema(region: Types::String).optional
  attribute? :failover_routing_policy, Types::Hash.schema(type: Types::String.enum("PRIMARY", "SECONDARY")).optional
  # ... additional routing policies
end
```

### Advanced Validation Strategy

The implementation includes sophisticated validation for DNS compliance and Route53 constraints:

#### DNS Record Name Validation
```ruby
def valid_record_name?
  return false if name.nil? || name.empty?
  return false if name.length > 253
  
  # Allow wildcard at the beginning
  name_to_check = name.start_with?('*.') ? name[2..-1] : name
  
  labels = name_to_check.split('.')
  labels.all? { |label| valid_dns_label?(label) }
end
```

#### Record Type-Specific Validation
```ruby
def validate_record_type_constraints
  case type
  when "A"
    records.each do |record|
      unless valid_ipv4?(record)
        raise Dry::Struct::Error, "A record must contain valid IPv4 addresses: #{record}"
      end
    end
  when "CNAME"
    if records.length != 1
      raise Dry::Struct::Error, "CNAME record must have exactly one target"
    end
  when "MX"
    records.each do |record|
      unless record.match?(/\A\d+\s+\S+\z/)
        raise Dry::Struct::Error, "MX record must be in format 'priority hostname': #{record}"
      end
    end
  end
end
```

#### Routing Policy Mutual Exclusion
```ruby
routing_policies = [
  weighted_routing_policy,
  latency_routing_policy,
  failover_routing_policy,
  geolocation_routing_policy,
  geoproximity_routing_policy
].compact

if routing_policies.length > 1
  raise Dry::Struct::Error, "Only one routing policy can be specified per record"
end
```

## Key Features

### 1. Complete DNS Record Type Support

The resource supports all standard DNS record types with type-specific validation:

- **A Records**: IPv4 address validation
- **AAAA Records**: IPv6 address validation  
- **CNAME Records**: Single target enforcement
- **MX Records**: Priority/hostname format validation
- **SRV Records**: Service record format validation
- **TXT Records**: Text data support

### 2. Alias Record Support

AWS-specific alias records for cost-effective AWS resource references:

```ruby
if record_attrs.alias
  _alias do  # Use _alias since 'alias' is a Ruby keyword
    name alias_block[:name]
    zone_id alias_block[:zone_id]
    evaluate_target_health alias_block[:evaluate_target_health]
  end
end
```

### 3. Advanced Routing Policies

Complete support for all Route53 routing policies:

#### Weighted Routing
```ruby
if record_attrs.weighted_routing_policy
  weighted_routing_policy do
    weight record_attrs.weighted_routing_policy[:weight]
  end
end
```

#### Geolocation Routing
```ruby
if record_attrs.geolocation_routing_policy
  geolocation_routing_policy do
    geo_policy = record_attrs.geolocation_routing_policy
    continent geo_policy[:continent] if geo_policy[:continent]
    country geo_policy[:country] if geo_policy[:country]
    subdivision geo_policy[:subdivision] if geo_policy[:subdivision]
  end
end
```

### 4. Health Check Integration

Seamless integration with Route53 health checks:

```ruby
health_check_id record_attrs.health_check_id if record_attrs.health_check_id
```

Health check ID validation:
```ruby
if attrs.health_check_id
  unless attrs.health_check_id.match?(/\A[a-f0-9\-]+\z/)
    raise Dry::Struct::Error, "Invalid health check ID format: #{attrs.health_check_id}"
  end
end
```

## Implementation Patterns

### 1. Resource Function Architecture

The function handles complex conditional terraform resource generation:

```ruby
def aws_route53_record(name, attributes = {})
  # 1. Validate comprehensive attributes
  record_attrs = Route53RecordAttributes.new(attributes)
  
  # 2. Generate terraform resource with conditional blocks
  resource(:aws_route53_record, name) do
    zone_id record_attrs.zone_id
    name record_attrs.name
    type record_attrs.type
    
    # Conditional simple record vs alias record configuration
    if !record_attrs.is_alias_record?
      ttl record_attrs.ttl
      records record_attrs.records
    else
      # Alias block generation
    end
    
    # Dynamic routing policy blocks
    # Health check integration
    # Additional configurations
  end
  
  # 3. Return ResourceReference with DNS-specific outputs
end
```

### 2. Conditional Block Generation

Complex conditional terraform block generation based on record configuration:

```ruby
# Simple record configuration
if !record_attrs.is_alias_record?
  ttl record_attrs.ttl
  records record_attrs.records if record_attrs.records.any?
end

# Alias record configuration
if record_attrs.alias
  alias_block = record_attrs.alias
  _alias do
    name alias_block[:name]
    zone_id alias_block[:zone_id]
    evaluate_target_health alias_block[:evaluate_target_health]
  end
end
```

### 3. Routing Policy Block Generation

Dynamic routing policy block generation:

```ruby
# Each routing policy gets its own conditional block
if record_attrs.weighted_routing_policy
  weighted_routing_policy do
    weight record_attrs.weighted_routing_policy[:weight]
  end
end

if record_attrs.latency_routing_policy
  latency_routing_policy do
    region record_attrs.latency_routing_policy[:region]
  end
end
```

## Configuration Helpers

### Pre-defined Record Configurations

`Route53RecordConfigs` module provides DNS record patterns:

```ruby
module Route53RecordConfigs
  def self.a_record(zone_id, name, ip_addresses, ttl: 300)
    {
      zone_id: zone_id,
      name: name,
      type: "A",
      ttl: ttl,
      records: Array(ip_addresses)
    }
  end
  
  def self.alias_record(zone_id, name, target_dns_name, target_zone_id, evaluate_health: false)
    {
      zone_id: zone_id,
      name: name,
      type: "A",
      alias: {
        name: target_dns_name,
        zone_id: target_zone_id,
        evaluate_target_health: evaluate_health
      }
    }
  end
end
```

### Routing Policy Helpers

Specialized configurations for routing policies:

```ruby
def self.failover_record(zone_id, name, type, records, failover_type, identifier, ttl: 300, health_check_id: nil)
  {
    zone_id: zone_id,
    name: name,
    type: type,
    set_identifier: identifier,
    failover_routing_policy: { type: failover_type.upcase },
    health_check_id: health_check_id
  }.compact
end
```

## Resource Outputs

Comprehensive outputs for DNS resolution and monitoring:

```ruby
outputs: {
  id: "${aws_route53_record.#{name}.id}",
  name: "${aws_route53_record.#{name}.name}",
  fqdn: "${aws_route53_record.#{name}.fqdn}",
  type: "${aws_route53_record.#{name}.type}",
  zone_id: "${aws_route53_record.#{name}.zone_id}",
  records: "${aws_route53_record.#{name}.records}",
  ttl: "${aws_route53_record.#{name}.ttl}"
}
```

## Computed Properties

Rich metadata for DNS infrastructure analysis:

```ruby
computed_properties: {
  is_alias_record: record_attrs.is_alias_record?,
  is_simple_record: record_attrs.is_simple_record?,
  routing_policy_type: record_attrs.routing_policy_type,
  has_routing_policy: record_attrs.has_routing_policy?,
  is_wildcard_record: record_attrs.is_wildcard_record?,
  domain_name: record_attrs.domain_name,
  estimated_query_cost_per_million: record_attrs.estimated_query_cost_per_million
}
```

### Cost Estimation

Built-in cost estimation for different routing types:

```ruby
def estimated_query_cost_per_million
  base_cost = 0.40  # $0.40 per million queries for standard
  
  case routing_policy_type
  when "weighted", "latency", "failover", "geolocation"
    base_cost * 2  # 2x cost for routing policies
  when "geoproximity"
    base_cost * 3  # 3x cost for geoproximity
  else
    base_cost
  end
end
```

## Integration Patterns

### 1. Hosted Zone Integration

Direct integration with Route53 hosted zones:

```ruby
zone = aws_route53_zone(:example, { name: "example.com" })

record = aws_route53_record(:www, {
  zone_id: zone.zone_id,  # Reference zone
  name: "www.example.com",
  type: "A",
  records: ["203.0.113.1"]
})
```

### 2. AWS Resource Alias Integration

Cost-effective AWS resource references:

```ruby
load_balancer = aws_lb(:app_lb, { ... })

alias_record = aws_route53_record(:app_alias, {
  zone_id: zone.zone_id,
  name: "app.example.com",
  type: "A",
  alias: {
    name: load_balancer.dns_name,
    zone_id: load_balancer.zone_id,
    evaluate_target_health: true
  }
})
```

### 3. Health Check Integration

Failover configuration with health monitoring:

```ruby
health_check = aws_route53_health_check(:primary, { ... })

primary_record = aws_route53_record(:primary, {
  zone_id: zone.zone_id,
  name: "api.example.com",
  type: "A",
  records: ["203.0.113.1"],
  set_identifier: "primary",
  failover_routing_policy: { type: "PRIMARY" },
  health_check_id: health_check.id
})
```

## Best Practices Encoded

### 1. DNS Compliance
- Complete DNS record name validation
- Record type-specific format enforcement
- TTL range validation

### 2. Route53 Optimization
- Alias record recommendation for AWS resources
- Cost-aware routing policy selection
- Health check integration guidance

### 3. High Availability Patterns
- Failover routing with health checks
- Multi-region latency routing
- Weighted traffic distribution

## AWS Service Integration

### Route53 Service
- All DNS record types supported
- Advanced routing policy implementation
- Health check integration

### AWS Resource Integration
- Load Balancer alias records
- CloudFront distribution aliases
- S3 website endpoint aliases

This implementation provides production-ready DNS record management with comprehensive validation, advanced routing capabilities, and seamless integration with Route53 hosted zones and AWS resources.