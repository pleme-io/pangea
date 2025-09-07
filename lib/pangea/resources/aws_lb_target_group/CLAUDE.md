# AWS Load Balancer Target Group Resource Implementation

## Overview

The `aws_lb_target_group` resource creates an AWS Target Group for use with Application Load Balancers (ALB), Network Load Balancers (NLB), or Gateway Load Balancers (GWLB). Target groups route requests to registered targets (EC2 instances, IP addresses, Lambda functions, or other ALBs) based on the protocol and port specified.

## Type Safety Implementation

### Attributes Structure

```ruby
class TargetGroupAttributes < Dry::Struct
  # Required attributes
  attribute :port, Port                              # 0-65535
  attribute :protocol, String.enum(HTTP, HTTPS, TCP, TLS, UDP, TCP_UDP, GENEVE)
  attribute :vpc_id, String                           # VPC ID
  
  # Optional attributes
  attribute :name, String.optional
  attribute :name_prefix, String.optional
  attribute :target_type, AlbTargetType               # instance, ip, lambda, alb
  attribute :deregistration_delay, Integer            # 0-3600 seconds
  attribute :slow_start, Integer                      # 0-900 seconds
  
  # Nested configurations
  attribute :health_check, TargetGroupHealthCheck.optional
  attribute :stickiness, TargetGroupStickiness.optional
end

class TargetGroupHealthCheck < Dry::Struct
  attribute :enabled, Bool
  attribute :interval, Integer                        # 5-300 seconds
  attribute :path, String                            # HTTP/HTTPS only
  attribute :port, String                            # traffic-port or specific
  attribute :protocol, HealthCheckProtocol
  attribute :timeout, Integer                        # Must be < interval
  attribute :healthy_threshold, Integer              # 2-10
  attribute :unhealthy_threshold, Integer            # 2-10
  attribute :matcher, String                         # HTTP status codes
end
```

### Key Design Decisions

1. **Protocol-Specific Validation**:
   - GENEVE protocol requires port 6081
   - HTTP/HTTPS support health check paths and stickiness
   - TCP/TLS/UDP for Network Load Balancers
   - Protocol version only valid for HTTP/HTTPS

2. **Name vs Name Prefix**:
   - Mutually exclusive options
   - `name`: Fixed target group name
   - `name_prefix`: AWS generates unique name

3. **Health Check Configuration**:
   - Timeout must be less than interval
   - Path only valid for HTTP/HTTPS protocols
   - Matcher (status codes) only for HTTP/HTTPS

4. **Stickiness Support**:
   - Only available for ALB (HTTP/HTTPS)
   - Two types: lb_cookie and app_cookie
   - app_cookie requires cookie_name

5. **Computed Properties**:
   - `supports_stickiness?`: True for HTTP/HTTPS
   - `supports_health_check_path?`: True for HTTP/HTTPS
   - `is_network_load_balancer?`: True for TCP/TLS/UDP

## Resource Function Pattern

The `aws_lb_target_group` function handles protocol-specific configurations:

```ruby
def aws_lb_target_group(name, attributes = {})
  # 1. Validate attributes with dry-struct
  tg_attrs = Types::TargetGroupAttributes.new(attributes)
  
  # 2. Generate Terraform resource via synthesizer
  resource(:aws_lb_target_group, name) do
    # Basic configuration
    port tg_attrs.port
    protocol tg_attrs.protocol
    vpc_id tg_attrs.vpc_id
    
    # Conditional health check block
    if tg_attrs.health_check
      health_check do
        # Only include path for HTTP/HTTPS
        path hc.path if tg_attrs.supports_health_check_path?
        # ... other health check settings
      end
    end
    
    # Conditional stickiness (only for ALB)
    if tg_attrs.stickiness && tg_attrs.supports_stickiness?
      stickiness do
        # Stickiness configuration
      end
    end
  end
  
  # 3. Return ResourceReference with outputs and computed properties
  ResourceReference.new(
    type: 'aws_lb_target_group',
    name: name,
    outputs: { id, arn, arn_suffix, name, port, protocol },
    computed_properties: { supports_stickiness, is_network_load_balancer }
  )
end
```

