# AWS CodePipeline Webhook - Technical Design

## Architecture Overview

CodePipeline Webhooks provide the critical integration point between external Git repositories and AWS pipelines. They enable event-driven continuous delivery by translating repository events into pipeline executions through secure, authenticated endpoints.

## Type System Design

### Authentication Models
The implementation supports three authentication types:
- **GITHUB_HMAC**: Cryptographic signature validation
- **IP**: Network-based access control
- **UNAUTHENTICATED**: Open endpoint (discouraged)

### Filter System
- JSON path-based event filtering
- Support for exact match or existence checks
- Multiple filters with AND logic
- GitHub webhook payload targeting

## Integration Patterns

### GitHub Push Events
```ruby
# Standard push to main branch
main_webhook = aws_codepipeline_webhook(:main_push, {
  name: "github-main-push",
  target_pipeline: pipeline.name,
  target_action: "SourceAction",
  authentication: "GITHUB_HMAC",
  authentication_configuration: {
    secret_token: github_secret.arn
  },
  filters: [{
    json_path: "$.ref",
    match_equals: "refs/heads/main"
  }]
})

# Multi-branch webhook
multi_branch_webhook = aws_codepipeline_webhook(:multi_branch, {
  name: "github-feature-branches",
  target_pipeline: pipeline.name,
  target_action: "SourceAction",
  authentication: "GITHUB_HMAC",
  authentication_configuration: {
    secret_token: github_secret.arn
  },
  filters: [{
    json_path: "$.ref"  # Any branch push
  }]
})
```

### Pull Request Integration
```ruby
# PR opened/synchronized webhook
pr_webhook = aws_codepipeline_webhook(:pr_validation, {
  name: "pull-request-validation",
  target_pipeline: pr_pipeline.name,
  target_action: "PRSource",
  authentication: "GITHUB_HMAC",
  authentication_configuration: {
    secret_token: github_secret.arn
  },
  filters: [
    {
      json_path: "$.action",
      match_equals: "opened"
    },
    {
      json_path: "$.pull_request.base.ref",
      match_equals: "main"
    }
  ]
})

# PR merged webhook
merge_webhook = aws_codepipeline_webhook(:pr_merged, {
  name: "pull-request-merged",
  target_pipeline: deploy_pipeline.name,
  target_action: "MergeSource",
  authentication: "GITHUB_HMAC",
  authentication_configuration: {
    secret_token: github_secret.arn
  },
  filters: [
    {
      json_path: "$.pull_request.merged",
      match_equals: "true"
    },
    {
      json_path: "$.pull_request.base.ref",
      match_equals: "main"
    }
  ]
})
```

### Tag-Based Deployments
```ruby
# Release tag webhook
release_webhook = aws_codepipeline_webhook(:release_tags, {
  name: "release-tag-deployment",
  target_pipeline: release_pipeline.name,
  target_action: "ReleaseSource",
  authentication: "GITHUB_HMAC",
  authentication_configuration: {
    secret_token: github_secret.arn
  },
  filters: [{
    json_path: "$.ref",
    match_equals: "refs/tags/v*"  # Matches v1.0.0, v2.1.0, etc.
  }]
})

# Semantic versioning webhook
semver_webhook = aws_codepipeline_webhook(:semver_deploy, {
  name: "semantic-version-deployment",
  target_pipeline: production_pipeline.name,
  target_action: "TagSource",
  authentication: "GITHUB_HMAC",
  authentication_configuration: {
    secret_token: github_secret.arn
  },
  filters: [
    {
      json_path: "$.ref"
    },
    {
      json_path: "$.ref",
      match_equals: "refs/tags/v[0-9]+.[0-9]+.[0-9]+$"
    }
  ]
})
```

## Security Patterns

