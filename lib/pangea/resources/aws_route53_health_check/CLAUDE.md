# AWS Route53 Health Check Implementation

## Overview

The `aws_route53_health_check` resource provides a comprehensive, type-safe interface for managing AWS Route53 Health Checks with support for all health check types, advanced configurations, and seamless integration with Route53 DNS records.

## Architecture

### Type System

The implementation uses `Route53HealthCheckAttributes` dry-struct with extensive health check validation:

```ruby
class Route53HealthCheckAttributes < Dry::Struct
  attribute :type, Types::String.enum("HTTP", "HTTPS", "HTTP_STR_MATCH", "HTTPS_STR_MATCH", "TCP", "CALCULATED", "CLOUDWATCH_METRIC")
  attribute? :fqdn, Types::String.optional
  attribute? :ip_address, Types::String.optional
  attribute? :port, Types::Integer.optional.constrained(gteq: 1, lteq: 65535)
  attribute :failure_threshold, Types::Integer.default(3).constrained(gteq: 1, lteq: 10)
  attribute :request_interval, Types::Integer.default(30).enum(10, 30)
  
  # Type-specific attributes
  attribute? :search_string, Types::String.optional
  attribute :child_health_checks, Types::Array.of(Types::String).default([].freeze)
  attribute? :cloudwatch_alarm_name, Types::String.optional
  # ... additional attributes
end
```

### Health Check Type Architecture

The resource implements sophisticated type-based validation and configuration:

#### Type Detection Methods
```ruby
def is_endpoint_health_check?
  %w[HTTP HTTPS HTTP_STR_MATCH HTTPS_STR_MATCH TCP].include?(type)
end

def is_calculated_health_check?
  type == "CALCULATED"
end

def is_cloudwatch_health_check?
  type == "CLOUDWATCH_METRIC"
end
```

#### Type-Specific Validation
```ruby
case attrs.type
when "HTTP", "HTTPS", "HTTP_STR_MATCH", "HTTPS_STR_MATCH"
  # Must have either FQDN or IP address
  unless attrs.fqdn || attrs.ip_address
    raise Dry::Struct::Error, "HTTP/HTTPS health checks require either fqdn or ip_address"
  end
  
  # String match types require search string
  if attrs.type.include?("STR_MATCH") && !attrs.search_string
    raise Dry::Struct::Error, "#{attrs.type} requires search_string parameter"
  end

when "TCP"
  unless attrs.port
    raise Dry::Struct::Error, "TCP health checks require port parameter"
  end

when "CALCULATED"
  if attrs.child_health_checks.empty?
    raise Dry::Struct::Error, "CALCULATED health checks require child_health_checks"
  end
end
```

## Key Features

### 1. Multi-Protocol Health Monitoring

The resource supports all AWS Route53 health check types with protocol-specific optimizations:

#### HTTP/HTTPS Monitoring
```ruby
# HTTP with string matching
if health_check_attrs.supports_string_matching? && health_check_attrs.search_string
  search_string health_check_attrs.search_string
end

# SSL configuration for HTTPS
if health_check_attrs.supports_ssl?
  enable_sni health_check_attrs.enable_sni
end
```

#### TCP Port Monitoring
```ruby
if health_check_attrs.is_endpoint_health_check?
  fqdn health_check_attrs.fqdn if health_check_attrs.fqdn
  ip_address health_check_attrs.ip_address if health_check_attrs.ip_address
  port health_check_attrs.port if health_check_attrs.port
end
```

### 2. Calculated Health Checks

Composite health monitoring combining multiple endpoints:

```ruby
if health_check_attrs.is_calculated_health_check?
  child_health_checks health_check_attrs.child_health_checks
  child_health_threshold health_check_attrs.child_health_threshold
end
```

### 3. CloudWatch Integration

Health checks based on CloudWatch alarm states:

```ruby
if health_check_attrs.is_cloudwatch_health_check?
  cloudwatch_alarm_name health_check_attrs.cloudwatch_alarm_name
  cloudwatch_alarm_region health_check_attrs.cloudwatch_alarm_region
  insufficient_data_health_status health_check_attrs.insufficient_data_health_status
end
```

