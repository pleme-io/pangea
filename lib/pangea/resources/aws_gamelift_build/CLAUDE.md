# AWS GameLift Build Resource - Technical Documentation

## Architecture
GameLift Build represents packaged game server executables ready for deployment. It's the foundation of GameLift's server hosting, containing all files needed to run game sessions.

## Build Lifecycle

### 1. Upload Phase
```ruby
# S3 bucket for builds
aws_s3_bucket(:game_builds, {
  bucket: "my-company-game-builds",
  versioning: { enabled: true }
})

# IAM role for GameLift access
aws_iam_role(:gamelift_s3, {
  assume_role_policy: gamelift_assume_policy,
  inline_policy: [{
    name: "S3BuildAccess",
    policy: s3_read_policy
  }]
})
```

### 2. Build Creation
```ruby
aws_gamelift_build(:production_build, {
  name: "GameServer-#{version}",
  operating_system: "AMAZON_LINUX_2",
  storage_location: {
    bucket: builds_bucket.id,
    key: "releases/v#{version}/server.zip",
    role_arn: gamelift_role.arn
  }
})
```

### 3. Validation Phase
GameLift automatically validates:
- File integrity
- Executable permissions
- Required dependencies
- Build size constraints

## Operating System Considerations

### Amazon Linux 2 (Recommended)
- Best performance/cost ratio
- Native AWS integration
- Minimal overhead

### Windows Server
- Required for Windows-only games
- Higher resource requirements
- DirectX support

## Build Packaging Best Practices

### Directory Structure
```
game-server.zip
├── GameServer (executable)
├── lib/
│   └── dependencies
├── assets/
│   └── game-data
└── config/
    └── server-config.json
```

### Size Optimization
- Exclude development assets
- Compress textures/audio
- Remove debug symbols for production
- Typical size: 100MB - 5GB

## Version Management Strategy

### Semantic Versioning
```ruby
version = "1.2.3"
aws_gamelift_build(:"game_build_v#{version.gsub('.', '_')}", {
  name: "GameServer-v#{version}",
  version: version,
  storage_location: {
    bucket: "builds",
    key: "releases/v#{version}/server.zip",
    role_arn: role_arn
  }
})
```

### Build Rotation
```ruby
# Keep last 5 builds
builds = ["1.2.0", "1.2.1", "1.2.2", "1.2.3", "1.2.4"]
builds.each do |ver|
  aws_gamelift_build(:"build_#{ver.gsub('.', '_')}", {
    name: "GameServer-v#{ver}",
    version: ver,
    # ...
  })
end
```

## Security Configuration

### IAM Role Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ],
    "Resource": "arn:aws:s3:::game-builds/*"
  }]
}
```

### S3 Bucket Policy
- Enable versioning
- Enforce encryption
- Restrict access to GameLift role
- Enable access logging

## Performance Optimization

### Build Upload
```ruby
# Use multipart upload for large builds
# Configure S3 Transfer Acceleration
aws_s3_bucket_accelerate_configuration(:build_acceleration, {
  bucket: builds_bucket.id,
  status: "Enabled"
})
```

### Regional Distribution
```ruby
# Replicate builds across regions
aws_s3_bucket_replication_configuration(:build_replication, {
  bucket: builds_bucket.id,
  role: replication_role.arn,
  rules: [{
    id: "replicate-builds",
    status: "Enabled",
    destination: {
      bucket: "arn:aws:s3:::builds-${region}"
    }
  }]
})
```

## Monitoring and Validation

### Build Status Tracking
```ruby
# CloudWatch alarm for failed builds
aws_cloudwatch_metric_alarm(:build_failures, {
  alarm_name: "gamelift-build-failures",
  comparison_operator: "GreaterThanThreshold",
  evaluation_periods: 1,
  metric_name: "BuildFailures",
  namespace: "AWS/GameLift",
  period: 300,
  threshold: 0
})
```

### Build Metrics
- Upload time
- Validation duration
- Build size
- Success/failure rate

## Cost Optimization

### S3 Lifecycle Rules
```ruby
aws_s3_bucket_lifecycle_configuration(:build_lifecycle, {
  bucket: builds_bucket.id,
  rules: [{
    id: "archive-old-builds",
    status: "Enabled",
    transitions: [{
      days: 30,
      storage_class: "GLACIER"
    }],
    expiration: {
      days: 365
    }
  }]
})
```

## Troubleshooting

### Common Issues
1. **FAILED status**: Check executable permissions
2. **S3 Access Denied**: Verify IAM role trust policy
3. **Invalid OS**: Ensure OS matches fleet configuration
4. **Size Limit**: Maximum 5GB per build

### Validation Logs
- Check CloudWatch Logs
- GameLift console build details
- S3 access logs

## Integration Examples

### CI/CD Pipeline
```ruby
# Triggered by build pipeline
build_id = aws_gamelift_build(:latest, {
  name: "GameServer-${env.BUILD_NUMBER}",
  version: "${env.GIT_COMMIT}",
  storage_location: {
    bucket: "${env.BUILDS_BUCKET}",
    key: "builds/${env.BUILD_NUMBER}/server.zip",
    role_arn: gamelift_role.arn
  }
})

# Update fleet with new build
aws_gamelift_fleet(:production, {
  build_id: build_id,
  # ...
})
```