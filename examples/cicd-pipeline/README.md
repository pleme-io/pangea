# CI/CD Pipeline Infrastructure

This example demonstrates a complete CI/CD pipeline infrastructure using AWS Developer Tools (CodeCommit, CodeBuild, CodePipeline, CodeDeploy) with Pangea's template isolation for managing complex deployment workflows.

## Overview

The CI/CD pipeline includes:

- **Source Control**: CodeCommit repositories with branch protection
- **Build Automation**: Multiple CodeBuild projects for different build stages
- **Artifact Management**: S3-based artifact storage with lifecycle policies
- **Container Registry**: ECR for Docker images with automated cleanup
- **Pipeline Orchestration**: CodePipeline with multi-stage workflows
- **Deployment Automation**: CodeDeploy for application deployments
- **Security**: KMS encryption, IAM roles, and security scanning
- **Monitoring**: CloudWatch dashboards, alarms, and notifications

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Developer Workstation                         │
└────────────────────────────┬────────────────────────────────────────┘
                             │ git push
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         CodeCommit                                   │
│                    (Source Repository)                               │
└────────────────────────────┬────────────────────────────────────────┘
                             │ triggers
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       CodePipeline                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │
│  │   Source    │─▶│    Build    │─▶│   Approve   │─▶│   Deploy   │ │
│  │   Stage     │  │   Stage     │  │   (Prod)    │  │   Stage    │ │
│  └─────────────┘  └──────┬──────┘  └─────────────┘  └────────────┘ │
└──────────────────────────┼──────────────────────────────────────────┘
                           │
                ┌──────────┴──────────────────────┐
                │                                 │
    ┌───────────▼────────┐          ┌────────────▼────────┐
    │ Unit Tests         │          │ Security Scan       │
    │ (CodeBuild)        │          │ (CodeBuild)         │
    └────────────────────┘          └─────────────────────┘
                │                                 │
    ┌───────────▼────────┐          ┌────────────▼────────┐
    │ Build & Package    │          │ Container Build     │
    │ (CodeBuild)        │          │ (CodeBuild)         │
    └───────────┬────────┘          └──────────┬──────────┘
                │                               │
                ▼                               ▼
    ┌─────────────────────┐          ┌─────────────────────┐
    │   S3 Artifacts      │          │   ECR Repository    │
    │   (Encrypted)       │          │   (Container Images)│
    └─────────────────────┘          └─────────────────────┘
                │
                ▼
    ┌─────────────────────────────────────────────────────┐
    │                    CodeDeploy                        │
    │              (Application Deployment)                │
    └─────────────────────────────────────────────────────┘
                │
                ▼
    ┌─────────────────────────────────────────────────────┐
    │               Target Infrastructure                  │
    │          (EC2, ECS, Lambda, etc.)                   │
    └─────────────────────────────────────────────────────┘
```

## Templates

### 1. Source and Artifacts (`source_and_artifacts`)

Manages source control and artifact storage:
- CodeCommit repository for source code
- S3 bucket for build artifacts with encryption
- ECR repository for container images
- Lifecycle policies for automated cleanup
- CloudWatch log groups for audit trails

### 2. Build Infrastructure (`build_infrastructure`)

Build and test automation:
- Unit test CodeBuild project
- Security scanning CodeBuild project
- Application build and packaging project
- Container build project with Docker support
- Build caching and optimization
- CloudWatch dashboards for build metrics

### 3. Deployment Pipeline (`deployment_pipeline`)

Pipeline orchestration and deployment:
- Multi-stage CodePipeline configuration
- Environment-specific deployment strategies
- Manual approval gates for production
- CodeDeploy application and deployment groups
- Automated rollback configurations
- Pipeline notifications via SNS

## Deployment

### Prerequisites

1. AWS CLI configured with appropriate credentials
2. S3 buckets created for Terraform state (if using remote backend)
3. IAM permissions for CodeCommit, CodeBuild, CodePipeline, and CodeDeploy

### Initial Setup

```bash
# Deploy source control and artifact management
pangea apply infrastructure.rb --template source_and_artifacts

# Deploy build infrastructure
pangea apply infrastructure.rb --template build_infrastructure

# Deploy the pipeline
pangea apply infrastructure.rb --template deployment_pipeline
```

### Environment-Specific Deployment

```bash
# Development environment (local testing)
pangea apply infrastructure.rb --namespace development

# Shared CI/CD for dev/staging
pangea apply infrastructure.rb --namespace shared

# Production CI/CD infrastructure
pangea apply infrastructure.rb --namespace production --no-auto-approve
```

## Build Specifications

Create these buildspec files in your source repository:

### buildspec-test.yml
```yaml
version: 0.2
phases:
  install:
    runtime-versions:
      nodejs: 18
  pre_build:
    commands:
      - echo Installing dependencies...
      - npm ci
  build:
    commands:
      - echo Running unit tests...
      - npm test
      - echo Running linting...
      - npm run lint
