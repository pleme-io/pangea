# AWS Load Balancer Listener Implementation

## Overview

The `aws_lb_listener` resource implements comprehensive AWS Load Balancer listener management with advanced type safety and validation for all supported protocols, actions, and configurations.

## Architecture

### Type System

```ruby
LoadBalancerListenerAttributes < Dry::Struct
  - load_balancer_arn: String (required)
  - port: ListenerPort (1-65535)
  - protocol: ListenerProtocol (HTTP, HTTPS, TCP, TLS, UDP, TCP_UDP, GENEVE)
  - ssl_policy: SslPolicy (HTTPS/TLS only)
  - certificate_arn: String (HTTPS/TLS only)
  - alpn_policy: String (HTTP1Only, HTTP2Only, HTTP2Optional, HTTP2Preferred, None)
  - default_action: Array[ActionConfig] (min 1 action)
  - tags: AwsTags
```

### Validation Logic

**Protocol-Specific Requirements:**
- HTTPS/TLS: Requires `ssl_policy` and `certificate_arn`
- HTTP/TCP/UDP: SSL configurations not allowed
- GENEVE: Gateway Load Balancer specific protocol

**Action Validation:**
- Each action type validates required sub-configurations
- Forward actions require either `target_group_arn` or `forward` block
- Complex actions like authenticate-cognito validate ARN formats

### Terraform Synthesis

The resource generates comprehensive Terraform JSON including:
- Base listener configuration (ARN, port, protocol)
- SSL configuration for encrypted listeners
- Complex default action blocks with proper nesting
- Tag management

## Load Balancer Type Support

### Application Load Balancer (ALB)
- **Protocols**: HTTP, HTTPS
- **Features**: Layer 7 routing, SSL termination, authentication
- **Actions**: All action types supported
- **Use Cases**: Web applications, APIs, microservices

### Network Load Balancer (NLB) 
- **Protocols**: TCP, TLS, UDP, TCP_UDP
- **Features**: Layer 4 routing, ultra-low latency, static IPs
- **Actions**: Forward only
- **Use Cases**: High-performance applications, gaming, IoT

### Gateway Load Balancer (GLB)
- **Protocols**: GENEVE
- **Features**: Network appliance integration
- **Actions**: Forward only  
- **Use Cases**: Firewalls, intrusion detection, DDoS protection

## Action Types Implementation

### Forward Actions

```ruby
# Simple target group forwarding
{
  type: "forward",
  target_group_arn: "arn:aws:elasticloadbalancing:..."
}

# Weighted routing with stickiness
{
  type: "forward", 
  forward: {
    target_groups: [
      { arn: "...", weight: 80 },
      { arn: "...", weight: 20 }
    ],
    stickiness: {
      enabled: true,
      duration: 3600
    }
  }
}
```

### Redirect Actions

```ruby
{
  type: "redirect",
  redirect: {
    protocol: "HTTPS",
    port: "443", 
    status_code: "HTTP_301"
  }
}
```

### Authentication Actions

**Cognito Integration:**
```ruby
{
  type: "authenticate-cognito",
  authenticate_cognito: {
    user_pool_arn: "arn:aws:cognito-idp:...",
    user_pool_client_id: "client-id",
    user_pool_domain: "auth.example.com"
  }
}
```

**OIDC Integration:**
```ruby
{
  type: "authenticate-oidc",
  authenticate_oidc: {
    authorization_endpoint: "https://auth.example.com/oauth/authorize",
    client_id: "oauth-client-id",
    issuer: "https://auth.example.com"
  }
}
```

### Fixed Response Actions

```ruby
{
  type: "fixed-response",
  fixed_response: {
    content_type: "application/json",
    message_body: '{"status":"maintenance"}',
    status_code: "503"
  }
}
```

## SSL/TLS Configuration

### SSL Policies

The implementation supports all current AWS ELB Security Policies:
- **ELBSecurityPolicy-TLS-1-0-2015-04**: Legacy support
- **ELBSecurityPolicy-FS-1-2-Res-2020-10**: Most secure, forward secrecy
- **ELBSecurityPolicy-TLS-1-2-2017-01**: Balanced security/compatibility

### ALPN Support

HTTP/2 optimization through ALPN policies:
- **HTTP2Preferred**: Negotiates HTTP/2 when possible
- **HTTP2Only**: Forces HTTP/2 (gRPC optimized)
- **HTTP1Only**: Forces HTTP/1.1
- **None**: No ALPN negotiation

## Production Patterns

