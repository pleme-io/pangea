# AWS CodeCommit Repository - Technical Design

## Architecture Overview

AWS CodeCommit is a fully-managed source control service that hosts Git repositories. This resource implementation provides type-safe, validated repository creation with advanced features like triggers, encryption, and branch management.

## Type System Design

### Core Attributes
- **repository_name**: Constrained string with regex validation for allowed characters
- **description**: Optional string with 1000 character limit  
- **default_branch**: Configurable default branch (defaults to 'main' for modern practices)
- **kms_key_id**: Optional KMS key for encryption at rest

### Trigger System
The trigger configuration supports event-driven architectures:
- Lambda function invocation for build/deploy automation
- SNS topic notification for team alerts
- Branch-specific triggers for environment-based workflows
- Multiple event types for granular control

### Validation Rules
1. Repository names must be alphanumeric with dots, dashes, underscores
2. Names cannot start/end with dots or dashes
3. Trigger names must be unique within repository
4. Destination ARNs must be valid AWS ARNs
5. At least one branch required if branches array specified

## Integration Patterns

### CI/CD Pipeline Integration
```ruby
# CodeCommit -> CodeBuild -> CodeDeploy pipeline
repo = aws_codecommit_repository(:app_repo, {
  repository_name: "my-app",
  triggers: [{
    name: "start-build",
    destination_arn: codebuild_trigger_lambda.arn,
    events: ["updateReference"],
    branches: ["main"]
  }]
})

build_project = aws_codebuild_project(:app_build, {
  source: {
    type: "CODECOMMIT",
    location: repo.clone_url_http
  }
})
```

### Multi-Environment Triggers
```ruby
# Different triggers for different environments
aws_codecommit_repository(:multi_env_repo, {
  repository_name: "multi-env-app",
  triggers: [
    {
      name: "dev-deploy",
      destination_arn: dev_pipeline.arn,
      events: ["updateReference"],
      branches: ["develop"]
    },
    {
      name: "staging-deploy",
      destination_arn: staging_pipeline.arn,
      events: ["updateReference"],
      branches: ["staging"]
    },
    {
      name: "prod-deploy",
      destination_arn: prod_pipeline.arn,
      events: ["updateReference"],
      branches: ["main"]
    }
  ]
})
```

### GitOps Pattern
```ruby
# Repository for infrastructure as code
iac_repo = aws_codecommit_repository(:gitops_repo, {
  repository_name: "infrastructure",
  description: "GitOps repository for Kubernetes manifests",
  kms_key_id: kms_key.arn,
  triggers: [{
    name: "sync-cluster",
    destination_arn: flux_sync_lambda.arn,
    events: ["updateReference"],
    branches: ["main"]
  }]
})
```

## Security Considerations

### Encryption
- Data encrypted at rest using AWS-managed or customer-managed KMS keys
- Data encrypted in transit using TLS
- Repository metadata also encrypted

### Access Control
- IAM-based authentication and authorization
- Fine-grained permissions per repository
- Support for cross-account access
- Git credential helper integration

### Audit Trail
- CloudTrail integration for all API calls
- Repository activity logging
- Trigger execution history

## Resource Relationships

### With CodeBuild
CodeCommit repositories serve as source providers for CodeBuild projects, enabling automated builds on code changes.

### With CodePipeline
Acts as a source stage in CodePipeline, triggering pipeline executions on repository events.

### With Lambda
Triggers can invoke Lambda functions for custom workflows like notifications, validations, or deployments.

### With EventBridge
Repository events can be routed through EventBridge for complex event-driven architectures.

## Anti-Patterns to Avoid

1. **Over-triggering**: Don't create triggers for every branch/event combination
2. **Large repositories**: Keep repositories focused and under 2GB for performance
3. **Direct credential storage**: Never store credentials in repository - use Parameter Store or Secrets Manager
4. **Monolithic repositories**: Prefer multiple focused repositories over one large repository

## Computed Properties Explained

- **encrypted**: Indicates if custom KMS encryption is enabled
- **has_triggers**: Quick check for trigger configuration presence
- **trigger_count**: Useful for monitoring and limits
- **trigger_names**: For validation and debugging
- **all_trigger_events**: Understanding repository automation coverage

## Migration Considerations

When migrating from other Git services:
1. Use `git push --mirror` for complete history preservation
2. Update all CI/CD configurations to use new URLs
3. Migrate webhooks to CodeCommit triggers
4. Update developer Git remotes
5. Consider using CodeStar connections for GitHub integration needs