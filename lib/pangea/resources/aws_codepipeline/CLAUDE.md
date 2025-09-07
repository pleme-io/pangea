# AWS CodePipeline - Technical Design

## Architecture Overview

AWS CodePipeline is the orchestration service that connects all CI/CD components into automated release pipelines. This implementation provides comprehensive pipeline modeling with support for complex workflows, multi-region deployments, and various integration patterns.

## Type System Design

### Pipeline Structure
The type system enforces CodePipeline's hierarchical structure:
- **Pipeline**: Top-level container with stages
- **Stages**: Sequential phases (minimum 2)
- **Actions**: Parallel or sequential operations within stages
- **Artifacts**: Data passed between actions

### Validation Strategy
1. Minimum 2 stages (typically Source + Build/Deploy)
2. At least one Source action required
3. Artifact names must be unique
4. Action names unique across pipeline
5. Artifact flow validation (outputs before inputs)

### Advanced Features
- Cross-region action support
- Parallel action execution with run_order
- Manual approval gates
- Webhook integration
- Variable namespaces for dynamic configuration

## Pipeline Patterns

### Standard CI/CD Pipeline
```ruby
# CodeCommit -> CodeBuild -> CodeDeploy
standard_pipeline = aws_codepipeline(:standard_cicd, {
  name: "standard-app-pipeline",
  role_arn: pipeline_role.arn,
  artifact_store: {
    type: "S3",
    location: artifacts_bucket.bucket,
    encryption_key: {
      id: kms_key.arn,
      type: "KMS"
    }
  },
  stages: [
    {
      name: "Source",
      actions: [{
        name: "SourceCode",
        action_type_id: {
          category: "Source",
          owner: "AWS",
          provider: "CodeCommit",
          version: "1"
        },
        configuration: {
          RepositoryName: repo.repository_name,
          BranchName: "main",
          PollForSourceChanges: "false"  # Use CloudWatch Events
        },
        output_artifacts: ["source_output"],
        namespace: "SourceVariables"
      }]
    },
    {
      name: "Build",
      actions: [{
        name: "BuildApplication",
        action_type_id: {
          category: "Build",
          owner: "AWS",
          provider: "CodeBuild",
          version: "1"
        },
        configuration: {
          ProjectName: build_project.name,
          EnvironmentVariablesOverride: JSON.generate([
            { name: "COMMIT_ID", value: "#{SourceVariables.CommitId}" }
          ])
        },
        input_artifacts: ["source_output"],
        output_artifacts: ["build_output"],
        namespace: "BuildVariables"
      }]
    },
    {
      name: "Deploy",
      actions: [{
        name: "DeployApplication",
        action_type_id: {
          category: "Deploy",
          owner: "AWS",
          provider: "CodeDeploy",
          version: "1"
        },
        configuration: {
          ApplicationName: deploy_app.application_name,
          DeploymentGroupName: deployment_group.deployment_group_name
        },
        input_artifacts: ["build_output"]
      }]
    }
  ]
})
```

### Blue-Green Deployment Pipeline
```ruby
# Pipeline with blue-green deployment and testing
blue_green_pipeline = aws_codepipeline(:blue_green_pipeline, {
  name: "blue-green-deployment",
  role_arn: pipeline_role.arn,
  artifact_store: {
    type: "S3",
    location: artifacts_bucket.bucket
  },
  stages: [
    # Source stage...
    # Build stage...
    {
      name: "DeployToBlue",
      actions: [{
        name: "DeployBlueEnvironment",
        action_type_id: {
          category: "Deploy",
          owner: "AWS",
          provider: "CodeDeploy",
          version: "1"
        },
        configuration: {
          ApplicationName: app.application_name,
          DeploymentGroupName: blue_group.deployment_group_name
        },
        input_artifacts: ["build_output"]
      }]
    },
    {
      name: "TestBlue",
      actions: [{
        name: "IntegrationTests",
        action_type_id: {
          category: "Test",
          owner: "AWS",
          provider: "CodeBuild",
          version: "1"
        },
        configuration: {
          ProjectName: test_project.name,
          EnvironmentVariablesOverride: JSON.generate([
            { name: "TARGET_ENV", value: "blue" }
          ])
        },
        input_artifacts: ["build_output"]
      }]
    },
    {
      name: "SwitchTraffic",
      actions: [{
        name: "ManualApproval",
        action_type_id: {
          category: "Approval",
          owner: "AWS",
          provider: "Manual",
          version: "1"
        },
        configuration: {
          CustomData: "Approve traffic switch from green to blue"
        },
        run_order: 1
      },
      {
        name: "SwitchLoadBalancer",
        action_type_id: {
          category: "Invoke",
          owner: "AWS",
          provider: "Lambda",
          version: "1"
        },
        configuration: {
          FunctionName: traffic_switch_lambda.function_name
        },
        run_order: 2
      }]
    }
  ]
})
```

