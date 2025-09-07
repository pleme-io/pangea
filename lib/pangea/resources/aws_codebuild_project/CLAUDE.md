# AWS CodeBuild Project - Technical Design

## Architecture Overview

AWS CodeBuild is a fully managed continuous integration service that compiles source code, runs tests, and produces software packages. This resource implementation provides comprehensive build project configuration with support for various source providers, build environments, and deployment patterns.

## Type System Design

### Core Architecture
The type system models CodeBuild's flexible build configuration:
- **Source Configuration**: Supports multiple source providers with provider-specific options
- **Build Environment**: Container-based builds with customizable compute resources
- **Artifacts Management**: Flexible output handling for build results
- **Security Integration**: VPC support, IAM roles, and secrets management

### Advanced Features
- **Secondary Sources**: Multiple source inputs for complex builds
- **Secondary Artifacts**: Multiple output destinations
- **Build Caching**: S3 or local caching for performance
- **Batch Builds**: Matrix builds and parallel execution
- **File System Mounts**: EFS integration for shared storage

### Validation Strategy
1. Source location required for non-CodePipeline sources
2. Artifact location required for S3 artifacts
3. VPC configuration requires subnets and security groups
4. Cache configuration validates based on type
5. Environment variables must have unique names

## Integration Patterns

### CI/CD Pipeline Integration
```ruby
# Complete CI/CD with CodeCommit -> CodeBuild -> CodeDeploy
repo = aws_codecommit_repository(:app_repo, {
  repository_name: "my-app"
})

build = aws_codebuild_project(:app_build, {
  name: "my-app-build",
  service_role: build_role.arn,
  source: {
    type: "CODECOMMIT",
    location: repo.clone_url_http,
    buildspec: "buildspec.yml"
  },
  artifacts: {
    type: "S3",
    location: artifact_bucket.bucket,
    name: "my-app-${CODEBUILD_BUILD_NUMBER}.zip"
  },
  environment: {
    type: "LINUX_CONTAINER",
    image: "aws/codebuild/standard:5.0",
    compute_type: "BUILD_GENERAL1_MEDIUM"
  }
})

deploy_app = aws_codedeploy_application(:app_deploy, {
  application_name: "my-app",
  compute_platform: "Server"
})
```

### Multi-Stage Build Pattern
```ruby
# Build with multiple stages and caching
multi_stage_build = aws_codebuild_project(:multi_stage, {
  name: "multi-stage-build",
  service_role: build_role.arn,
  source: {
    type: "GITHUB",
    location: "https://github.com/org/repo.git"
  },
  secondary_sources: [
    {
      source_identifier: "config",
      type: "S3",
      location: "${config_bucket.bucket}/build-config"
    }
  ],
  artifacts: {
    type: "S3",
    location: artifact_bucket.bucket,
    name: "app-bundle"
  },
  secondary_artifacts: [
    {
      artifact_identifier: "test-reports",
      type: "S3",
      location: reports_bucket.bucket,
      name: "test-reports"
    }
  ],
  environment: {
    type: "LINUX_CONTAINER",
    image: "aws/codebuild/standard:5.0",
    compute_type: "BUILD_GENERAL1_LARGE"
  },
  cache: {
    type: "LOCAL",
    modes: ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }
})
```

### Container Image Build
```ruby
# Docker image build and push to ECR
docker_build = aws_codebuild_project(:docker_build, {
  name: "docker-image-build",
  service_role: build_role.arn,
  source: {
    type: "CODECOMMIT",
    location: repo.clone_url_http
  },
  artifacts: {
    type: "NO_ARTIFACTS"
  },
  environment: {
    type: "LINUX_CONTAINER",
    image: "aws/codebuild/standard:5.0",
    compute_type: "BUILD_GENERAL1_MEDIUM",
    privileged_mode: true,  # Required for Docker
    environment_variables: [
      { name: "AWS_DEFAULT_REGION", value: "us-east-1" },
      { name: "AWS_ACCOUNT_ID", value: "123456789012" },
      { name: "IMAGE_REPO_NAME", value: "my-app" },
      { name: "IMAGE_TAG", value: "latest" }
    ]
  }
})
```

## Security Patterns

