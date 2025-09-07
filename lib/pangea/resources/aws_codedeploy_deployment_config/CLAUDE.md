# AWS CodeDeploy Deployment Configuration - Technical Design

## Architecture Overview

CodeDeploy Deployment Configurations define the rules and pace of deployments across compute platforms. They provide fine-grained control over deployment velocity, failure tolerance, and traffic shifting patterns. This implementation supports all three platforms with their unique configuration requirements.

## Type System Design

### Platform-Specific Configuration
The type system enforces platform-specific rules:
- **Server**: Minimum healthy hosts configuration
- **Lambda/ECS**: Traffic routing configuration
- **Validation**: Platform-appropriate settings only

### Traffic Shifting Abstraction
- **Canary**: Two-phase traffic shift
- **Linear**: Gradual traffic increase
- **All-at-once**: Immediate traffic shift

## Configuration Patterns

### Conservative Production Deployment
```ruby
# EC2: Keep most instances healthy during deployment
prod_ec2_config = aws_codedeploy_deployment_config(:production_safe, {
  deployment_config_name: "Production-KeepMostHealthy",
  compute_platform: "Server",
  minimum_healthy_hosts: {
    type: "FLEET_PERCENT",
    value: 90  # Keep 90% healthy during deployment
  }
})

# Lambda: Slow canary with extended bake time
prod_lambda_config = aws_codedeploy_deployment_config(:production_canary, {
  deployment_config_name: "Production-Canary-5Percent-30Minutes",
  compute_platform: "Lambda",
  traffic_routing_config: {
    type: "TimeBasedCanary",
    time_based_canary: {
      canary_percentage: 5,    # Only 5% initial traffic
      canary_interval: 30      # 30 minute bake time
    }
  }
})
```

### Aggressive Development Deployment
```ruby
# EC2: Fast deployment for development
dev_ec2_config = aws_codedeploy_deployment_config(:dev_fast, {
  deployment_config_name: "Development-FastDeploy",
  compute_platform: "Server",
  minimum_healthy_hosts: {
    type: "FLEET_PERCENT",
    value: 0  # Allow all instances to be updated simultaneously
  }
})

# Lambda: Quick all-at-once for development
dev_lambda_config = aws_codedeploy_deployment_config(:dev_immediate, {
  deployment_config_name: "Development-AllAtOnce",
  compute_platform: "Lambda",
  traffic_routing_config: {
    type: "AllAtOnceTrafficShift"
  }
})
```

### Gradual Rollout Patterns
```ruby
# ECS: Very gradual linear deployment
gradual_ecs = aws_codedeploy_deployment_config(:gradual_rollout, {
  deployment_config_name: "Gradual-Linear-10Percent-Every10Minutes",
  compute_platform: "ECS",
  traffic_routing_config: {
    type: "TimeBasedLinear",
    time_based_linear: {
      linear_percentage: 10,   # 10% traffic increase
      linear_interval: 10      # Every 10 minutes
    }
  }
})

# Lambda: Multi-stage canary
staged_lambda = aws_codedeploy_deployment_config(:staged_canary, {
  deployment_config_name: "Staged-Canary-25Percent-20Minutes",
  compute_platform: "Lambda",
  traffic_routing_config: {
    type: "TimeBasedCanary",
    time_based_canary: {
      canary_percentage: 25,   # 25% initial traffic
      canary_interval: 20      # 20 minute validation
    }
  }
})
```

## Advanced Configuration Strategies

### High Availability Deployment
```ruby
# Ensure service availability during deployment
ha_config = aws_codedeploy_deployment_config(:high_availability, {
  deployment_config_name: "HA-KeepMinimumCapacity",
  compute_platform: "Server",
  minimum_healthy_hosts: {
    type: "HOST_COUNT",
    value: 3  # Always keep at least 3 instances healthy
  }
})

# Use with Auto Scaling Group
deployment_group = aws_codedeploy_deployment_group(:ha_group, {
  app_name: app.application_name,
  deployment_group_name: "ha-deployment",
  service_role_arn: role.arn,
  deployment_config_name: ha_config.deployment_config_name,
  auto_scaling_groups: [asg.name],
  auto_rollback_configuration: {
    enabled: true,
    events: ["DEPLOYMENT_FAILURE"]
  }
})
```

### Blue-Green Specific Configuration
```ruby
# Blue-green with custom configuration
blue_green_config = aws_codedeploy_deployment_config(:blue_green_custom, {
  deployment_config_name: "BlueGreen-Custom",
  compute_platform: "Server",
  minimum_healthy_hosts: {
    type: "FLEET_PERCENT",
    value: 100  # Keep all blue instances healthy until switch
  }
})
```

### Canary Analysis Integration
```ruby
# Canary with CloudWatch alarms
canary_with_analysis = aws_codedeploy_deployment_config(:canary_analyzed, {
  deployment_config_name: "Canary-WithAnalysis-10Percent-15Minutes",
  compute_platform: "Lambda",
  traffic_routing_config: {
    type: "TimeBasedCanary",
    time_based_canary: {
      canary_percentage: 10,
      canary_interval: 15  # Enough time for metric analysis
    }
  }
})

# Deployment group with alarms
canary_group = aws_codedeploy_deployment_group(:canary_group, {
  app_name: lambda_app.application_name,
  deployment_group_name: "canary-with-alarms",
  service_role_arn: role.arn,
  deployment_config_name: canary_with_analysis.deployment_config_name,
  alarm_configuration: {
    alarms: [
      error_rate_alarm.name,
      latency_p99_alarm.name,
      throttle_alarm.name
    ],
    enabled: true
  },
  auto_rollback_configuration: {
    enabled: true,
    events: ["DEPLOYMENT_STOP_ON_ALARM"]
  }
})
```

