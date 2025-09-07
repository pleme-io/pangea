# AWS Auto Scaling Lifecycle Hook Implementation

## Overview

The `aws_autoscaling_lifecycle_hook` resource enables custom actions during instance launch and termination in Auto Scaling Groups. This implementation provides comprehensive validation for lifecycle transitions, notification configurations, and operational constraints to support production-grade instance lifecycle management.

## Key Features

### Lifecycle Transitions Supported
- **Instance Launching**: `autoscaling:EC2_INSTANCE_LAUNCHING`
- **Instance Terminating**: `autoscaling:EC2_INSTANCE_TERMINATING`

### Notification Integration
- **SNS Topic Support**: Fan-out notifications to multiple subscribers
- **SQS Queue Support**: Reliable message queuing for hook processors
- **IAM Role Validation**: Ensures proper permissions for notification delivery
- **Metadata Support**: Custom JSON metadata for hook context

### Operational Controls
- **Configurable Timeouts**: 30 seconds to 2 hours (30-7200 seconds)
- **Default Results**: `ABANDON` (fail-safe) or `CONTINUE` (permissive)
- **ARN Validation**: Comprehensive AWS ARN format validation

## Implementation Details

### Type System Architecture

```ruby
class AutoScalingLifecycleHookAttributes < Dry::Struct
  # Lifecycle transition validation
  attribute :lifecycle_transition, Resources::Types::String.enum(
    'autoscaling:EC2_INSTANCE_LAUNCHING',
    'autoscaling:EC2_INSTANCE_TERMINATING'
  )
  
  # Heartbeat timeout with AWS constraints
  attribute :heartbeat_timeout, Resources::Types::Integer
    .default(300)
    .constrained(gteq: 30, lteq: 7200)
end
```

### Notification Configuration Validation

The implementation enforces consistent notification configuration:

```ruby
def self.new(attributes)
  # Ensure notification components are specified together
  notification_target = attrs[:notification_target_arn]
  role = attrs[:role_arn]
  
  if notification_target && !role
    raise Dry::Struct::Error, "role_arn is required when notification_target_arn is specified"
  end
  
  if role && !notification_target
    raise Dry::Struct::Error, "notification_target_arn is required when role_arn is specified"  
  end
end
```

### ARN Validation System

Comprehensive ARN validation for AWS resource references:

```ruby
def self.valid_arn?(arn)
  # Basic AWS ARN format validation
  arn =~ /^arn:aws[a-z-]*:[a-z0-9][a-z0-9-]*:[a-z0-9-]*:\d{12}:.+/
end

def self.valid_notification_target?(arn)
  valid_arn?(arn) && (arn.include?(':sns:') || arn.include?(':sqs:'))
end

def self.valid_iam_role_arn?(arn)
  valid_arn?(arn) && arn.include?(':iam:') && arn.include?(':role/')
end
```

**Validation Features:**
- **Basic ARN Structure**: Validates partition, service, region, account format
- **Service-Specific Validation**: Ensures SNS/SQS for notifications, IAM for roles
- **Resource Type Validation**: Validates role path for IAM ARNs

### Metadata Validation

```ruby
# Validate metadata length constraint
if attrs[:notification_metadata] && attrs[:notification_metadata].length > 1023
  raise Dry::Struct::Error, "notification_metadata cannot exceed 1023 characters"
end
```

AWS Auto Scaling has a hard limit of 1023 characters for notification metadata.

## Production Integration Patterns

### Application Lifecycle Management

```ruby
# Launch hook for complex application initialization
aws_autoscaling_lifecycle_hook(:app_startup_hook, {
  name: "application-initialization",
  auto_scaling_group_name: ref(:aws_autoscaling_group, :web_servers, :name),
  lifecycle_transition: "autoscaling:EC2_INSTANCE_LAUNCHING",
  heartbeat_timeout: 900,  # 15 minutes for startup
  default_result: "ABANDON",  # Fail if initialization fails
  notification_target_arn: ref(:aws_sns_topic, :app_lifecycle, :arn),
  role_arn: ref(:aws_iam_role, :lifecycle_notifications, :arn),
  notification_metadata: JSON.generate({
    service: "web-application",
    environment: "production", 
    initialization_timeout: 900,
    health_check_endpoint: "/health"
  })
})

# Termination hook for graceful shutdown
aws_autoscaling_lifecycle_hook(:app_shutdown_hook, {
  name: "application-graceful-shutdown",
  auto_scaling_group_name: ref(:aws_autoscaling_group, :web_servers, :name),
  lifecycle_transition: "autoscaling:EC2_INSTANCE_TERMINATING",
  heartbeat_timeout: 300,  # 5 minutes for shutdown
  default_result: "CONTINUE",  # Continue even if graceful shutdown fails
  notification_target_arn: ref(:aws_sqs_queue, :shutdown_processor, :arn),
  role_arn: ref(:aws_iam_role, :lifecycle_notifications, :arn),
  notification_metadata: JSON.generate({
    service: "web-application",
    action: "graceful_shutdown",
    drain_timeout: 60,
    backup_required: false
  })
})
```

### Data Persistence Lifecycle

