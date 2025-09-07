# AWS Load Balancer Listener Rule Implementation

## Overview

The `aws_lb_listener_rule` resource implements comprehensive AWS Application Load Balancer listener rule management with advanced routing conditions, priority management, and action validation for complex traffic routing scenarios.

## Architecture

### Type System

```ruby
LoadBalancerListenerRuleAttributes < Dry::Struct
  - listener_arn: String (required)
  - priority: Integer (1-50000)
  - action: Array[ActionConfig] (min 1 action, same as listener actions)
  - condition: Array[ConditionConfig] (min 1 condition)
  - tags: AwsTags
```

### Condition Type Support

**Modern Condition Types:**
- `host_header`: Host-based routing (domain/subdomain)
- `path_pattern`: Path-based routing (URL patterns)  
- `http_method`: HTTP method routing (GET, POST, etc.)
- `query_string`: Query parameter routing
- `http_header`: Custom header routing
- `source_ip`: IP-based routing (CIDR blocks)

**Legacy Support:**
- `field` + `values`: Backwards compatibility with old condition format

### Action Type Integration

Listener rules support the same action types as listeners:
- **forward**: Route to target groups (with weighted routing)
- **redirect**: HTTP/HTTPS redirects with customizable components
- **fixed-response**: Return static responses
- **authenticate-cognito**: Cognito User Pool authentication
- **authenticate-oidc**: OpenID Connect authentication

## Routing Engine Architecture

### Priority System

AWS ALB evaluates rules in priority order (lowest number = highest priority):
- **1-99**: Reserved for security and maintenance rules
- **100-999**: Core application routing
- **1000-4999**: Service-specific routing
- **5000-9999**: Catch-all and redirect rules
- **10000+**: Default/fallback rules

### Condition Evaluation Logic

```ruby
# Multiple conditions in single rule = AND logic
{
  condition: [
    { host_header: { values: ["api.example.com"] } },      # AND
    { path_pattern: { values: ["/v2/*"] } }                # Must match both
  ]
}

# Multiple rules = OR logic  
rule_1: { condition: [{ host_header: { values: ["api.example.com"] } }] }    # OR
rule_2: { condition: [{ host_header: { values: ["admin.example.com"] } }] }  # Either matches
```

### Pattern Matching

**Path Patterns:**
- Exact match: `/api/users`
- Wildcard: `/api/*`
- Multi-level: `/api/*/profile`
- Root wildcard: `*`

**Host Patterns:**
- Exact: `api.example.com`
- Wildcard: `*.example.com`
- Multi-subdomain: `*.api.example.com`

## Production Routing Patterns

### Microservices Architecture

```ruby
# Service mesh routing implementation
class MicroservicesRouter
  SERVICES = {
    user_service: { path: "/users/*", priority: 1000 },
    order_service: { path: "/orders/*", priority: 1010 },
    payment_service: { path: "/payments/*", priority: 1020 },
    inventory_service: { path: "/inventory/*", priority: 1030 }
  }.freeze

  def self.create_routing_rules(listener_arn)
    SERVICES.map do |service, config|
      aws_lb_listener_rule(service, {
        listener_arn: listener_arn,
        priority: config[:priority],
        condition: [{
          path_pattern: { values: [config[:path]] }
        }],
        action: [{
          type: "forward",
          target_group_arn: target_group_for(service)
        }],
        tags: {
          Service: service.to_s,
          Type: "microservice-routing"
        }
      })
    end
  end
end
```

### Multi-Tenant Routing

```ruby
# Tenant isolation through routing
tenants = %w[tenant-a tenant-b tenant-c]

tenants.each_with_index do |tenant, index|
  aws_lb_listener_rule(:"#{tenant.tr('-', '_')}_routing", {
    listener_arn: saas_listener.arn,
    priority: 2000 + index,
    condition: [{
      host_header: { values: ["#{tenant}.saas.example.com"] }
    }],
    action: [{
      type: "forward", 
      target_group_arn: tenant_target_groups[tenant].arn
    }],
    tags: {
      Tenant: tenant,
      Type: "tenant-isolation"
    }
  })
end
```

### Canary Deployment Pattern

