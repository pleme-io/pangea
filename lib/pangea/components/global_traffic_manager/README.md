# Global Traffic Manager Component

## Overview

The `global_traffic_manager` component creates intelligent global traffic distribution infrastructure with multiple routing strategies including latency-based, weighted, geo-proximity, and failover routing. It combines AWS Global Accelerator, Route 53, CloudFront, and comprehensive health checking to deliver optimal performance worldwide.

## Features

- **Multiple Traffic Routing Strategies**: Latency, weighted, geo-proximity, geo-location, failover, and multi-value
- **AWS Global Accelerator**: Anycast IPs with automatic failover and TCP optimization
- **CloudFront CDN Integration**: Edge caching with Origin Shield and custom cache behaviors
- **Advanced Health Checking**: Multi-protocol health checks with configurable thresholds
- **Geo-Routing Capabilities**: Country, continent, and subdivision-level routing
- **Security Features**: DDoS protection, WAF integration, geo-blocking, rate limiting
- **Performance Optimization**: TCP optimization, connection draining, flow logs
- **Advanced Deployment Patterns**: Canary deployments, blue-green deployments, traffic dials
- **Comprehensive Observability**: Real-time metrics, synthetic monitoring, distributed tracing

## Usage

```ruby
traffic_manager = global_traffic_manager(:global_traffic, {
  manager_name: "global-app-traffic",
  domain_name: "app.example.com",
  certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/abc",
  
  endpoints: [
    {
      region: "us-east-1",
      endpoint_id: "alb-us-east-1.elb.amazonaws.com",
      endpoint_type: "ALB",
      weight: 100,
      priority: 100,
      enabled: true,
      client_ip_preservation: true
    },
    {
      region: "eu-west-1",
      endpoint_id: "alb-eu-west-1.elb.amazonaws.com",
      endpoint_type: "ALB",
      weight: 80,
      priority: 90,
      enabled: true
    },
    {
      region: "ap-southeast-1",
      endpoint_id: "nlb-ap-southeast-1.elb.amazonaws.com",
      endpoint_type: "NLB",
      weight: 60,
      priority: 80,
      enabled: true
    }
  ],
  
  default_policy: "latency",
  
  traffic_policies: [
    {
      policy_name: "primary",
      policy_type: "latency",
      health_check_interval: 30,
      health_check_path: "/api/health",
      health_check_protocol: "HTTPS",
      unhealthy_threshold: 3,
      healthy_threshold: 2
    }
  ],
  
  geo_routing: {
    enabled: true,
    location_rules: [
      { location: "EU", endpoint_region: "eu-west-1" },
      { location: "AS", endpoint_region: "ap-southeast-1" },
      { location: "US-CA", endpoint_region: "us-west-2" }
    ],
    bias_adjustments: {
      "us-east-1": -50,
      "eu-west-1": 25
    }
  },
  
  performance: {
    tcp_optimization: true,
    flow_logs_enabled: true,
    flow_logs_s3_bucket: "my-traffic-logs-bucket",
    connection_draining_timeout: 30
  },
  
  advanced_routing: {
    canary_deployment: {
      percentage: 10,
      endpoint: "canary.example.com",
      stable_endpoint: "stable.example.com"
    },
    traffic_dials: {
      "us-east-1": 100,
      "eu-west-1": 75,
      "ap-southeast-1": 50
    }
  },
  
  observability: {
    cloudwatch_enabled: true,
    detailed_metrics: true,
    synthetic_checks: [
      {
        type: "availability",
        schedule: "rate(5 minutes)",
        timeout: 60
      }
    ],
    alerting_enabled: true
  },
  
  security: {
    ddos_protection: true,
    waf_enabled: true,
    blocked_countries: ["XX", "YY"],
    rate_limiting: {
      limit: 2000,
      key_type: "IP"
    }
  },
  
  cloudfront: {
    enabled: true,
    price_class: "PriceClass_200",
    origin_shield_enabled: true,
    origin_shield_region: "us-east-1",
    cache_behaviors: [
      {
        path_pattern: "/api/*",
        origin_id: "origin-us-east-1",
        viewer_protocol_policy: "https-only",
        allowed_methods: ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"],
        default_ttl: 0,
        max_ttl: 0
      }
    ]
  }
})
```