### Microservices Architecture

```ruby
# API Gateway pattern with authentication
api_listener = aws_lb_listener(:api_gateway, {
  load_balancer_arn: alb.arn,
  port: 443,
  protocol: "HTTPS",
  ssl_policy: "ELBSecurityPolicy-FS-1-2-Res-2020-10",
  certificate_arn: cert.arn,
  alpn_policy: "HTTP2Preferred",
  default_action: [
    {
      type: "authenticate-oidc",
      order: 1,
      authenticate_oidc: {
        authorization_endpoint: "https://auth.company.com/oauth/authorize",
        client_id: "api-gateway-client",
        issuer: "https://auth.company.com"
      }
    },
    {
      type: "forward", 
      order: 2,
      target_group_arn: default_api_tg.arn
    }
  ]
})
```

### High Availability Setup

```ruby
# Multi-AZ production listener with health checking
prod_listener = aws_lb_listener(:production_web, {
  load_balancer_arn: multi_az_alb.arn,
  port: 443,
  protocol: "HTTPS",
  ssl_policy: "ELBSecurityPolicy-FS-1-2-Res-2020-10",
  certificate_arn: wildcard_cert.arn,
  default_action: [{
    type: "forward",
    forward: {
      target_groups: [
        { arn: primary_tg.arn, weight: 100 }
      ]
    }
  }],
  tags: {
    Name: "production-web-listener",
    Environment: "production", 
    HighAvailability: "true"
  }
})
```

### Blue/Green Deployment

```ruby
# Weighted routing for zero-downtime deployments  
blue_green_listener = aws_lb_listener(:blue_green_deploy, {
  load_balancer_arn: deployment_alb.arn,
  port: 80,
  protocol: "HTTP",
  default_action: [{
    type: "forward",
    forward: {
      target_groups: [
        { arn: blue_environment_tg.arn, weight: 100 },
        { arn: green_environment_tg.arn, weight: 0 }
      ]
    }
  }]
})
```

## Security Considerations

### SSL/TLS Best Practices
- Use `ELBSecurityPolicy-FS-1-2-Res-2020-10` for maximum security
- Enable HTTP/2 with `alpn_policy: "HTTP2Preferred"`
- Always use certificate validation
- Implement HTTPS redirect for HTTP listeners

### Authentication Integration
- Validate Cognito User Pool ARNs format
- Secure OIDC client secrets using AWS Secrets Manager references
- Implement proper session timeout values (1-604800 seconds)
- Use appropriate scopes for OAuth flows

### Network Security
- Validate target group ARNs match load balancer type
- Ensure certificate ARNs are in correct region
- Implement proper security group rules for listener ports

## Error Handling

The implementation provides comprehensive validation errors:
- **Protocol Mismatch**: SSL configuration on non-HTTPS listeners
- **Missing Requirements**: SSL policy/certificate missing for HTTPS
- **Invalid Actions**: Incomplete action configurations
- **AWS Constraints**: Port ranges, ARN formats, weight limits

## Testing Patterns

### Unit Testing
```ruby
describe "aws_lb_listener validation" do
  it "requires SSL policy for HTTPS listeners" do
    expect {
      aws_lb_listener(:test, {
        load_balancer_arn: "arn:aws:...",
        port: 443,
        protocol: "HTTPS",
        # Missing ssl_policy and certificate_arn
        default_action: [{ type: "forward", target_group_arn: "..." }]
      })
    }.to raise_error(/ssl_policy is required/)
  end
end
```

### Integration Testing
```ruby
# Test complete HTTPS listener with authentication
https_auth_listener = aws_lb_listener(:integration_test, {
  load_balancer_arn: test_alb.arn,
  port: 443,
  protocol: "HTTPS",
  ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
  certificate_arn: test_cert.arn,
  default_action: [{
    type: "authenticate-cognito",
    authenticate_cognito: {
      user_pool_arn: test_user_pool.arn,
      user_pool_client_id: "test-client",
      user_pool_domain: "test-auth.example.com"
    }
  }]
})
```

## Performance Considerations

- **HTTP/2**: Use `alpn_policy: "HTTP2Preferred"` for better performance
- **Stickiness**: Configure appropriate session stickiness for stateful applications
- **Weighted Routing**: Implement gradual traffic shifting for deployments
- **SSL Offloading**: Terminate SSL at load balancer level for backend efficiency

This implementation provides production-ready AWS Load Balancer listener management with comprehensive validation, security controls, and support for complex enterprise patterns.