```ruby
# Progressive traffic shifting for canary deployments
class CanaryDeployment
  def self.create_weighted_rule(listener_arn, canary_weight = 5)
    aws_lb_listener_rule(:canary_deployment, {
      listener_arn: listener_arn,
      priority: 500,
      condition: [{
        path_pattern: { values: ["/api/*"] }
      }],
      action: [{
        type: "forward",
        forward: {
          target_groups: [
            { arn: production_tg.arn, weight: 100 - canary_weight },
            { arn: canary_tg.arn, weight: canary_weight }
          ],
          stickiness: {
            enabled: true,
            duration: 3600  # Sticky sessions for consistent user experience
          }
        }
      }]
    })
  end

  # Gradually increase canary traffic
  def self.shift_traffic(rule_ref, new_canary_weight)
    # Update existing rule with new weights
    # Implementation would update the existing rule
  end
end
```

## Advanced Condition Patterns

### Feature Flag Routing

```ruby
# Route users to beta features based on query parameters
beta_feature_rule = aws_lb_listener_rule(:beta_features, {
  listener_arn: app_listener.arn,
  priority: 300,
  condition: [{
    query_string: {
      values: [
        { key: "beta", value: "true" },
        { key: "feature", value: "new_dashboard" }
      ]
    }
  }],
  action: [{
    type: "forward",
    target_group_arn: beta_app_tg.arn
  }]
})
```

### Device-Specific Routing

```ruby
# Mobile traffic routing based on User-Agent
mobile_routing_rule = aws_lb_listener_rule(:mobile_traffic, {
  listener_arn: web_listener.arn,
  priority: 400,
  condition: [{
    http_header: {
      http_header_name: "User-Agent",
      values: [
        "*Mobile*", "*Android*", "*iPhone*", "*iPad*",
        "*BlackBerry*", "*Windows Phone*"
      ]
    }
  }],
  action: [{
    type: "forward",
    target_group_arn: mobile_optimized_tg.arn
  }]
})
```

### Geographic/IP-Based Routing

```ruby
# Internal traffic routing for different behavior
internal_routing_rule = aws_lb_listener_rule(:internal_traffic, {
  listener_arn: api_listener.arn,
  priority: 100,  # High priority for internal routing
  condition: [{
    source_ip: {
      values: [
        "10.0.0.0/8",      # RFC 1918 private networks
        "172.16.0.0/12",   # RFC 1918 private networks  
        "192.168.0.0/16"   # RFC 1918 private networks
      ]
    }
  }],
  action: [{
    type: "forward",
    target_group_arn: internal_api_tg.arn
  }]
})
```

## Authentication and Authorization Patterns

### Progressive Authentication

```ruby
# Different authentication requirements based on path sensitivity
[
  { paths: ["/public/*"], priority: 900, auth: false },
  { paths: ["/user/*"], priority: 800, auth: :basic },
  { paths: ["/admin/*"], priority: 700, auth: :strict }
].each do |route|
  actions = []
  
  if route[:auth]
    actions << {
      type: "authenticate-cognito",
      order: 1,
      authenticate_cognito: {
        user_pool_arn: user_pools[route[:auth]].arn,
        user_pool_client_id: client_ids[route[:auth]],
        user_pool_domain: "auth-#{route[:auth]}.example.com",
        session_timeout: route[:auth] == :strict ? 3600 : 28800
      }
    }
  end

  actions << {
    type: "forward",
    order: 2,
    target_group_arn: route[:auth] ? authenticated_tg.arn : public_tg.arn
  }

  aws_lb_listener_rule(:"#{route[:auth] || 'public'}_routing", {
    listener_arn: app_listener.arn,
    priority: route[:priority],
    condition: [{
      path_pattern: { values: route[:paths] }
    }],
    action: actions
  })
end
```

## Security Patterns

### Security Rule Implementation

```ruby
# Comprehensive security routing rules
class SecurityRules
  BLOCKED_PATHS = [
    "/.env*", "/config/*", "/admin/phpmyadmin*",
    "/wp-admin/*", "/xmlrpc.php", "/.git/*",
    "/server-status", "/server-info"
  ].freeze

  BLOCKED_USER_AGENTS = [
    "*bot*", "*crawler*", "*scraper*", "*scanner*"
  ].freeze

  def self.create_security_rules(listener_arn)
    # Block suspicious paths
    aws_lb_listener_rule(:security_path_block, {
      listener_arn: listener_arn,
      priority: 10,  # Highest priority
      condition: [{
        path_pattern: { values: BLOCKED_PATHS }
      }],
      action: [{
        type: "fixed-response",
        fixed_response: {
          status_code: "403",
          content_type: "application/json",
          message_body: '{"error":"Forbidden","code":"ACCESS_DENIED"}'
        }
      }]
    })

    # Block suspicious user agents
    aws_lb_listener_rule(:security_ua_block, {
      listener_arn: listener_arn,
      priority: 20,
      condition: [{
        http_header: {
          http_header_name: "User-Agent",
          values: BLOCKED_USER_AGENTS
        }
      }],
      action: [{
        type: "fixed-response",
        fixed_response: {
          status_code: "429",
          content_type: "text/plain",
          message_body: "Rate Limited"
        }
      }]
    })
  end
end
```