## Configuration Options

### Core Configuration

- `manager_name` (required): Name for the traffic manager
- `domain_name` (required): Domain name for traffic routing
- `certificate_arn`: ACM certificate ARN for HTTPS
- `endpoints` (required): Array of endpoint configurations

### Endpoint Configuration

Each endpoint supports:

- `region`: AWS region of the endpoint
- `endpoint_id`: DNS name or IP of the endpoint
- `endpoint_type`: "ALB", "NLB", "INSTANCE", "EIP", or "EC2"
- `weight`: Weight for weighted routing (default: 100)
- `priority`: Priority for failover scenarios (default: 100)
- `enabled`: Whether endpoint is active (default: true)
- `health_check_enabled`: Enable health checks (default: true)
- `client_ip_preservation`: Preserve client IP (default: false)
- `metadata`: Additional endpoint metadata

### Traffic Policy Configuration

- `policy_name`: Name of the traffic policy
- `policy_type`: "latency", "weighted", "geoproximity", "geolocation", "failover", or "multivalue"
- `health_check_interval`: Health check interval in seconds (10-300)
- `health_check_path`: Path for HTTP/HTTPS health checks
- `health_check_protocol`: "HTTP", "HTTPS", or "TCP"
- `unhealthy_threshold`: Failed checks before unhealthy (2-10)
- `healthy_threshold`: Successful checks before healthy (2-10)
- `health_check_timeout`: Timeout for health checks

### Geo-Routing Configuration

- `enabled`: Enable geographic routing
- `default_location`: Default location for unmatched requests
- `location_rules`: Array of location to endpoint mappings
- `bias_adjustments`: Bias values for geoproximity routing
- `continent_mapping`: Custom continent mappings

### Performance Configuration

- `tcp_optimization`: Enable TCP optimization
- `flow_logs_enabled`: Enable flow logs
- `flow_logs_s3_bucket`: S3 bucket for flow logs
- `flow_logs_s3_prefix`: S3 prefix for logs
- `connection_draining_timeout`: Connection drain timeout (0-3600)
- `idle_timeout`: Idle connection timeout

### Advanced Routing Configuration

- `weighted_distribution`: Custom weight distribution
- `canary_deployment`: Canary deployment settings
- `blue_green_deployment`: Blue-green deployment config
- `traffic_dials`: Regional traffic percentage controls
- `custom_headers`: Custom headers to add
- `request_routing_rules`: Request-based routing rules

### Observability Configuration

- `cloudwatch_enabled`: Enable CloudWatch metrics
- `detailed_metrics`: Enable detailed metrics
- `access_logs_enabled`: Enable access logging
- `distributed_tracing`: Enable X-Ray tracing
- `real_user_monitoring`: Enable RUM
- `synthetic_checks`: Synthetic monitoring configuration
- `alerting_enabled`: Enable CloudWatch alarms
- `notification_topic_ref`: SNS topic for alerts

### Security Configuration

- `ddos_protection`: Enable AWS Shield Advanced
- `waf_enabled`: Enable AWS WAF
- `waf_acl_ref`: Reference to existing WAF ACL
- `allowed_countries`: Country allowlist
- `blocked_countries`: Country blocklist
- `rate_limiting`: Rate limiting configuration
- `ip_allowlist`: IP address allowlist
- `ip_blocklist`: IP address blocklist

### CloudFront Configuration

- `enabled`: Enable CloudFront distribution
- `price_class`: "PriceClass_All", "PriceClass_200", or "PriceClass_100"
- `cache_behaviors`: Custom cache behaviors
- `origin_shield_enabled`: Enable Origin Shield
- `origin_shield_region`: Origin Shield region
- `compress`: Enable compression
- `viewer_protocol_policy`: Viewer protocol policy
- `custom_error_responses`: Custom error page configuration