reports:
  test-results:
    files:
      - 'test-results.xml'
    file-format: 'JUNITXML'
```

### buildspec-security.yml
```yaml
version: 0.2
phases:
  install:
    commands:
      - echo Installing security scanning tools...
      - pip install safety bandit
  build:
    commands:
      - echo Running dependency check...
      - safety check
      - echo Running static analysis...
      - bandit -r src/
artifacts:
  files:
    - 'security-report.json'
```

### buildspec-build.yml
```yaml
version: 0.2
phases:
  install:
    runtime-versions:
      nodejs: 18
  pre_build:
    commands:
      - echo Installing dependencies...
      - npm ci
  build:
    commands:
      - echo Building application...
      - npm run build
artifacts:
  files:
    - '**/*'
  exclude-paths:
    - 'node_modules/**/*'
    - '.git/**/*'
```

### buildspec-container.yml
```yaml
version: 0.2
phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $IMAGE_URI
      - IMAGE_TAG=${CODEBUILD_RESOLVED_SOURCE_VERSION}
  build:
    commands:
      - echo Building Docker image...
      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $IMAGE_URI:$IMAGE_TAG
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $IMAGE_URI:latest
  post_build:
    commands:
      - echo Pushing Docker image...
      - docker push $IMAGE_URI:$IMAGE_TAG
      - docker push $IMAGE_URI:latest
      - echo Writing image definitions file...
      - printf '[{"name":"app","imageUri":"%s"}]' $IMAGE_URI:$IMAGE_TAG > imagedefinitions.json
artifacts:
  files:
    - imagedefinitions.json
```

## Pipeline Configuration

### Branch Strategy

- **Development**: Triggers on `develop` branch
- **Staging**: Triggers on `staging` branch
- **Production**: Triggers on `main` branch with manual approval

### Deployment Strategies

- **Development**: All-at-once deployment
- **Staging**: All-at-once deployment
- **Production**: One-at-a-time deployment with health checks

## Monitoring and Alerts

### CloudWatch Dashboards

The build infrastructure creates dashboards monitoring:
- Build execution counts
- Build duration trends
- Success/failure rates
- Resource utilization

### Notifications

Configure SNS topic subscriptions for:
- Build failures
- Pipeline failures
- Deployment failures
- Manual approval requests

```bash
# Subscribe email to build notifications
aws sns subscribe \
  --topic-arn $(pangea output infrastructure.rb --template build_infrastructure | jq -r .build_notifications_topic_arn) \
  --protocol email \
  --notification-endpoint your-email@example.com

# Subscribe to pipeline notifications
aws sns subscribe \
  --topic-arn $(pangea output infrastructure.rb --template deployment_pipeline | jq -r .pipeline_notifications_topic_arn) \
  --protocol email \
  --notification-endpoint your-email@example.com
```

## Security Best Practices

1. **Encryption**: All artifacts encrypted with KMS
2. **Access Control**: Least-privilege IAM roles
3. **Audit Trail**: CloudWatch Logs for all activities
4. **Security Scanning**: Automated security checks in pipeline
5. **Branch Protection**: Restrict direct pushes to main branch

## Cost Optimization

1. **Artifact Lifecycle**: Automatic cleanup of old artifacts
2. **Build Compute**: Right-sized compute environments
3. **ECR Cleanup**: Automatic removal of old container images
4. **Log Retention**: Appropriate retention periods

## Troubleshooting

### Common Issues

1. **Build Failures**
   - Check CloudWatch logs in `/aws/codebuild/`
   - Verify IAM permissions
   - Check buildspec syntax

2. **Pipeline Stuck**
   - Check manual approval stages
   - Verify IAM roles and permissions
   - Check artifact bucket permissions

3. **Deployment Failures**
   - Review CodeDeploy logs
   - Check target instance health
   - Verify deployment scripts

## Extending the Pipeline

### Adding New Build Stages

1. Create new CodeBuild project in `build_infrastructure` template
2. Add corresponding buildspec file
3. Add new action to pipeline in `deployment_pipeline` template

### Adding Environments

1. Create new namespace in `pangea.yaml`
2. Deploy infrastructure to new namespace
3. Configure branch triggers appropriately

## Clean Up

Remove infrastructure in reverse order:

```bash
# Remove pipeline first
pangea destroy infrastructure.rb --template deployment_pipeline

# Remove build infrastructure
pangea destroy infrastructure.rb --template build_infrastructure

# Remove source and artifacts
pangea destroy infrastructure.rb --template source_and_artifacts
```

## Next Steps

1. Customize buildspec files for your application
2. Add integration tests to the pipeline
3. Implement blue/green deployments
4. Add performance testing stage
5. Integrate with external tools (Slack, Jira, etc.)