## Performance Optimization

### Caching Rules

```ruby
# Different caching strategies based on content type
caching_rules = [
  {
    name: :static_assets,
    priority: 1500,
    paths: ["/assets/*", "/static/*", "*.css", "*.js", "*.png", "*.jpg"],
    target: cdn_origin_tg
  },
  {
    name: :api_responses,
    priority: 1600,
    paths: ["/api/*/cache/*"],
    target: cached_api_tg
  }
]

caching_rules.each do |rule|
  aws_lb_listener_rule(rule[:name], {
    listener_arn: web_listener.arn,
    priority: rule[:priority],
    condition: [{
      path_pattern: { values: rule[:paths] }
    }],
    action: [{
      type: "forward",
      target_group_arn: rule[:target].arn
    }],
    tags: {
      CachingStrategy: rule[:name].to_s,
      Type: "performance-optimization"
    }
  })
end
```

## Monitoring and Observability

### Rule-Specific Monitoring

```ruby
# Add monitoring tags for rule performance tracking
monitoring_rule = aws_lb_listener_rule(:api_v2_routing, {
  listener_arn: api_listener.arn,
  priority: 1000,
  condition: [{
    path_pattern: { values: ["/v2/*"] }
  }],
  action: [{
    type: "forward",
    target_group_arn: api_v2_tg.arn
  }],
  tags: {
    Name: "api-v2-routing",
    Version: "v2",
    MonitoringEnabled: "true",
    AlertOnLatency: "high",
    BusinessCritical: "true"
  }
})
```

## Error Handling and Validation

### Comprehensive Validation

```ruby
# The implementation validates:
# - Priority uniqueness within listener
# - Condition completeness (exactly one condition type per condition)  
# - Action completeness (required sub-configurations)
# - AWS resource ARN formats
# - Pattern syntax validity
```

### Error Cases

```ruby
# These configurations will raise validation errors:

# Missing action configuration
invalid_rule = aws_lb_listener_rule(:invalid, {
  listener_arn: listener.arn,
  priority: 100,
  condition: [{ path_pattern: { values: ["/api/*"] } }],
  action: [{ type: "forward" }]  # Missing target_group_arn or forward config
})

# Multiple condition types in single condition  
invalid_condition = aws_lb_listener_rule(:invalid_condition, {
  listener_arn: listener.arn, 
  priority: 200,
  condition: [{
    path_pattern: { values: ["/api/*"] },
    host_header: { values: ["api.example.com"] }  # Cannot have both
  }],
  action: [{ type: "forward", target_group_arn: tg.arn }]
})
```

## Testing Strategies

### Unit Testing

```ruby
describe "aws_lb_listener_rule" do
  it "validates priority ranges" do
    expect {
      aws_lb_listener_rule(:test, {
        priority: 50001,  # Outside valid range
        # ... other attributes
      })
    }.to raise_error(/priority must be.*50000/)
  end

  it "requires complete action configuration" do
    expect {
      aws_lb_listener_rule(:test, {
        action: [{ type: "redirect" }]  # Missing redirect config
      })
    }.to raise_error(/redirect action requires redirect configuration/)
  end
end
```

### Integration Testing

```ruby
# Test complete routing scenario
routing_test = aws_lb_listener_rule(:integration_test, {
  listener_arn: test_listener.arn,
  priority: 100,
  condition: [
    { host_header: { values: ["test.example.com"] } },
    { path_pattern: { values: ["/api/v2/*"] } }
  ],
  action: [{
    type: "forward",
    forward: {
      target_groups: [
        { arn: test_tg_1.arn, weight: 50 },
        { arn: test_tg_2.arn, weight: 50 }
      ]
    }
  }]
})
```

This implementation provides production-ready AWS Application Load Balancer listener rule management with comprehensive routing capabilities, security controls, and validation for complex enterprise traffic routing scenarios.