## Platform-Specific Patterns

### EC2/Server Patterns
```ruby
# Rolling deployment for stateful services
stateful_config = aws_codedeploy_deployment_config(:stateful_rolling, {
  deployment_config_name: "Stateful-OneAtATime",
  compute_platform: "Server",
  minimum_healthy_hosts: {
    type: "HOST_COUNT",
    value: instance_count - 1  # Deploy one at a time
  }
})

# Batch deployment for stateless services
stateless_config = aws_codedeploy_deployment_config(:stateless_batch, {
  deployment_config_name: "Stateless-BatchDeploy",
  compute_platform: "Server",
  minimum_healthy_hosts: {
    type: "FLEET_PERCENT",
    value: 50  # Deploy half at a time
  }
})
```

### Lambda Patterns
```ruby
# A/B testing configuration
ab_test_config = aws_codedeploy_deployment_config(:ab_testing, {
  deployment_config_name: "ABTest-50Percent-60Minutes",
  compute_platform: "Lambda",
  traffic_routing_config: {
    type: "TimeBasedCanary",
    time_based_canary: {
      canary_percentage: 50,   # 50/50 split
      canary_interval: 60      # 1 hour test period
    }
  }
})

# Feature flag deployment
feature_flag_config = aws_codedeploy_deployment_config(:feature_flag, {
  deployment_config_name: "FeatureFlag-Progressive",
  compute_platform: "Lambda",
  traffic_routing_config: {
    type: "TimeBasedLinear",
    time_based_linear: {
      linear_percentage: 20,   # 20% every interval
      linear_interval: 30      # 30 minutes per increment
    }
  }
})
```

### ECS Patterns
```ruby
# Container service gradual rollout
container_gradual = aws_codedeploy_deployment_config(:container_gradual, {
  deployment_config_name: "Container-Gradual-5Percent",
  compute_platform: "ECS",
  traffic_routing_config: {
    type: "TimeBasedLinear",
    time_based_linear: {
      linear_percentage: 5,    # 5% increments
      linear_interval: 5       # Every 5 minutes
    }
  }
})

# Microservice canary deployment
microservice_canary = aws_codedeploy_deployment_config(:microservice_canary, {
  deployment_config_name: "Microservice-Canary-Test",
  compute_platform: "ECS",
  traffic_routing_config: {
    type: "TimeBasedCanary",
    time_based_canary: {
      canary_percentage: 10,
      canary_interval: 10
    }
  }
})
```

## Configuration Selection Strategy

### By Environment
```ruby
def deployment_config_for_environment(env, platform)
  case env
  when :production
    case platform
    when "Server"
      "Custom-Production-KeepMostHealthy"
    when "Lambda"
      "CodeDeployDefault.LambdaCanary10Percent30Minutes"
    when "ECS"
      "CodeDeployDefault.ECSLinear10PercentEvery3Minutes"
    end
  when :staging
    case platform
    when "Server"
      "CodeDeployDefault.HalfAtATime"
    when "Lambda"
      "CodeDeployDefault.LambdaCanary10Percent5Minutes"
    when "ECS"
      "CodeDeployDefault.ECSCanary10Percent5Minutes"
    end
  when :development
    "CodeDeployDefault.AllAtOnce"
  end
end
```

### By Service Criticality
```ruby
def deployment_config_for_criticality(criticality)
  case criticality
  when :critical
    # Very conservative deployment
    aws_codedeploy_deployment_config(:critical_service, {
      deployment_config_name: "Critical-Service-Deployment",
      compute_platform: "Server",
      minimum_healthy_hosts: {
        type: "FLEET_PERCENT",
        value: 95
      }
    })
  when :important
    # Balanced deployment
    aws_codedeploy_deployment_config(:important_service, {
      deployment_config_name: "Important-Service-Deployment",
      compute_platform: "Server",
      minimum_healthy_hosts: {
        type: "FLEET_PERCENT",
        value: 75
      }
    })
  when :standard
    # Standard deployment
    "CodeDeployDefault.OneAtATime"
  end
end
```

## Anti-Patterns to Avoid

1. **Too Fast for Production**: Don't use aggressive configs in prod
2. **Too Slow for Development**: Don't over-engineer dev deployments
3. **Ignoring Platform Limits**: Respect platform-specific constraints
4. **No Bake Time**: Allow time for canary analysis
5. **Fixed Configurations**: Create environment-appropriate configs

## Monitoring Deployment Velocity

### Metrics to Track
- Deployment duration by configuration
- Rollback frequency by configuration
- Success rate by deployment speed
- Alarm triggers during canary period

### Configuration Optimization
```ruby
# Track deployment metrics
cloudwatch_metric(:deployment_duration, {
  namespace: "CodeDeploy",
  metric_name: "DeploymentDuration",
  dimensions: {
    DeploymentConfig: config.deployment_config_name
  }
})
```

## Cost Implications

1. **Longer Deployments**: More instance hours during deployment
2. **Canary Period**: Extended dual-version running
3. **Linear Deployments**: Gradual resource scaling
4. **Rollback Time**: Faster configs = faster rollback
5. **Health Checks**: More frequent with conservative configs