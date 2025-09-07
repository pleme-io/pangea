# AWS ECS Service Implementation

## Overview

The `aws_ecs_service` resource implements comprehensive ECS service management with support for multiple scheduling strategies, deployment configurations, load balancing, service discovery, and the new Service Connect feature.

## Type System Design

### Core Types

#### EcsServiceAttributes
The main service configuration with:
- Service identification (name, cluster, task definition)
- Scheduling configuration (desired count, strategy)
- Launch type and capacity providers
- Network configuration for awsvpc mode
- Load balancing and service discovery
- Deployment configuration with circuit breaker
- Service Connect for service mesh capabilities

#### EcsLoadBalancer
Load balancer attachment configuration:
- Target group ARN validation
- Container name and port mapping
- Supports multiple load balancers per service

#### EcsNetworkConfiguration
Network settings for awsvpc mode:
- Subnet list (minimum 1 required)
- Security groups (optional)
- Public IP assignment control

#### EcsServiceRegistries
Service discovery configuration:
- Registry ARN for Cloud Map
- Port configurations
- Container mapping

#### EcsDeploymentConfiguration
Deployment behavior control:
- Circuit breaker with rollback
- Maximum/minimum healthy percentages
- Safe deployment defaults

#### EcsPlacementConstraint & EcsPlacementStrategy
EC2-specific placement controls:
- Constraint types: distinctInstance, memberOf
- Strategy types: random, spread, binpack
- Expression validation for memberOf

#### EcsCapacityProviderStrategy
Capacity provider configuration:
- Provider selection
- Weight-based distribution
- Base capacity guarantee

### Service Connect Types

Service Connect configuration is deeply nested to support:
- Service-level configuration
- Port mapping and aliases
- Timeout settings
- TLS configuration with AWS Private CA
- Logging configuration

## Key Validation Rules

### Launch Type Validation
- Cannot specify both `launch_type` and `capacity_provider_strategy`
- Platform version only applies to Fargate

### Scheduling Strategy Validation
- DAEMON services cannot have desired_count > 0
- DAEMON services cannot use placement strategies
- REPLICA is the default and most common

### Network Configuration
- Required when using load balancers (implied awsvpc mode)
- Subnet validation for high availability
- Security group configuration

### Health Check Grace Period
- Only valid when using load balancers
- Prevents premature health check failures

### Service Connect Validation
- Requires at least one service configuration when enabled
- Port names must match task definition
- Namespace configuration required

## Helper Methods

### Service Type Detection
```ruby
service.using_fargate?           # Fargate launch type or capacity provider
service.load_balanced?           # Has load balancer configuration
service.service_discovery_enabled? # Has service registry
service.service_connect_enabled?  # Service Connect is configured
```

### Safety Checks
```ruby
service.deployment_safe?  # Circuit breaker enabled with rollback
```

### Cost Estimation
```ruby
service.estimated_monthly_cost  # Rough cost calculation
```

## Resource Synthesis

The implementation handles complex nested structures:

1. **Conditional Blocks** - Only synthesize configured features
2. **Array Iteration** - Multiple load balancers, registries, etc.
3. **Deep Nesting** - Service Connect configuration hierarchy
4. **Launch Type Logic** - Either launch_type or capacity_provider_strategy

## Service Connect Implementation

Service Connect is ECS's service mesh solution. The implementation supports:

### Basic Configuration
```ruby
service_connect_configuration: {
  enabled: true,
  namespace: "arn:aws:servicediscovery:..."
}
```

### Service Configuration
```ruby
services: [{
  port_name: "web",           # From task definition
  discovery_name: "web-api",  # Service discovery name
  client_aliases: [{          # Internal DNS aliases
    port: 80,
    dns_name: "api"
  }]
}]
```

### Advanced Features
- Timeout configuration (idle and per-request)
- TLS with AWS Private Certificate Authority
- Custom logging configuration

## Deployment Strategies

### Rolling Updates (Default)
```ruby
deployment_configuration: {
  maximum_percent: 200,         # Allow 2x capacity during deployment
  minimum_healthy_percent: 100  # Maintain full capacity
}
```

### Blue/Green with CodeDeploy
```ruby
deployment_controller: {
  type: "CODE_DEPLOY"
}
```

### Circuit Breaker
```ruby
deployment_circuit_breaker: {
  enable: true,   # Stop bad deployments
  rollback: true  # Automatic rollback
}
```

## Capacity Provider Strategies

The implementation supports complex capacity provider configurations:

```ruby
capacity_provider_strategy: [
  { capacity_provider: "FARGATE_SPOT", weight: 4, base: 0 },
  { capacity_provider: "FARGATE", weight: 1, base: 1 }
]
```

This creates:
- 80% of tasks on FARGATE_SPOT (weight 4/5)
- 20% on FARGATE (weight 1/5)
- At least 1 task on FARGATE (base: 1)

## Placement Strategies (EC2)

For EC2 launch type, supports:

### Spread Strategy
```ruby
placement_strategy: [
  { type: "spread", field: "instanceId" }  # Distribute across instances
]
```

### Binpack Strategy
```ruby
placement_strategy: [
  { type: "binpack", field: "memory" }  # Pack by memory utilization
]
```

### Combined Strategies
```ruby
placement_strategy: [
  { type: "spread", field: "attribute:ecs.availability-zone" },
  { type: "binpack", field: "cpu" }
]
```

## Integration Patterns

### With Auto Scaling
Services integrate with Application Auto Scaling for dynamic scaling based on metrics.

### With Load Balancers
Multiple load balancer support for complex routing scenarios.

### With Service Discovery
Cloud Map integration for internal service communication.

### With CloudWatch
Metrics and logs integration for monitoring.

## Design Decisions

1. **Separate Type Classes** - Each configuration aspect has its own type for reusability
2. **Deep Validation** - Catch configuration errors early
3. **Smart Defaults** - Production-ready defaults (circuit breaker disabled by default for backward compatibility)
4. **Helper Methods** - Simplify common checks and calculations
5. **Service Connect Focus** - First-class support for AWS's service mesh solution

## Testing Considerations

Key test scenarios:
1. Launch type and capacity provider mutual exclusion
2. DAEMON scheduling strategy restrictions
3. Network configuration requirements
4. Service Connect configuration validation
5. Deployment configuration defaults
6. Cost calculation accuracy

## Future Enhancements

Potential improvements:
1. Auto-generate network configuration from task definition
2. Service Connect configuration helpers
3. Deployment strategy templates
4. Auto scaling policy integration
5. Cross-service dependency management
6. Traffic shifting configuration for blue/green