```ruby
# Database backup before termination
aws_autoscaling_lifecycle_hook(:database_backup_hook, {
  name: "database-backup-lifecycle",
  auto_scaling_group_name: ref(:aws_autoscaling_group, :db_servers, :name),
  lifecycle_transition: "autoscaling:EC2_INSTANCE_TERMINATING",
  heartbeat_timeout: 1800,  # 30 minutes for backup
  default_result: "CONTINUE",  # Don't block termination for backup failures
  notification_target_arn: ref(:aws_sns_topic, :database_operations, :arn),
  role_arn: ref(:aws_iam_role, :database_lifecycle_role, :arn),
  notification_metadata: JSON.generate({
    database_type: "postgresql",
    backup_destination: "s3://backup-bucket/database-backups/",
    compression: "gzip",
    retention_days: 30
  })
})
```

### Container Orchestration Integration

```ruby
# Container startup coordination
aws_autoscaling_lifecycle_hook(:container_startup_hook, {
  name: "container-orchestration-startup", 
  auto_scaling_group_name: ref(:aws_autoscaling_group, :ecs_hosts, :name),
  lifecycle_transition: "autoscaling:EC2_INSTANCE_LAUNCHING",
  heartbeat_timeout: 600,  # 10 minutes for container pulls
  default_result: "ABANDON", 
  notification_target_arn: ref(:aws_sqs_queue, :container_lifecycle, :arn),
  role_arn: ref(:aws_iam_role, :ecs_lifecycle_role, :arn),
  notification_metadata: JSON.generate({
    orchestrator: "ecs",
    cluster_name: "production-cluster",
    services: ["web", "api", "worker"],
    health_check_grace_period: 300
  })
})
```

## Query Method Implementation

The implementation provides rich query methods for operational logic:

```ruby
def is_launching_hook?
  lifecycle_transition == 'autoscaling:EC2_INSTANCE_LAUNCHING'
end

def is_terminating_hook?
  lifecycle_transition == 'autoscaling:EC2_INSTANCE_TERMINATING'
end

def has_notifications?
  !notification_target_arn.nil? && !role_arn.nil?
end

def uses_sns_notification?
  has_notifications? && notification_target_arn.include?(':sns:')
end

def uses_sqs_notification?
  has_notifications? && notification_target_arn.include?(':sqs:')
end

def short_timeout?
  heartbeat_timeout < 300  # Less than 5 minutes
end

def long_timeout?
  heartbeat_timeout > 1800  # More than 30 minutes
end
```

These methods enable conditional logic and operational insights.

## Operational Patterns

### Timeout Strategy by Use Case

```ruby
# Quick health checks - short timeout
heartbeat_timeout: 60

# Application startup - medium timeout  
heartbeat_timeout: 300

# Complex initialization - long timeout
heartbeat_timeout: 900

# Database operations - extended timeout
heartbeat_timeout: 1800
```

### Default Result Strategy

```ruby
# Critical initialization - ABANDON on failure
default_result: "ABANDON"

# Graceful operations - CONTINUE even on failure
default_result: "CONTINUE"
```

### Notification Routing Patterns

```ruby
# SNS for fan-out to multiple consumers
notification_target_arn: ref(:aws_sns_topic, :lifecycle_events, :arn)

# SQS for dedicated processing queues
notification_target_arn: ref(:aws_sqs_queue, :lifecycle_processor, :arn)
```

## Error Handling

The implementation provides detailed validation errors:

```ruby
# Configuration consistency errors
"role_arn is required when notification_target_arn is specified"
"notification_target_arn is required when role_arn is specified"

# ARN format errors
"Invalid ARN format for notification_target_arn: invalid-arn"
"notification_target_arn must be an SNS topic or SQS queue ARN"
"role_arn must be a valid IAM role ARN"

# Constraint validation errors
"notification_metadata cannot exceed 1023 characters"
```

## Testing Strategy

### Unit Tests
- ARN format validation for all AWS service types
- Lifecycle transition enum validation
- Timeout constraint validation (30-7200 seconds)
- Notification configuration consistency
- Metadata length validation

### Integration Tests  
- Hook creation with Auto Scaling Groups
- SNS/SQS notification delivery
- IAM role permission validation
- Hook execution and timeout behavior
- Metadata processing in notifications

### Production Monitoring
- Hook execution success/failure rates
- Timeout occurrence frequency
- Notification delivery verification
- Hook completion time analysis

## IAM Integration Requirements

### Notification Role Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow", 
      "Action": [
        "sns:Publish"
      ],
      "Resource": "arn:aws:sns:*:*:lifecycle-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage"
      ], 
      "Resource": "arn:aws:sqs:*:*:lifecycle-*"
    }
  ]
}
```

### Trust Policy for Auto Scaling Service

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "autoscaling.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

## Terraform Resource Mapping

Maps to AWS Terraform resource `aws_autoscaling_lifecycle_hook`:

```hcl
resource "aws_autoscaling_lifecycle_hook" "app_init_hook" {
  name                 = "application-initialization"
  auto_scaling_group_name = aws_autoscaling_group.web_servers.name
  lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  heartbeat_timeout    = 900
  default_result       = "ABANDON"
  notification_target_arn = aws_sns_topic.lifecycle_events.arn
  role_arn            = aws_iam_role.lifecycle_notifications.arn
  notification_metadata = jsonencode({
    service = "web-application"
    environment = "production"
  })
}
```

This implementation ensures reliable, well-validated lifecycle hooks that integrate seamlessly with Auto Scaling Groups and provide robust operational capabilities for production instance lifecycle management.