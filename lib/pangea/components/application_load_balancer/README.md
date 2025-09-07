# Application Load Balancer Component

A production-ready Application Load Balancer component with target groups, health checks, and comprehensive monitoring.

## Features

- **Load Balancing**: Application Load Balancer with multi-AZ deployment
- **Target Groups**: Automatic target group creation with health checks
- **HTTPS Support**: SSL/TLS termination with certificate management
- **Health Checks**: Configurable health check endpoints and parameters
- **Security**: Security groups integration and SSL enforcement
- **Monitoring**: CloudWatch alarms for response time, errors, and unhealthy hosts
- **Access Logging**: Optional S3 access logging

## Usage

### Basic Web Application Load Balancer

```ruby
# Create VPC and subnets first
vpc = aws_vpc(:main, { cidr_block: "10.0.0.0/16" })
public_subnet_1 = aws_subnet(:public_1, { 
  vpc_id: vpc.id, 
  cidr_block: "10.0.1.0/24",
  availability_zone: "us-east-1a"
})
public_subnet_2 = aws_subnet(:public_2, { 
  vpc_id: vpc.id, 
  cidr_block: "10.0.2.0/24",
  availability_zone: "us-east-1b" 
})

# Create security group
web_sg = aws_security_group(:web, {
  name: "web-alb-sg",
  description: "Security group for web ALB",
  vpc_id: vpc.id,
  ingress: [
    { from_port: 80, to_port: 80, protocol: "tcp", cidr_blocks: ["0.0.0.0/0"] },
    { from_port: 443, to_port: 443, protocol: "tcp", cidr_blocks: ["0.0.0.0/0"] }
  ]
})

# Create Application Load Balancer
alb = application_load_balancer(:web_alb, {
  vpc_ref: vpc,
  subnet_refs: [public_subnet_1, public_subnet_2],
  security_group_refs: [web_sg],
  scheme: "internet-facing",
  
  # Enable HTTPS with certificate
  enable_https: true,
  certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
  ssl_redirect: true,
  
  # Custom target groups
  target_groups: [{
    name: "api",
    port: 8080,
    protocol: "HTTP",
    health_check: {
      path: "/health",
      healthy_threshold: 2,
      unhealthy_threshold: 3,
      timeout: 5,
      interval: 30,
      matcher: "200"
    }
  }],
  
  # Multiple listeners
  listeners: [
    { port: 80, protocol: "HTTP", default_action_type: "redirect" },
    { port: 443, protocol: "HTTPS", default_action_type: "forward" }
  ],
  
  tags: {
    Environment: "production",
    Application: "web-app"
  }
})
```

### Advanced Configuration with Multiple Target Groups

```ruby
advanced_alb = application_load_balancer(:advanced_alb, {
  vpc_ref: vpc,
  subnet_refs: [public_subnet_1, public_subnet_2],
  security_group_refs: [web_sg],
  
  # Advanced settings
  idle_timeout: 300,
  enable_deletion_protection: true,
  enable_cross_zone_load_balancing: true,
  
  # Multiple target groups for microservices
  target_groups: [
    {
      name: "api",
      port: 8080,
      protocol: "HTTP",
      target_type: "instance",
      deregistration_delay: 60,
      health_check: {
        path: "/api/health",
        healthy_threshold: 2,
        interval: 15,
        timeout: 10
      }
    },
    {
      name: "admin",
      port: 9000,
      protocol: "HTTP",
      target_type: "ip",
      stickiness_enabled: true,
      stickiness_duration: 86400,
      health_check: {
        path: "/admin/status",
        matcher: "200,202"
      }
    }
  ],
  
  # Access logging
  enable_access_logs: true,
  access_logs_bucket: "my-alb-logs-bucket",
  access_logs_prefix: "production/alb-logs",
  
  # Security headers
  enable_security_headers: true,
  security_headers: {
    "X-Content-Type-Options" => "nosniff",
    "X-Frame-Options" => "SAMEORIGIN",
    "Strict-Transport-Security" => "max-age=63072000"
  }
})
```

### Internal Load Balancer

```ruby
internal_alb = application_load_balancer(:internal_alb, {
  vpc_ref: vpc,
  subnet_refs: [private_subnet_1, private_subnet_2],
  security_group_refs: [internal_sg],
  scheme: "internal",
  
  # Internal service configuration
  create_default_target_group: true,
  default_target_group_port: 3000,
  default_target_group_protocol: "HTTP",
  
  listeners: [{
    port: 3000,
    protocol: "HTTP",
    default_action_type: "forward"
  }],
  
  tags: {
    Environment: "production",
    Tier: "internal"
  }
})
```

## Component Outputs

The component returns a `ComponentReference` with the following outputs:

```ruby
alb.outputs[:alb_arn]                    # ARN of the load balancer
alb.outputs[:alb_dns_name]               # DNS name for the load balancer
alb.outputs[:alb_zone_id]                # Route 53 hosted zone ID
alb.outputs[:target_group_arns]          # Hash of target group ARNs
alb.outputs[:listener_arns]              # Hash of listener ARNs
alb.outputs[:security_features]          # Array of enabled security features
alb.outputs[:health_check_paths]         # Health check endpoints
alb.outputs[:estimated_monthly_cost]     # Estimated monthly cost
```

## Security Features

- **HTTPS/TLS Termination**: SSL certificate integration with ACM
- **Security Groups**: Network-level access control
- **SSL Policy**: Configurable SSL/TLS security policies
- **HTTP to HTTPS Redirect**: Automatic HTTP traffic redirection
- **Access Logging**: Request logging to S3 for audit trails
- **Security Headers**: OWASP-recommended HTTP security headers

## Monitoring and Alerting

The component automatically creates CloudWatch alarms for:

- **Target Response Time**: Alerts when response time exceeds threshold
- **Unhealthy Hosts**: Monitors target health status
- **HTTP 5xx Errors**: Tracks server error rates
- **Request Count**: Monitors traffic patterns

## Best Practices

1. **Multi-AZ Deployment**: Always deploy across multiple availability zones
2. **Health Checks**: Configure appropriate health check endpoints
3. **SSL/TLS**: Use HTTPS for production workloads
4. **Access Logging**: Enable access logging for security monitoring
5. **Target Group Deregistration**: Set appropriate deregistration delays
6. **Sticky Sessions**: Use sticky sessions only when necessary

## Integration with Other Components

The ALB component works seamlessly with:

- **Auto Scaling Groups**: Automatic target registration
- **Security Groups**: Network access control
- **ACM Certificates**: SSL/TLS certificate management
- **Route 53**: DNS routing and health checks
- **WAF**: Web application firewall integration

## Cost Optimization

- **Cross-Zone Load Balancing**: Enable only if required for your traffic pattern
- **Target Groups**: Minimize the number of target groups to reduce costs
- **Health Check Interval**: Balance between responsiveness and cost
- **Access Logging**: Consider log retention and storage costs