### 4. Advanced Configuration Support

Comprehensive configuration options with intelligent defaults:

```ruby
# Set default ports if not specified
if !attrs.port
  default_port = attrs.type.start_with?("HTTPS") ? 443 : 80
  attrs = attrs.copy_with(port: default_port)
end

# Normalize resource path
if attrs.resource_path && !attrs.resource_path.start_with?('/')
  attrs = attrs.copy_with(resource_path: "/#{attrs.resource_path}")
end
```

## Implementation Patterns

### 1. Resource Function Architecture

The function implements conditional terraform resource generation based on health check type:

```ruby
def aws_route53_health_check(name, attributes = {})
  # 1. Validate attributes with type-specific validation
  health_check_attrs = Route53HealthCheckAttributes.new(attributes)
  
  # 2. Generate terraform resource with conditional configuration
  resource(:aws_route53_health_check, name) do
    type health_check_attrs.type
    
    # Conditional endpoint configuration
    if health_check_attrs.is_endpoint_health_check?
      # HTTP/HTTPS/TCP specific configuration
    end
    
    # Conditional calculated health check configuration
    if health_check_attrs.is_calculated_health_check?
      # Child health check configuration
    end
    
    # Conditional CloudWatch configuration
    if health_check_attrs.is_cloudwatch_health_check?
      # CloudWatch alarm configuration
    end
  end
  
  # 3. Return ResourceReference with health check specific outputs
end
```

### 2. Type-Specific Configuration Blocks

Dynamic configuration block generation based on health check type:

```ruby
# Endpoint configuration (HTTP/HTTPS/TCP)
if health_check_attrs.is_endpoint_health_check?
  fqdn health_check_attrs.fqdn if health_check_attrs.fqdn
  ip_address health_check_attrs.ip_address if health_check_attrs.ip_address
  port health_check_attrs.port if health_check_attrs.port
  resource_path health_check_attrs.resource_path if health_check_attrs.resource_path
end

# String matching configuration
if health_check_attrs.supports_string_matching? && health_check_attrs.search_string
  search_string health_check_attrs.search_string
end
```

### 3. Validation Integration

Comprehensive validation with helpful error messages:

```ruby
# Validate IP address format if provided
if attrs.ip_address && !attrs.valid_ip_address?
  raise Dry::Struct::Error, "Invalid IP address format: #{attrs.ip_address}"
end

# Validate FQDN format if provided
if attrs.fqdn && !attrs.valid_fqdn?
  raise Dry::Struct::Error, "Invalid FQDN format: #{attrs.fqdn}"
end
```

## Configuration Helpers

### Pre-defined Health Check Configurations

`Route53HealthCheckConfigs` module provides optimized configurations:

```ruby
module Route53HealthCheckConfigs
  def self.http_check(fqdn, port: 80, path: "/", search_string: nil)
    config = {
      type: search_string ? "HTTP_STR_MATCH" : "HTTP",
      fqdn: fqdn,
      port: port,
      resource_path: path,
      failure_threshold: 3,
      request_interval: 30
    }
    config[:search_string] = search_string if search_string
    config
  end
  
  def self.calculated_check(child_health_check_ids, min_healthy: nil)
    {
      type: "CALCULATED",
      child_health_checks: child_health_check_ids,
      child_health_threshold: min_healthy || (child_health_check_ids.length / 2).ceil
    }
  end
end
```

### Specialized Configurations

Multiple health check patterns for common use cases:

- **HTTP/HTTPS**: Web application monitoring with optional string matching
- **TCP**: Database and service port monitoring
- **Load Balancer**: Specialized load balancer health checking
- **Calculated**: Composite health monitoring
- **CloudWatch**: Alarm-based health checking

## Resource Outputs

Comprehensive outputs for health check integration:

