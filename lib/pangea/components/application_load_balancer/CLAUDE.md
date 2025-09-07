# Application Load Balancer Component Implementation

## Overview

The Application Load Balancer component creates a production-ready ALB with target groups, health checks, SSL/TLS termination, and comprehensive monitoring. It demonstrates the Pangea component pattern of composing multiple AWS resources into a reusable, type-safe building block.

## Architecture

The component creates and manages the following AWS resources:

### Core Resources
- **AWS ALB**: Application Load Balancer with multi-AZ deployment
- **Target Groups**: One or more target groups with health check configuration
- **Listeners**: HTTP/HTTPS listeners with SSL termination and security policies
- **CloudWatch Alarms**: Automated monitoring for response time, errors, and health

### Optional Resources
- **SSL Certificates**: ACM certificate integration for HTTPS
- **Access Logging**: S3 bucket integration for request logging
- **Security Headers**: HTTP security header injection

## Implementation Details

### Type Safety

The component uses comprehensive dry-struct validation:

```ruby
class ApplicationLoadBalancerAttributes < Dry::Struct
  attribute :vpc_ref, Types.Instance(Object)  # ResourceReference validation
  attribute :subnet_refs, Types::Array.of(Types.Instance(Object)).constrained(min_size: 2)
  attribute :scheme, Types::String.enum('internet-facing', 'internal')
  # ... additional validation
end
```

Key validation patterns:
- **Resource References**: Validates VPC and subnet resource objects
- **Network Requirements**: Ensures minimum 2 subnets for high availability
- **SSL Configuration**: Validates certificate ARN format and SSL policy compatibility
- **Health Check Parameters**: Validates timeout, interval, and threshold ranges

### Resource Composition

The component demonstrates sophisticated resource composition:

1. **Primary ALB Creation**: Creates the load balancer with networking and security configuration
2. **Target Group Management**: Creates default and custom target groups with health checks
3. **Listener Configuration**: Sets up HTTP and HTTPS listeners with appropriate actions
4. **SSL Redirection**: Automatically creates HTTP-to-HTTPS redirect listeners
5. **Monitoring Setup**: Creates comprehensive CloudWatch alarms

### Security Features

- **SSL/TLS Termination**: Full certificate lifecycle management
- **Security Group Integration**: Seamless integration with existing security groups
- **HTTP Security Headers**: OWASP-recommended security headers
- **SSL Enforcement**: Automatic SSL-only policies
- **Access Logging**: Comprehensive request logging for security auditing

### Health Check Automation

Advanced health check configuration:
- **Configurable Endpoints**: Custom health check paths and protocols
- **Intelligent Defaults**: Production-ready default health check parameters
- **Multi-Protocol Support**: HTTP, HTTPS, TCP health checks
- **Response Code Matching**: Flexible success response code patterns

## Usage Patterns

### Basic Web Application
```ruby
alb = application_load_balancer(:web_alb, {
  vpc_ref: vpc,
  subnet_refs: [public_subnet_1, public_subnet_2],
  security_group_refs: [web_sg],
  enable_https: true,
  certificate_arn: certificate.arn
})
```

### Microservices Architecture
```ruby
alb = application_load_balancer(:api_gateway, {
  vpc_ref: vpc,
  subnet_refs: public_subnets,
  security_group_refs: [api_sg],
  target_groups: [
    { name: "api", port: 8080, health_check: { path: "/health" } },
    { name: "admin", port: 9000, health_check: { path: "/admin/status" } }
  ],
  listeners: [
    { port: 80, protocol: "HTTP", default_action_type: "redirect" },
    { port: 443, protocol: "HTTPS", default_action_type: "forward" }
  ]
})
```

## Component Reference Integration

The component returns a `ComponentReference` with:

### Resources Structure
```ruby
{
  alb: ResourceReference,              # Primary ALB resource
  target_groups: {                     # Hash of target group references
    default: ResourceReference,
    api: ResourceReference,
    admin: ResourceReference
  },
  listeners: {                         # Hash of listener references  
    listener_80_http: ResourceReference,
    listener_443_https: ResourceReference
  },
  alarms: {                           # Monitoring alarms
    response_time: ResourceReference,
    unhealthy_hosts: ResourceReference,
    error_rate: ResourceReference
  }
}
```

### Computed Outputs
```ruby
{
  alb_arn: "arn:aws:elasticloadbalancing:...",
  alb_dns_name: "web-alb-123456789.us-east-1.elb.amazonaws.com",
  target_group_arns: { default: "arn:aws:...", api: "arn:aws:..." },
  security_features: ["HTTPS Support", "Health Checks", "SSL Redirect"],
  estimated_monthly_cost: 22.0
}
```

## Integration with Other Components

### Auto Scaling Groups
```ruby
# ALB creates target groups
alb = application_load_balancer(:web_alb, { ... })

# ASG automatically registers with target groups
asg = auto_scaling_web_servers(:web_servers, {
  target_group_refs: [alb.resources[:target_groups][:default]]
})
```

### WAF Integration
```ruby
# ALB ARN used for WAF association
waf_association = aws_wafv2_web_acl_association(:alb_waf, {
  resource_arn: alb.outputs[:alb_arn],
  web_acl_arn: web_acl.arn
})
```

## Monitoring and Observability

### Automatic CloudWatch Alarms
- **Target Response Time**: Alerts when response time exceeds 1 second
- **Unhealthy Host Count**: Monitors target health across all target groups  
- **HTTP 5xx Error Rate**: Tracks server error rates over time
- **Request Volume**: Monitors traffic patterns and capacity

### Access Logging Integration
```ruby
alb = application_load_balancer(:production_alb, {
  enable_access_logs: true,
  access_logs_bucket: "production-alb-logs",
  access_logs_prefix: "alb-logs/"
})
```

## Cost Optimization Features

- **Cross-Zone Load Balancing**: Optional to reduce data transfer costs
- **Target Group Optimization**: Minimizes target group count to reduce costs
- **Health Check Tuning**: Balances responsiveness with API call costs
- **SSL Certificate**: Free ACM certificates vs. third-party certificate costs

## Production Best Practices

1. **Multi-AZ Deployment**: Always deploy across multiple availability zones
2. **Security Group Hygiene**: Use least-privilege security group rules
3. **SSL Configuration**: Use modern SSL policies and HSTS headers
4. **Health Check Tuning**: Set appropriate timeouts for application startup
5. **Access Logging**: Enable for security monitoring and troubleshooting
6. **Certificate Management**: Use ACM for automatic certificate renewal

## Error Handling and Validation

### Compile-Time Validation
- Resource reference type checking
- SSL certificate ARN format validation
- Network configuration validation (subnets, security groups)

### Runtime Validation  
- Health check parameter ranges
- SSL policy compatibility
- Target group configuration conflicts

### Error Recovery
- Automatic retry for transient failures
- Graceful degradation for optional features
- Clear error messages for configuration issues

## Performance Characteristics

### Scalability
- Supports up to 100 target groups per ALB
- Handles millions of requests per second
- Auto-scales based on traffic demand

### Availability
- 99.99% SLA when deployed across multiple AZs
- Automatic failover between availability zones
- Health check automation reduces MTTR

### Security
- WAF integration ready
- Shield Advanced compatible
- Security group automation

This component exemplifies the Pangea philosophy of providing production-ready, enterprise-grade infrastructure components with comprehensive type safety, security defaults, and operational excellence built-in.