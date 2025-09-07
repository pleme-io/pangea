# AWS CodeDeploy Deployment Group - Technical Design

## Architecture Overview

CodeDeploy Deployment Groups are the core operational units that define how deployments are executed. They specify the target instances, deployment strategy, traffic routing, and rollback behavior. The implementation supports all three compute platforms with their unique deployment patterns.

## Type System Design

### Target Selection Strategy
The type system models multiple target selection methods:
- **Tag-based**: EC2 instances selected by tags
- **Auto Scaling**: Entire Auto Scaling Groups
- **On-premises**: Registered on-premises servers
- **ECS Services**: Container deployments

### Deployment Style Abstraction
- **In-place**: Updates existing instances (EC2 only)
- **Blue-green**: Provisions new infrastructure
- **Traffic-controlled**: Gradual traffic shifting

### Complex Configuration Modeling
- **Blue-green config**: Instance termination, fleet provisioning
- **Load balancer info**: ELB, ALB, or target group pairs
- **Rollback config**: Automatic rollback triggers
- **Alarm integration**: CloudWatch alarm monitoring

## Deployment Patterns

### Blue-Green EC2 Pattern
```ruby
# Complete blue-green setup with ALB
blue_green = aws_codedeploy_deployment_group(:production_bg, {
  app_name: app.application_name,
  deployment_group_name: "prod-blue-green",
  service_role_arn: role.arn,
  deployment_style: {
    deployment_type: "BLUE_GREEN",
    deployment_option: "WITH_TRAFFIC_CONTROL"
  },
  blue_green_deployment_config: {
    terminate_blue_instances_on_deployment_success: {
      action: "KEEP_ALIVE",  # Keep for quick rollback
      termination_wait_time_in_minutes: 60
    },
    deployment_ready_option: {
      action_on_timeout: "STOP_DEPLOYMENT"  # Safety first
    },
    green_fleet_provisioning_option: {
      action: "COPY_AUTO_SCALING_GROUP"
    }
  },
  load_balancer_info: {
    target_group_info: [{
      name: target_group.name
    }]
  },
  auto_scaling_groups: [asg.name],
  auto_rollback_configuration: {
    enabled: true,
    events: ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  },
  alarm_configuration: {
    alarms: [cpu_alarm.name, error_rate_alarm.name],
    enabled: true
  }
})
```

### Canary Deployment Pattern
```ruby
# Lambda canary deployment with validation
canary = aws_codedeploy_deployment_group(:lambda_canary, {
  app_name: lambda_app.application_name,
  deployment_group_name: "canary-deployment",
  service_role_arn: role.arn,
  deployment_config_name: "CodeDeployDefault.LambdaCanary10Percent30Minutes",
  auto_rollback_configuration: {
    enabled: true,
    events: ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  },
  alarm_configuration: {
    alarms: [
      error_rate_alarm.name,
      latency_alarm.name,
      throttle_alarm.name
    ],
    enabled: true
  },
  trigger_configurations: [{
    trigger_name: "deployment-notifications",
    trigger_target_arn: sns_topic.arn,
    trigger_events: [
      "DeploymentStart",
      "DeploymentSuccess",
      "DeploymentFailure",
      "DeploymentRollback"
    ]
  }]
})
```

### Progressive ECS Deployment
```ruby
# ECS linear deployment with test traffic
ecs_progressive = aws_codedeploy_deployment_group(:ecs_linear, {
  app_name: ecs_app.application_name,
  deployment_group_name: "ecs-progressive",
  service_role_arn: role.arn,
  deployment_config_name: "CodeDeployDefault.ECSLinear10PercentEvery3Minutes",
  ecs_service: {
    cluster_name: cluster.name,
    service_name: service.name
  },
  load_balancer_info: {
    target_group_pair_info: [{
      prod_traffic_route: {
        listener_arns: [prod_listener.arn]
      },
      test_traffic_route: {
        listener_arns: [test_listener.arn]  # Separate test endpoint
      },
      target_groups: [
        { name: blue_tg.name },
        { name: green_tg.name }
      ]
    }]
  },
  auto_rollback_configuration: {
    enabled: true,
    events: ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }
})
```

## Advanced Patterns

### Multi-Region Deployment
```ruby
# Regional deployment groups for disaster recovery
regions = ["us-east-1", "us-west-2", "eu-west-1"]

regions.each do |region|
  aws_codedeploy_deployment_group(:"prod_#{region.gsub('-', '_')}", {
    app_name: app.application_name,
    deployment_group_name: "production-#{region}",
    service_role_arn: role.arn,
    ec2_tag_filters: [{
      type: "KEY_AND_VALUE",
      key: "Region",
      value: region
    }],
    deployment_config_name: "CodeDeployDefault.OneAtATime"
  })
end
```

### Environment-Specific Strategies
```ruby
# Different strategies per environment
environments = {
  dev: "CodeDeployDefault.AllAtOnce",
  staging: "CodeDeployDefault.HalfAtATime",
  production: "CodeDeployDefault.OneAtATime"
}

environments.each do |env, config|
  aws_codedeploy_deployment_group(:"#{env}_deployment", {
    app_name: app.application_name,
    deployment_group_name: "#{env}-servers",
    service_role_arn: role.arn,
    deployment_config_name: config,
    ec2_tag_filters: [{
      type: "KEY_AND_VALUE",
      key: "Environment",
      value: env.to_s
    }]
  })
end
```

