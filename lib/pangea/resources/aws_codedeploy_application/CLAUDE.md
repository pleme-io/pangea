# AWS CodeDeploy Application - Technical Design

## Architecture Overview

AWS CodeDeploy Application serves as the top-level container for organizing deployments. Each application is bound to a specific compute platform (EC2/Server, Lambda, or ECS) and contains deployment groups that define the deployment targets and configurations.

## Type System Design

### Platform Abstraction
The type system abstracts the three supported platforms:
- **Server**: Traditional EC2 instances and on-premises servers
- **Lambda**: Serverless function deployments
- **ECS**: Container service deployments

### Validation Strategy
1. Application names must be alphanumeric with dots, dashes, underscores
2. No spaces allowed in application names
3. Compute platform is immutable after creation
4. Platform determines available deployment strategies

## Platform-Specific Patterns

### EC2/Server Deployments
```ruby
# Application for EC2 fleet
web_app = aws_codedeploy_application(:web_app, {
  application_name: "production-web-app",
  compute_platform: "Server"
})

# Associated deployment group for blue-green
blue_green_group = aws_codedeploy_deployment_group(:blue_green, {
  app_name: web_app.application_name,
  deployment_group_name: "blue-green-web",
  service_role_arn: deploy_role.arn,
  deployment_config_name: "CodeDeployDefault.AllAtOnceBlueGreen",
  blue_green_deployment_config: {
    terminate_blue_instances_on_deployment_success: {
      action: "TERMINATE",
      termination_wait_time_in_minutes: 5
    },
    deployment_ready_option: {
      action_on_timeout: "CONTINUE_DEPLOYMENT"
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
  auto_scaling_groups: [asg.name]
})
```

### Lambda Deployments
```ruby
# Application for Lambda functions
lambda_app = aws_codedeploy_application(:lambda_app, {
  application_name: "serverless-api",
  compute_platform: "Lambda"
})

# Canary deployment group
canary_group = aws_codedeploy_deployment_group(:canary, {
  app_name: lambda_app.application_name,
  deployment_group_name: "canary-10-percent",
  service_role_arn: deploy_role.arn,
  deployment_config_name: "CodeDeployDefault.LambdaCanary10Percent5Minutes",
  auto_rollback_configuration: {
    enabled: true,
    events: ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  },
  alarm_configuration: {
    alarms: [error_rate_alarm.name],
    enabled: true
  }
})
```

### ECS Deployments
```ruby
# Application for ECS services
ecs_app = aws_codedeploy_application(:ecs_app, {
  application_name: "container-services",
  compute_platform: "ECS"
})

# Blue-green ECS deployment
ecs_deployment_group = aws_codedeploy_deployment_group(:ecs_blue_green, {
  app_name: ecs_app.application_name,
  deployment_group_name: "ecs-blue-green",
  service_role_arn: deploy_role.arn,
  deployment_config_name: "CodeDeployDefault.ECSAllAtOnce",
  ecs_service: {
    cluster_name: ecs_cluster.name,
    service_name: ecs_service.name
  },
  blue_green_deployment_config: {
    terminate_blue_instances_on_deployment_success: {
      action: "TERMINATE",
      termination_wait_time_in_minutes: 5
    },
    deployment_ready_option: {
      action_on_timeout: "CONTINUE_DEPLOYMENT"
    }
  },
  load_balancer_info: {
    target_group_pair_info: [{
      prod_traffic_route: {
        listener_arns: [prod_listener.arn]
      },
      test_traffic_route: {
        listener_arns: [test_listener.arn]
      },
      target_groups: [
        { name: blue_target_group.name },
        { name: green_target_group.name }
      ]
    }]
  }
})
```

## Deployment Strategy Patterns

### In-Place Deployment (EC2 Only)
Updates existing instances without provisioning new infrastructure:
```ruby
in_place_group = aws_codedeploy_deployment_group(:in_place, {
  app_name: web_app.application_name,
  deployment_group_name: "in-place-update",
  service_role_arn: deploy_role.arn,
  deployment_config_name: "CodeDeployDefault.OneAtATime",
  ec2_tag_filters: [{
    type: "KEY_AND_VALUE",
    key: "Environment",
    value: "Production"
  }]
})
```