### HMAC Authentication Setup
```ruby
# Create GitHub webhook secret
github_secret = aws_secretsmanager_secret(:github_webhook_secret, {
  name: "github-webhook-hmac-secret",
  description: "HMAC secret for GitHub webhook authentication",
  recovery_window_in_days: 7
})

github_secret_version = aws_secretsmanager_secret_version(:github_webhook_secret_version, {
  secret_id: github_secret.id,
  secret_string: random_password.webhook_secret.result
})

# Webhook with secret rotation support
secure_webhook = aws_codepipeline_webhook(:rotatable_webhook, {
  name: "secure-rotatable-webhook",
  target_pipeline: pipeline.name,
  target_action: "SourceAction",
  authentication: "GITHUB_HMAC",
  authentication_configuration: {
    secret_token: github_secret.arn  # Supports rotation
  },
  filters: [{
    json_path: "$.ref",
    match_equals: "refs/heads/main"
  }]
})
```

### IP Allowlist Pattern
```ruby
# Corporate network webhook
corporate_webhook = aws_codepipeline_webhook(:corporate_trigger, {
  name: "corporate-network-webhook",
  target_pipeline: internal_pipeline.name,
  target_action: "InternalSource",
  authentication: "IP",
  authentication_configuration: {
    allowed_ip_range: "10.0.0.0/8"  # Corporate network
  },
  filters: [{
    json_path: "$.repository.name"
  }]
})

# GitHub Enterprise webhook
ghe_webhook = aws_codepipeline_webhook(:github_enterprise, {
  name: "github-enterprise-webhook",
  target_pipeline: enterprise_pipeline.name,
  target_action: "GHESource",
  authentication: "IP",
  authentication_configuration: {
    allowed_ip_range: "192.168.100.0/24"  # GHE server range
  },
  filters: [{
    json_path: "$.ref"
  }]
})
```

## Advanced Filtering Patterns

### Complex Event Filtering
```ruby
# Deploy only from specific users
user_filtered_webhook = aws_codepipeline_webhook(:trusted_users, {
  name: "trusted-user-deployments",
  target_pipeline: production_pipeline.name,
  target_action: "TrustedSource",
  authentication: "GITHUB_HMAC",
  authentication_configuration: {
    secret_token: github_secret.arn
  },
  filters: [
    {
      json_path: "$.pusher.name",
      match_equals: "release-bot"
    },
    {
      json_path: "$.ref",
      match_equals: "refs/heads/main"
    }
  ]
})

# Skip CI commits
ci_skip_webhook = aws_codepipeline_webhook(:skip_ci, {
  name: "skip-ci-commits",
  target_pipeline: pipeline.name,
  target_action: "SourceAction",
  authentication: "GITHUB_HMAC",
  authentication_configuration: {
    secret_token: github_secret.arn
  },
  filters: [
    {
      json_path: "$.head_commit.message"
      # Note: Cannot do negative matching, handle in pipeline
    },
    {
      json_path: "$.ref",
      match_equals: "refs/heads/main"
    }
  ]
})
```

### Environment-Based Webhooks
```ruby
# Development environment webhook
dev_webhook = aws_codepipeline_webhook(:dev_trigger, {
  name: "development-branch-webhook",
  target_pipeline: dev_pipeline.name,
  target_action: "DevSource",
  authentication: "GITHUB_HMAC",
  authentication_configuration: {
    secret_token: github_secret.arn
  },
  filters: [{
    json_path: "$.ref",
    match_equals: "refs/heads/develop"
  }]
})

# Staging environment webhook
staging_webhook = aws_codepipeline_webhook(:staging_trigger, {
  name: "staging-branch-webhook",
  target_pipeline: staging_pipeline.name,
  target_action: "StagingSource",
  authentication: "GITHUB_HMAC",
  authentication_configuration: {
    secret_token: github_secret.arn
  },
  filters: [{
    json_path: "$.ref",
    match_equals: "refs/heads/staging"
  }]
})

# Production hotfix webhook
hotfix_webhook = aws_codepipeline_webhook(:hotfix_trigger, {
  name: "hotfix-branch-webhook",
  target_pipeline: hotfix_pipeline.name,
  target_action: "HotfixSource",
  authentication: "GITHUB_HMAC",
  authentication_configuration: {
    secret_token: github_secret.arn
  },
  filters: [{
    json_path: "$.ref",
    match_equals: "refs/heads/hotfix/*"
  }]
})
```

## GitHub Repository Configuration