### Zero-Downtime Database Migration
```ruby
# Blue-green with database migration hooks
db_migration_group = aws_codedeploy_deployment_group(:db_migration, {
  app_name: app.application_name,
  deployment_group_name: "database-migration",
  service_role_arn: role.arn,
  deployment_style: {
    deployment_type: "BLUE_GREEN",
    deployment_option: "WITH_TRAFFIC_CONTROL"
  },
  blue_green_deployment_config: {
    terminate_blue_instances_on_deployment_success: {
      action: "KEEP_ALIVE",  # Keep old version during migration
      termination_wait_time_in_minutes: 1440  # 24 hours
    },
    deployment_ready_option: {
      action_on_timeout: "STOP_DEPLOYMENT"
    }
  },
  load_balancer_info: {
    target_group_info: [{
      name: target_group.name
    }]
  },
  trigger_configurations: [{
    trigger_name: "migration-hooks",
    trigger_target_arn: migration_lambda.arn,
    trigger_events: ["DeploymentReady", "InstanceReady"]
  }]
})
```

## Security Patterns

### Least Privilege Deployment
```ruby
# Minimal permissions deployment group
secure_group = aws_codedeploy_deployment_group(:secure_deployment, {
  app_name: app.application_name,
  deployment_group_name: "least-privilege",
  service_role_arn: minimal_deploy_role.arn,  # Only required permissions
  ec2_tag_filters: [{
    type: "KEY_AND_VALUE",
    key: "SecurityLevel",
    value: "High"
  }],
  deployment_config_name: "CodeDeployDefault.OneAtATime",
  auto_rollback_configuration: {
    enabled: true,
    events: ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_REQUEST"]
  }
})
```

### Compliance-Aware Deployment
```ruby
# Deployment with compliance checks
compliance_group = aws_codedeploy_deployment_group(:compliance, {
  app_name: app.application_name,
  deployment_group_name: "compliance-aware",
  service_role_arn: role.arn,
  ec2_tag_filters: [{
    type: "KEY_AND_VALUE",
    key: "Compliance",
    value: "Required"
  }],
  trigger_configurations: [
    {
      trigger_name: "pre-deployment-scan",
      trigger_target_arn: security_scan_lambda.arn,
      trigger_events: ["DeploymentStart"]
    },
    {
      trigger_name: "post-deployment-validation",
      trigger_target_arn: compliance_check_lambda.arn,
      trigger_events: ["DeploymentSuccess"]
    }
  ]
})
```

## Performance Optimization

### Parallel Deployment Groups
```ruby
# Parallel deployments for microservices
services = ["api", "web", "worker", "admin"]

services.each do |service|
  aws_codedeploy_deployment_group(:"#{service}_deployment", {
    app_name: app.application_name,
    deployment_group_name: "#{service}-servers",
    service_role_arn: role.arn,
    ec2_tag_filters: [{
      type: "KEY_AND_VALUE",
      key: "Service",
      value: service
    }],
    deployment_config_name: "CodeDeployDefault.AllAtOnce"  # Fast per service
  })
end
```

### Staged Rollout
```ruby
# Progressive rollout across availability zones
azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

azs.each_with_index do |az, index|
  aws_codedeploy_deployment_group(:"az_#{az.gsub('-', '_')}", {
    app_name: app.application_name,
    deployment_group_name: "production-#{az}",
    service_role_arn: role.arn,
    ec2_tag_filters: [{
      type: "KEY_AND_VALUE",
      key: "AvailabilityZone",
      value: az
    }],
    deployment_config_name: "CodeDeployDefault.HalfAtATime"
  })
end
```

## Anti-Patterns to Avoid

1. **Over-broad Tag Filters**: Don't select unintended instances
2. **Missing Health Checks**: Always configure proper health validation
3. **Instant Termination**: Keep blue instances for rollback capability
4. **No Alarms**: Deploy without CloudWatch alarm integration
5. **Shared Deployment Groups**: Don't mix different application tiers

## Monitoring and Observability

### Deployment Metrics
- Deployment duration and success rate
- Instance health during deployment
- Traffic shifting metrics
- Rollback frequency and causes

### Custom Metrics
```ruby
trigger_configurations: [{
  trigger_name: "custom-metrics",
  trigger_target_arn: metrics_lambda.arn,
  trigger_events: [
    "DeploymentStart",
    "DeploymentSuccess",
    "DeploymentFailure",
    "InstanceStart",
    "InstanceSuccess"
  ]
}]
```

## Cost Considerations

1. **Instance Termination**: Configure appropriate wait times
2. **Deployment Velocity**: Balance speed with instance hours
3. **Alarm Costs**: Use composite alarms to reduce CloudWatch costs
4. **Regional Deployments**: Consider cross-region data transfer
5. **Build Artifacts**: Clean up old deployment packages