### Multi-Account Pipeline
```ruby
# Cross-account deployment pipeline
multi_account_pipeline = aws_codepipeline(:cross_account, {
  name: "multi-account-deployment",
  role_arn: pipeline_role.arn,
  artifact_store: {
    type: "S3",
    location: artifacts_bucket.bucket
  },
  stages: [
    # Source and Build stages...
    {
      name: "DeployToDev",
      actions: [{
        name: "DeployDevAccount",
        action_type_id: {
          category: "Deploy",
          owner: "AWS",
          provider: "CloudFormation",
          version: "1"
        },
        configuration: {
          ActionMode: "CREATE_UPDATE",
          StackName: "app-stack-dev",
          TemplatePath: "build_output::template.yaml",
          RoleArn: "arn:aws:iam::${dev_account_id}:role/CloudFormationRole"
        },
        input_artifacts: ["build_output"],
        role_arn: "arn:aws:iam::${dev_account_id}:role/CodePipelineRole"
      }]
    },
    {
      name: "DeployToStaging",
      actions: [{
        name: "DeployStagingAccount",
        action_type_id: {
          category: "Deploy",
          owner: "AWS",
          provider: "CloudFormation",
          version: "1"
        },
        configuration: {
          ActionMode: "CREATE_UPDATE",
          StackName: "app-stack-staging",
          TemplatePath: "build_output::template.yaml",
          RoleArn: "arn:aws:iam::${staging_account_id}:role/CloudFormationRole"
        },
        input_artifacts: ["build_output"],
        role_arn: "arn:aws:iam::${staging_account_id}:role/CodePipelineRole"
      }]
    }
  ]
})
```

### Container Pipeline
```ruby
# Docker build and ECS deployment
container_pipeline = aws_codepipeline(:container_pipeline, {
  name: "container-deployment",
  role_arn: pipeline_role.arn,
  artifact_store: {
    type: "S3",
    location: artifacts_bucket.bucket
  },
  stages: [
    {
      name: "Source",
      actions: [{
        name: "SourceCode",
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
      actions: [
        {
          name: "BuildDockerImage",
          action_type_id: {
            category: "Build",
            owner: "AWS",
            provider: "CodeBuild",
            version: "1"
          },
          configuration: {
            ProjectName: docker_build.name
          },
          input_artifacts: ["source_output"],
          output_artifacts: ["image_definitions"],
          run_order: 1
        },
        {
          name: "SecurityScan",
          action_type_id: {
            category: "Test",
            owner: "AWS",
            provider: "CodeBuild",
            version: "1"
          },
          configuration: {
            ProjectName: security_scan.name
          },
          input_artifacts: ["source_output"],
          run_order: 1
        }
      ]
    },
    {
      name: "Deploy",
      actions: [{
        name: "DeployToECS",
        action_type_id: {
          category: "Deploy",
          owner: "AWS",
          provider: "ECS",
          version: "1"
        },
        configuration: {
          ClusterName: ecs_cluster.name,
          ServiceName: ecs_service.name,
          FileName: "imagedefinitions.json"
        },
        input_artifacts: ["image_definitions"]
      }]
    }
  ]
})
```

## Advanced Patterns

### Feature Branch Pipeline
```ruby
# Dynamic pipeline for feature branches
feature_pipeline = aws_codepipeline(:feature_pipeline, {
  name: "feature-branch-pipeline",
  role_arn: pipeline_role.arn,
  artifact_store: {
    type: "S3",
    location: artifacts_bucket.bucket
  },
  stages: [
    {
      name: "Source",
      actions: [{
        name: "FeatureBranch",
        action_type_id: {
          category: "Source",
          owner: "AWS",
          provider: "CodeCommit",
          version: "1"
        },
        configuration: {
          RepositoryName: repo.repository_name,
          BranchName: "#{branch_name}"  # Dynamic branch
        },
        output_artifacts: ["source_output"]
      }]
    },
    {
      name: "BuildAndTest",
      actions: [
        {
          name: "UnitTests",
          action_type_id: {
            category: "Test",
            owner: "AWS",
            provider: "CodeBuild",
            version: "1"
          },
          configuration: {
            ProjectName: unit_test_project.name
          },
          input_artifacts: ["source_output"],
          run_order: 1
        },
        {
          name: "Build",
          action_type_id: {
            category: "Build",
            owner: "AWS",
            provider: "CodeBuild",
            version: "1"
          },
          configuration: {
            ProjectName: build_project.name
          },
          input_artifacts: ["source_output"],
          output_artifacts: ["build_output"],
          run_order: 2
        }
      ]
    },
    {
      name: "DeployToFeatureEnv",
      actions: [{
        name: "CreateFeatureStack",
        action_type_id: {
          category: "Deploy",
          owner: "AWS",
          provider: "CloudFormation",
          version: "1"
        },
        configuration: {
          ActionMode: "CREATE_UPDATE",
          StackName: "feature-#{branch_name}",
          TemplatePath: "build_output::template.yaml"
        },
        input_artifacts: ["build_output"]
      }]
    }
  ]
})
```