### Secrets Management
```ruby
secure_build = aws_codebuild_project(:secure_build, {
  name: "secure-app-build",
  service_role: build_role.arn,
  source: {
    type: "CODECOMMIT",
    location: repo.clone_url_http
  },
  artifacts: {
    type: "S3",
    location: artifact_bucket.bucket
  },
  environment: {
    type: "LINUX_CONTAINER",
    image: "aws/codebuild/standard:5.0",
    compute_type: "BUILD_GENERAL1_SMALL",
    environment_variables: [
      # Parameter Store
      { 
        name: "DB_PASSWORD", 
        value: "/myapp/prod/db_password", 
        type: "PARAMETER_STORE" 
      },
      # Secrets Manager
      { 
        name: "API_KEY", 
        value: "arn:aws:secretsmanager:us-east-1:123456789012:secret:api-key",
        type: "SECRETS_MANAGER"
      }
    ]
  }
})
```

### VPC-Isolated Builds
```ruby
private_build = aws_codebuild_project(:private_build, {
  name: "private-vpc-build",
  service_role: build_role.arn,
  source: {
    type: "CODECOMMIT",
    location: repo.clone_url_http
  },
  artifacts: {
    type: "S3",
    location: artifact_bucket.bucket
  },
  environment: {
    type: "LINUX_CONTAINER",
    image: "aws/codebuild/standard:5.0",
    compute_type: "BUILD_GENERAL1_MEDIUM"
  },
  vpc_config: {
    vpc_id: vpc.id,
    subnets: private_subnets.map(&:id),
    security_group_ids: [build_sg.id]
  }
})
```

## Performance Optimization

### Caching Strategies
1. **S3 Cache**: Best for artifacts shared across builds
2. **Local Docker Layer Cache**: Speeds up Docker builds
3. **Local Source Cache**: Caches git repositories
4. **Local Custom Cache**: User-defined cache directories

### Compute Type Selection
- **Small (3GB/2vCPU)**: Simple builds, scripts
- **Medium (7GB/4vCPU)**: Standard applications
- **Large (15GB/8vCPU)**: Large applications, containers
- **2XLarge (145GB/72vCPU)**: Memory-intensive builds

## Build Patterns

### Blue-Green Deployment Build
```ruby
blue_green_build = aws_codebuild_project(:blue_green, {
  name: "blue-green-build",
  service_role: build_role.arn,
  source: {
    type: "CODECOMMIT",
    location: repo.clone_url_http,
    buildspec: "buildspec-bluegreen.yml"
  },
  artifacts: {
    type: "CODEPIPELINE"  # Used within pipeline
  },
  environment: {
    type: "LINUX_CONTAINER",
    image: "aws/codebuild/standard:5.0",
    compute_type: "BUILD_GENERAL1_MEDIUM",
    environment_variables: [
      { name: "DEPLOYMENT_TYPE", value: "blue-green" }
    ]
  }
})
```

### Canary Deployment Build
```ruby
canary_build = aws_codebuild_project(:canary, {
  name: "canary-build",
  service_role: build_role.arn,
  source: {
    type: "GITHUB",
    location: "https://github.com/org/app.git",
    report_build_status: true
  },
  artifacts: {
    type: "S3",
    location: artifact_bucket.bucket,
    name: "canary-${CODEBUILD_BUILD_NUMBER}"
  },
  environment: {
    type: "LINUX_CONTAINER",
    image: "aws/codebuild/standard:5.0",
    compute_type: "BUILD_GENERAL1_SMALL",
    environment_variables: [
      { name: "CANARY_PERCENTAGE", value: "10" }
    ]
  }
})
```

## Anti-Patterns to Avoid

1. **Over-provisioning Compute**: Don't use LARGE for simple builds
2. **Storing Secrets in Plaintext**: Always use Parameter Store or Secrets Manager
3. **Ignoring Cache**: Implement caching for faster builds
4. **Public Subnet VPC Builds**: Use private subnets for security
5. **Unbounded Timeouts**: Set reasonable timeout values

## Monitoring and Debugging

### CloudWatch Integration
- Build logs automatically sent to CloudWatch Logs
- Metrics for build duration, success rate, queue time
- CloudWatch Events for build state changes

### Build Badges
Enable badges for GitHub/GitLab README integration showing build status

### Log Configuration
```ruby
logs_config: {
  cloudwatch_logs: {
    status: "ENABLED",
    group_name: "/aws/codebuild/myapp",
    stream_name: "build-logs"
  },
  s3_logs: {
    status: "ENABLED",
    location: "${logs_bucket.bucket}/build-logs",
    encryption_disabled: false
  }
}
```

## Cost Optimization

1. **Right-size Compute**: Use smallest compute type that meets needs
2. **Build Caching**: Reduces build time and cost
3. **Concurrent Build Limits**: Prevent runaway costs
4. **Timeout Configuration**: Fail fast on stuck builds
5. **On-Demand vs Reserved**: Consider savings plans for predictable workloads