## Outputs

The component returns:

- `manager_name`: Traffic manager name
- `domain_name`: Configured domain
- `hosted_zone_id`: Route 53 zone ID
- `endpoints`: Configured endpoints with status
- `global_accelerator_dns`: Global Accelerator DNS name
- `global_accelerator_ips`: Anycast IP addresses
- `cloudfront_distribution_id`: CloudFront distribution ID
- `cloudfront_domain_name`: CloudFront domain
- `routing_strategies`: Active routing strategies
- `health_check_status`: Health check configuration
- `security_features`: Enabled security features
- `observability_features`: Monitoring capabilities
- `performance_optimizations`: Performance features
- `estimated_monthly_cost`: Cost estimate

## Routing Strategy Examples

### Latency-Based Routing

```ruby
default_policy: "latency",
traffic_policies: [{
  policy_type: "latency",
  health_check_enabled: true
}]
```

### Weighted Traffic Distribution

```ruby
default_policy: "weighted",
endpoints: [
  { region: "us-east-1", weight: 70 },
  { region: "eu-west-1", weight: 20 },
  { region: "ap-southeast-1", weight: 10 }
]
```

### Geo-Proximity with Bias

```ruby
default_policy: "geoproximity",
geo_routing: {
  bias_adjustments: {
    "us-east-1": -50,  # Shrink coverage area
    "eu-west-1": 100   # Expand coverage area
  }
}
```

### Canary Deployment

```ruby
advanced_routing: {
  canary_deployment: {
    percentage: 5,
    endpoint: "canary-version.example.com",
    stable_endpoint: "stable.example.com"
  }
}
```

## Best Practices

1. **Endpoint Selection**: Choose appropriate endpoint types (ALB for HTTP/HTTPS, NLB for TCP/UDP)
2. **Health Check Configuration**: Set appropriate intervals and thresholds
3. **Geographic Coverage**: Place endpoints near your users
4. **Caching Strategy**: Configure CloudFront behaviors for optimal caching
5. **Security Layers**: Enable WAF and Shield for production workloads
6. **Monitoring**: Set up alarms for health checks and traffic anomalies
7. **Cost Optimization**: Use appropriate CloudFront price class
8. **Testing**: Test failover scenarios regularly

## Performance Optimization Tips

1. **Global Accelerator**: Use for TCP traffic and gaming applications
2. **CloudFront**: Enable for static content and API acceleration
3. **Origin Shield**: Enable in regions with high traffic
4. **Connection Pooling**: Configure appropriate idle timeouts
5. **TCP Optimization**: Enable for improved throughput
6. **Compression**: Enable for text-based content

## Security Considerations

1. **DDoS Protection**: Shield Advanced provides comprehensive protection
2. **WAF Rules**: Configure rules for your application needs
3. **Geo-Blocking**: Block traffic from unwanted regions
4. **Rate Limiting**: Prevent abuse with appropriate limits
5. **IP Restrictions**: Use allowlists for sensitive endpoints
6. **Certificate Management**: Keep SSL/TLS certificates updated

## Cost Breakdown

Major cost components:

- **Global Accelerator**: $0.025/hour + data processing fees
- **CloudFront**: Data transfer costs vary by region
- **Route 53**: $0.50/hosted zone + $0.50/health check
- **WAF**: $5/web ACL + $1/rule + request fees
- **Shield Advanced**: $3,000/month (optional)
- **Monitoring**: CloudWatch metrics and synthetics

## Troubleshooting

Common issues:

1. **Endpoints Unhealthy**: Check security groups, health check paths
2. **High Latency**: Review routing policies and endpoint placement
3. **Traffic Not Routing**: Verify DNS propagation and health checks
4. **Cost Overruns**: Analyze CloudFront data transfer patterns
5. **Security Blocks**: Check WAF logs and geo-blocking rules