### GitOps Pipeline
```ruby
# GitOps with automated rollback
gitops_pipeline = aws_codepipeline(:gitops_pipeline, {
  name: "gitops-deployment",
  role_arn: pipeline_role.arn,
  artifact_store: {
    type: "S3",
    location: artifacts_bucket.bucket
  },
  stages: [
    {
      name: "Source",
      actions: [{
        name: "ConfigRepo",
        action_type_id: {
          category: "Source",
          owner: "AWS",
          provider: "CodeCommit",
          version: "1"
        },
        configuration: {
          RepositoryName: config_repo.repository_name,
          BranchName: "main"
        },
        output_artifacts: ["config_output"]
      }]
    },
    {
      name: "Validate",
      actions: [{
        name: "ValidateManifests",
        action_type_id: {
          category: "Test",
          owner: "AWS",
          provider: "CodeBuild",
          version: "1"
        },
        configuration: {
          ProjectName: validate_project.name
        },
        input_artifacts: ["config_output"]
      }]
    },
    {
      name: "Deploy",
      actions: [{
        name: "ApplyManifests",
        action_type_id: {
          category: "Invoke",
          owner: "AWS",
          provider: "Lambda",
          version: "1"
        },
        configuration: {
          FunctionName: gitops_sync_lambda.function_name
        },
        input_artifacts: ["config_output"]
      }]
    }
  ]
})
```

## Security Patterns

### Secure Pipeline with Scanning
```ruby
secure_pipeline = aws_codepipeline(:secure_pipeline, {
  name: "security-focused-pipeline",
  role_arn: pipeline_role.arn,
  artifact_store: {
    type: "S3",
    location: artifacts_bucket.bucket,
    encryption_key: {
      id: kms_key.arn,
      type: "KMS"
    }
  },
  stages: [
    # Source stage...
    {
      name: "SecurityScans",
      actions: [
        {
          name: "SAST",
          action_type_id: {
            category: "Test",
            owner: "AWS",
            provider: "CodeBuild",
            version: "1"
          },
          configuration: {
            ProjectName: sast_project.name
          },
          input_artifacts: ["source_output"],
          run_order: 1
        },
        {
          name: "DependencyCheck",
          action_type_id: {
            category: "Test",
            owner: "AWS",
            provider: "CodeBuild",
            version: "1"
          },
          configuration: {
            ProjectName: dependency_scan.name
          },
          input_artifacts: ["source_output"],
          run_order: 1
        },
        {
          name: "ContainerScan",
          action_type_id: {
            category: "Test",
            owner: "AWS",
            provider: "CodeBuild",
            version: "1"
          },
          configuration: {
            ProjectName: container_scan.name
          },
          input_artifacts: ["build_output"],
          run_order: 2
        }
      ]
    }
  ]
})
```

## Anti-Patterns to Avoid

1. **Linear Everything**: Use parallel actions where possible
2. **Missing Encryption**: Always encrypt artifacts
3. **Polling for Changes**: Use CloudWatch Events/webhooks
4. **Hardcoded Values**: Use parameters and namespaces
5. **No Approval Gates**: Add manual approval for production

## Monitoring and Observability

### Pipeline Metrics
- Stage execution time
- Action success/failure rates
- Pipeline execution frequency
- Artifact sizes

### CloudWatch Integration
```ruby
# Pipeline with detailed monitoring
monitored_pipeline = aws_codepipeline(:monitored_pipeline, {
  name: "observable-pipeline",
  role_arn: pipeline_role.arn,
  # ... stages configuration ...
})

# CloudWatch Events rule for pipeline state changes
pipeline_events_rule = aws_cloudwatch_event_rule(:pipeline_events, {
  name: "pipeline-state-changes",
  event_pattern: JSON.generate({
    source: ["aws.codepipeline"],
    detail_type: ["CodePipeline Pipeline Execution State Change"],
    detail: {
      pipeline: [monitored_pipeline.name]
    }
  })
})
```

## Cost Optimization

1. **Artifact Lifecycle**: Set S3 lifecycle policies
2. **Regional Artifacts**: Use regional buckets for multi-region
3. **Build Caching**: Cache dependencies in CodeBuild
4. **Conditional Actions**: Skip unnecessary stages
5. **Resource Cleanup**: Delete temporary resources