```ruby
outputs: {
  id: "${aws_route53_health_check.#{name}.id}",
  arn: "${aws_route53_health_check.#{name}.arn}",
  reference_name: "${aws_route53_health_check.#{name}.reference_name}",
  type: "${aws_route53_health_check.#{name}.type}",
  fqdn: "${aws_route53_health_check.#{name}.fqdn}",
  port: "${aws_route53_health_check.#{name}.port}",
  failure_threshold: "${aws_route53_health_check.#{name}.failure_threshold}"
}
```

## Computed Properties

Rich metadata for health check analysis and integration:

```ruby
computed_properties: {
  is_endpoint_health_check: health_check_attrs.is_endpoint_health_check?,
  is_calculated_health_check: health_check_attrs.is_calculated_health_check?,
  is_cloudwatch_health_check: health_check_attrs.is_cloudwatch_health_check?,
  supports_string_matching: health_check_attrs.supports_string_matching?,
  supports_ssl: health_check_attrs.supports_ssl?,
  endpoint_identifier: health_check_attrs.endpoint_identifier,
  configuration_warnings: health_check_attrs.validate_configuration,
  estimated_monthly_cost: health_check_attrs.estimated_monthly_cost
}
```

### Cost Estimation

Built-in cost estimation with feature-based pricing:

```ruby
def estimated_monthly_cost
  base_cost = 0.50  # $0.50 per health check per month
  
  # Additional costs for optional features
  if measure_latency
    base_cost += 1.00  # $1.00 additional for latency measurement
  end
  
  # Request interval affects cost
  if request_interval == 10
    base_cost += 2.00  # Fast interval costs more
  end
  
  "$#{base_cost}/month"
end
```

## Integration Patterns

### 1. Route53 Record Integration

Direct integration with Route53 DNS records for failover and routing:

```ruby
health_check = aws_route53_health_check(:primary_health, {
  type: "HTTPS_STR_MATCH",
  fqdn: "api.example.com",
  search_string: "OK"
})

dns_record = aws_route53_record(:api_primary, {
  zone_id: zone.zone_id,
  name: "api.example.com",
  type: "A",
  records: ["203.0.113.1"],
  health_check_id: health_check.id,  # Link health check to DNS record
  failover_routing_policy: { type: "PRIMARY" }
})
```

### 2. Load Balancer Health Monitoring

Application load balancer health checking:

```ruby
alb_health = aws_route53_health_check(:alb_health, {
  type: "HTTPS_STR_MATCH",
  fqdn: load_balancer.dns_name,
  port: 443,
  resource_path: "/health",
  search_string: "healthy",
  enable_sni: true
})
```

### 3. Hierarchical Health Architecture

Multi-tier health monitoring with calculated health checks:

```ruby
# Individual component health checks
api_health = aws_route53_health_check(:api, {
  type: "HTTPS_STR_MATCH",
  fqdn: "api.internal.com",
  search_string: "OK"
})

db_health = aws_route53_health_check(:database, {
  type: "TCP",
  fqdn: "db.internal.com",
  port: 5432
})

# Overall system health
system_health = aws_route53_health_check(:system, {
  type: "CALCULATED",
  child_health_checks: [api_health.id, db_health.id],
  child_health_threshold: 1,  # Healthy if either component is healthy
  reference_name: "Overall System Health"
})
```

## Best Practices Encoded

### 1. Protocol-Specific Optimization
- Automatic port defaults for HTTP/HTTPS
- SSL/SNI configuration for HTTPS
- String matching for application health validation

### 2. Cost Optimization
- Built-in cost estimation
- Fast interval cost awareness
- Calculated health check efficiency

### 3. High Availability Patterns
- Failover routing integration
- Multi-endpoint monitoring
- Composite health checking

## AWS Service Integration

### Route53 Service
- All health check types supported
- DNS record integration for routing policies
- Global health check distribution

### CloudWatch Integration
- Alarm-based health checking
- Health check metrics and monitoring
- Custom alarm integration

### Load Balancer Integration
- ALB/NLB health check coordination
- Target group health correlation
- Multi-region health monitoring

This implementation provides production-ready health check management with comprehensive type validation, cost optimization, and seamless integration with Route53 DNS routing and AWS monitoring services.