### Automated Setup Pattern
```ruby
# Output webhook configuration for automation
output :github_webhook_config do
  value {
    url: webhook.url,
    content_type: "application/json",
    secret: github_secret.name,
    events: ["push", "pull_request"],
    active: true
  }
end

# Lambda for automatic GitHub webhook configuration
webhook_config_lambda = aws_lambda_function(:configure_github_webhook, {
  function_name: "configure-github-webhooks",
  runtime: "python3.9",
  handler: "index.handler",
  environment: {
    variables: {
      GITHUB_TOKEN_SECRET: github_token.arn,
      WEBHOOK_URL: webhook.url,
      WEBHOOK_SECRET: github_secret.arn
    }
  }
})
```

### Multi-Repository Pattern
```ruby
# Shared webhook for multiple repositories
repositories = ["frontend", "backend", "infrastructure"]

repositories.each do |repo|
  aws_codepipeline_webhook(:"#{repo}_webhook", {
    name: "#{repo}-push-webhook",
    target_pipeline: pipelines[repo].name,
    target_action: "SourceAction",
    authentication: "GITHUB_HMAC",
    authentication_configuration: {
      secret_token: github_secret.arn
    },
    filters: [
      {
        json_path: "$.repository.name",
        match_equals: repo
      },
      {
        json_path: "$.ref",
        match_equals: "refs/heads/main"
      }
    ]
  })
end
```

## Monitoring and Debugging

### Webhook Metrics
```ruby
# CloudWatch alarm for webhook failures
webhook_failure_alarm = aws_cloudwatch_metric_alarm(:webhook_failures, {
  alarm_name: "codepipeline-webhook-failures",
  comparison_operator: "GreaterThanThreshold",
  evaluation_periods: 1,
  metric_name: "WebhookTriggersFailed",
  namespace: "AWS/CodePipeline",
  period: 300,
  statistic: "Sum",
  threshold: 5,
  alarm_description: "Alert on webhook trigger failures"
})

# Custom metric for webhook latency
webhook_latency_metric = aws_cloudwatch_log_metric_filter(:webhook_latency, {
  name: "webhook-processing-latency",
  pattern: "[time, request_id, event_type, latency_ms > 1000]",
  log_group_name: "/aws/codepipeline/webhooks"
})
```

### Debugging Configuration
```ruby
# Webhook with detailed logging
debug_webhook = aws_codepipeline_webhook(:debug_webhook, {
  name: "debug-webhook-events",
  target_pipeline: test_pipeline.name,
  target_action: "TestSource",
  authentication: "GITHUB_HMAC",
  authentication_configuration: {
    secret_token: github_secret.arn
  },
  filters: [{
    json_path: "$"  # Log entire payload
  }],
  tags: {
    Environment: "development",
    Debug: "true"
  }
})
```

## Anti-Patterns to Avoid

1. **No Authentication**: Never use UNAUTHENTICATED in production
2. **Broad Filters**: Avoid triggering on all events
3. **Secret in Code**: Always use Secrets Manager
4. **IP Range Too Broad**: Be specific with IP allowlists
5. **Missing Rotation**: Plan for secret rotation

## Best Practices

### Secret Management
```ruby
# Rotate webhook secrets periodically
resource :aws_secretsmanager_secret_rotation, :webhook_rotation do
  secret_id github_secret.id
  rotation_lambda_arn rotation_lambda.arn
  
  rotation_rules do
    automatically_after_days 30
  end
end
```

### High Availability
```ruby
# Multiple webhooks for redundancy
["primary", "secondary"].each do |tier|
  aws_codepipeline_webhook(:"#{tier}_webhook", {
    name: "github-webhook-#{tier}",
    target_pipeline: pipeline.name,
    target_action: "SourceAction",
    authentication: "GITHUB_HMAC",
    authentication_configuration: {
      secret_token: github_secret.arn
    },
    filters: [{
      json_path: "$.ref",
      match_equals: "refs/heads/main"
    }]
  })
end
```

## Cost Optimization

1. **Filter Early**: Reduce unnecessary pipeline executions
2. **Consolidate Webhooks**: Use filters vs multiple webhooks
3. **Cache Validation**: Avoid duplicate builds
4. **Regional Webhooks**: Use same-region endpoints
5. **Batch Events**: Group related changes when possible