## Integration with Terraform Synthesizer

The resource handles protocol-specific features:

```ruby
resource(:aws_lb_target_group, name) do
  port 80
  protocol "HTTP"
  vpc_id vpc_id
  target_type "instance"
  
  # ALB-specific health check
  health_check do
    enabled true
    interval 30
    path "/health"        # Only for HTTP/HTTPS
    port "traffic-port"
    protocol "HTTP"
    timeout 5
    healthy_threshold 2
    unhealthy_threshold 3
    matcher "200-299"     # Only for HTTP/HTTPS
  end
  
  # ALB-specific stickiness
  stickiness do
    enabled true
    type "lb_cookie"
    duration 86400
  end
  
  tags do
    Name "web-target-group"
    Environment "production"
  end
end
```

## Common Usage Patterns

### 1. HTTP Target Group for ALB
```ruby
tg = aws_lb_target_group(:web, {
  port: 80,
  protocol: "HTTP",
  vpc_id: vpc.id,
  health_check: {
    enabled: true,
    path: "/health",
    interval: 30,
    timeout: 5,
    healthy_threshold: 2,
    unhealthy_threshold: 3,
    matcher: "200,301"
  },
  stickiness: {
    enabled: true,
    type: "lb_cookie",
    duration: 3600
  }
})
```

### 2. TCP Target Group for NLB
```ruby
tg = aws_lb_target_group(:tcp_app, {
  port: 3306,
  protocol: "TCP",
  vpc_id: vpc.id,
  target_type: "instance",
  deregistration_delay: 60,
  health_check: {
    enabled: true,
    protocol: "TCP",
    interval: 10,
    timeout: 5,
    healthy_threshold: 2,
    unhealthy_threshold: 2
  }
})
```

### 3. Lambda Target Group
```ruby
tg = aws_lb_target_group(:lambda, {
  port: 443,
  protocol: "HTTPS",
  vpc_id: vpc.id,
  target_type: "lambda",
  health_check: {
    enabled: false  # Lambda health checks work differently
  }
})
```

### 4. IP-based Target Group for Containers
```ruby
tg = aws_lb_target_group(:container, {
  port: 8080,
  protocol: "HTTP",
  vpc_id: vpc.id,
  target_type: "ip",
  slow_start: 30,  # Gradual traffic increase
  deregistration_delay: 30,
  health_check: {
    path: "/api/health",
    interval: 15,
    timeout: 10,
    healthy_threshold: 2,
    unhealthy_threshold: 3
  }
})
```

## Testing Considerations

1. **Type Validation**:
   - Test protocol-specific constraints
   - Test name/name_prefix mutual exclusivity
   - Test health check timeout < interval
   - Test port range validation

2. **Protocol-Specific Features**:
   - Verify stickiness only for HTTP/HTTPS
   - Verify health check path only for HTTP/HTTPS
   - Test GENEVE port requirement

3. **Nested Structure Generation**:
   - Test health check block generation
   - Test stickiness block inclusion
   - Test conditional attribute inclusion

4. **Edge Cases**:
   - Empty health check configuration
   - Invalid protocol/feature combinations
   - Target type specific validations

## Future Enhancements

1. **Enhanced Validation**:
   - Cross-validate target type with protocol
   - Validate health check protocol compatibility
   - VPC ID format validation

2. **Additional Features**:
   - Connection termination settings
   - Advanced routing configuration
   - Target group weight support

3. **Computed Properties**:
   - Estimated target capacity
   - Protocol-specific recommendations
   - Health check timing analysis

4. **Helper Methods**:
   - Target registration helpers
   - Health check template generators
   - Blue/green deployment support