### Blue-Green Deployment
Provisions new infrastructure before switching traffic:
```ruby
# EC2 Blue-Green
ec2_blue_green = aws_codedeploy_deployment_group(:ec2_bg, {
  app_name: web_app.application_name,
  deployment_group_name: "blue-green-ec2",
  service_role_arn: deploy_role.arn,
  deployment_config_name: "CodeDeployDefault.AllAtOnceBlueGreen",
  blue_green_deployment_config: {
    terminate_blue_instances_on_deployment_success: {
      action: "KEEP_ALIVE"  # Keep for rollback capability
    },
    green_fleet_provisioning_option: {
      action: "DISCOVER_EXISTING"  # Use pre-provisioned instances
    }
  }
})
```

### Canary Deployment (Lambda)
Gradually shifts traffic to new version:
```ruby
canary_deployment = aws_codedeploy_deployment_group(:canary, {
  app_name: lambda_app.application_name,
  deployment_group_name: "canary-deployment",
  service_role_arn: deploy_role.arn,
  deployment_config_name: "CodeDeployDefault.LambdaCanary10Percent30Minutes"
})
```

### Linear Deployment (Lambda)
Shifts traffic linearly over time:
```ruby
linear_deployment = aws_codedeploy_deployment_group(:linear, {
  app_name: lambda_app.application_name,
  deployment_group_name: "linear-deployment",
  service_role_arn: deploy_role.arn,
  deployment_config_name: "CodeDeployDefault.LambdaLinear10PercentEvery10Minutes"
})
```

## Integration with CI/CD Pipeline

### Complete Pipeline Pattern
```ruby
# CodeCommit -> CodeBuild -> CodeDeploy
repo = aws_codecommit_repository(:app_repo, {
  repository_name: "my-app"
})

build = aws_codebuild_project(:app_build, {
  name: "my-app-build",
  service_role: build_role.arn,
  source: {
    type: "CODECOMMIT",
    location: repo.clone_url_http
  },
  artifacts: {
    type: "S3",
    location: artifact_bucket.bucket
  }
})

deploy_app = aws_codedeploy_application(:app_deploy, {
  application_name: "my-app",
  compute_platform: "Server"
})

pipeline = aws_codepipeline(:app_pipeline, {
  name: "my-app-pipeline",
  role_arn: pipeline_role.arn,
  stages: [
    {
      name: "Source",
      actions: [{
        name: "SourceAction",
        action_type_id: {
          category: "Source",
          owner: "AWS",
          provider: "CodeCommit",
          version: "1"
        },
        configuration: {
          RepositoryName: repo.repository_name,
          BranchName: "main"
        },
        output_artifacts: ["source_output"]
      }]
    },
    {
      name: "Build",
      actions: [{
        name: "BuildAction",
        action_type_id: {
          category: "Build",
          owner: "AWS",
          provider: "CodeBuild",
          version: "1"
        },
        configuration: {
          ProjectName: build.name
        },
        input_artifacts: ["source_output"],
        output_artifacts: ["build_output"]
      }]
    },
    {
      name: "Deploy",
      actions: [{
        name: "DeployAction",
        action_type_id: {
          category: "Deploy",
          owner: "AWS",
          provider: "CodeDeploy",
          version: "1"
        },
        configuration: {
          ApplicationName: deploy_app.application_name,
          DeploymentGroupName: "production"
        },
        input_artifacts: ["build_output"]
      }]
    }
  ]
})
```

## Anti-Patterns to Avoid

1. **Platform Mismatch**: Don't create deployment groups for wrong platform
2. **Name Conflicts**: Avoid duplicate application names in same region
3. **Missing Service Role**: Ensure deployment groups have proper IAM roles
4. **Incorrect Deployment Config**: Match deployment config to platform
5. **Tag Overlap**: Avoid overlapping EC2 tag filters between groups

## Monitoring and Observability

### CloudWatch Integration
- Deployment metrics automatically sent to CloudWatch
- Custom metrics for application-specific monitoring
- Alarms for automatic rollback triggers

### Event Notifications
- SNS topics for deployment events
- CloudWatch Events for state changes
- Integration with third-party monitoring tools

## Security Considerations

### IAM Roles
- Service role for CodeDeploy operations
- Instance profile for EC2 deployments
- Lambda execution role for function deployments
- Task role for ECS deployments

### Encryption
- S3 artifacts encrypted at rest
- TLS for data in transit
- KMS integration for enhanced security

## Cost Optimization

1. **Right-size Deployment Groups**: Don't over-provision
2. **Cleanup Old Revisions**: Remove unused deployment artifacts
3. **Optimize Deployment Frequency**: Balance speed with cost
4. **Use Deployment Configurations**: Control deployment velocity
5. **Monitor Failed Deployments**: Reduce wasted compute time