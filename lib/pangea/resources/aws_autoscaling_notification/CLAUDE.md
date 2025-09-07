# AWS Auto Scaling Notification Implementation

## Overview

The `aws_autoscaling_notification` resource creates notification configurations that send Auto Scaling events to SNS topics. This implementation provides comprehensive validation for notification types, SNS topic ARNs, and Auto Scaling Group references, enabling robust operational monitoring of scaling activities.

## Key Features

### Notification Event Types Supported
- **Launch Events**: `autoscaling:EC2_INSTANCE_LAUNCH`
- **Launch Errors**: `autoscaling:EC2_INSTANCE_LAUNCH_ERROR`
- **Termination Events**: `autoscaling:EC2_INSTANCE_TERMINATE`
- **Termination Errors**: `autoscaling:EC2_INSTANCE_TERMINATE_ERROR`
- **Test Events**: `autoscaling:TEST_NOTIFICATION`

### Multi-Group Support
- **Centralized Monitoring**: Single notification configuration for multiple ASGs
- **Group Validation**: Validates group name format and constraints
- **Flexible Grouping**: Support for environment, service, or functional groupings

### SNS Integration
- **Topic ARN Validation**: Comprehensive SNS topic ARN format validation
- **Message Structure**: Structured JSON messages with scaling event details
- **Subscription Patterns**: Support for email, Lambda, SQS, and HTTP subscriptions

## Implementation Details

### Type System Architecture

```ruby
class AutoScalingNotificationAttributes < Dry::Struct
  # Multi-group support with validation
  attribute :group_names, Resources::Types::Array.of(Resources::Types::String)
    .constrained(min_size: 1)
  
  # Notification type enum validation
  attribute :notifications, Resources::Types::Array.of(
    Resources::Types::String.enum(
      'autoscaling:EC2_INSTANCE_LAUNCH',
      'autoscaling:EC2_INSTANCE_LAUNCH_ERROR',
      'autoscaling:EC2_INSTANCE_TERMINATE',
      'autoscaling:EC2_INSTANCE_TERMINATE_ERROR',
      'autoscaling:TEST_NOTIFICATION'
    )
  ).constrained(min_size: 1)
  
  # SNS topic ARN validation
  attribute :topic_arn, Resources::Types::String
end
```

### SNS Topic ARN Validation

Comprehensive validation for SNS topic ARN format:

```ruby
def self.valid_sns_topic_arn?(arn)
  # SNS topic ARN format: arn:aws:sns:region:account-id:topic-name
  arn =~ /^arn:aws[a-z-]*:sns:[a-z0-9-]+:\d{12}:[a-zA-Z0-9_-]+$/
end
```

**Validation Features:**
- **Partition Support**: Handles standard AWS and AWS GovCloud partitions
- **Region Format**: Validates region identifier format
- **Account ID**: Validates 12-digit AWS account ID format
- **Topic Name**: Validates topic name character constraints

### Group Name Validation

Validates Auto Scaling Group names according to AWS constraints:

```ruby
def self.new(attributes)
  if attrs[:group_names]
    attrs[:group_names].each do |group_name|
      if group_name.nil? || group_name.strip.empty?
        raise Dry::Struct::Error, "Auto Scaling Group names cannot be empty"
      end
      
      if group_name.length > 255
        raise Dry::Struct::Error, "Auto Scaling Group name cannot exceed 255 characters"
      end
    end
  end
end
```

### Notification Type Validation

Ensures notification types are valid and unique:

```ruby
# Validate notifications are unique
if attrs[:notifications] && attrs[:notifications].uniq.length != attrs[:notifications].length
  raise Dry::Struct::Error, "Duplicate notification types are not allowed"
end
```

**Supported Notification Types:**
- Instance launch success and error events
- Instance termination success and error events  
- Test notifications for configuration validation

## Query Method Implementation

Rich query methods for operational logic and monitoring strategies:

```ruby
def monitors_launch_events?
  notifications.any? { |n| n.include?('LAUNCH') }
end

def monitors_terminate_events?
  notifications.any? { |n| n.include?('TERMINATE') }
end

def monitors_all_lifecycle_events?
  monitors_all_launch_events? && monitors_all_terminate_events?
end

def monitors_errors_only?
  notifications.all? { |n| n.include?('ERROR') }
end

def monitors_success_only?
  notifications.none? { |n| n.include?('ERROR') } && !includes_test_notification?
end
```

These methods enable conditional configuration and operational insights.

## Integration Patterns

### Production Monitoring Setup

```ruby
# Comprehensive production monitoring
aws_autoscaling_notification(:production_lifecycle_monitoring, {
  group_names: [
    ref(:aws_autoscaling_group, :web_tier, :name),
    ref(:aws_autoscaling_group, :app_tier, :name),
    ref(:aws_autoscaling_group, :data_tier, :name)
  ],
  notifications: [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR", 
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ],
  topic_arn: ref(:aws_sns_topic, :production_autoscaling_events, :arn)
})

# Error-focused monitoring for critical services
aws_autoscaling_notification(:production_error_monitoring, {
  group_names: [
    ref(:aws_autoscaling_group, :critical_service, :name)
  ],
  notifications: [
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ],
  topic_arn: ref(:aws_sns_topic, :critical_alerts, :arn)
})
```

### Multi-Environment Pattern

```ruby
# Development environment - basic monitoring
aws_autoscaling_notification(:dev_monitoring, {
  group_names: [ref(:aws_autoscaling_group, :dev_services, :name)],
  notifications: [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE"
  ],
  topic_arn: ref(:aws_sns_topic, :dev_events, :arn)
})

# Staging environment - comprehensive monitoring
aws_autoscaling_notification(:staging_monitoring, {
  group_names: [
    ref(:aws_autoscaling_group, :staging_web, :name),
    ref(:aws_autoscaling_group, :staging_api, :name)
  ],
  notifications: [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE", 
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ],
  topic_arn: ref(:aws_sns_topic, :staging_events, :arn)
})
```

### Service-Specific Monitoring

```ruby
# Database service monitoring with extended error handling
aws_autoscaling_notification(:database_service_monitoring, {
  group_names: [
    ref(:aws_autoscaling_group, :primary_db, :name),
    ref(:aws_autoscaling_group, :read_replica, :name)
  ],
  notifications: [
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ],
  topic_arn: ref(:aws_sns_topic, :database_alerts, :arn)
})

# Web service monitoring for capacity planning
aws_autoscaling_notification(:web_service_capacity_monitoring, {
  group_names: [ref(:aws_autoscaling_group, :web_servers, :name)],
  notifications: [
    "autoscaling:EC2_INSTANCE_LAUNCH"
  ],
  topic_arn: ref(:aws_sns_topic, :capacity_planning, :arn)
})
```

## Notification Message Processing

### SNS Message Structure

Auto Scaling sends structured JSON messages:

```json
{
  "Progress": 50,
  "AccountId": "123456789012", 
  "Description": "Launching a new EC2 instance: i-1234567890abcdef0",
  "RequestId": "12345678-1234-1234-1234-123456789012",
  "EndTime": "2024-01-15T10:30:00.000Z",
  "AutoScalingGroupARN": "arn:aws:autoscaling:us-east-1:123456789012:autoScalingGroup:...",
  "ActivityId": "12345678-1234-1234-1234-123456789012",
  "StartTime": "2024-01-15T10:29:30.000Z",
  "Service": "AWS Auto Scaling",
  "Time": "2024-01-15T10:30:00.000Z",
  "EC2InstanceId": "i-1234567890abcdef0",
  "StatusCode": "InProgress",
  "StatusMessage": "Instance is launching",
  "Details": {
    "Availability Zone": "us-east-1a",
    "Subnet ID": "subnet-12345678"
  },
  "AutoScalingGroupName": "web-servers-asg",
  "Cause": "At 2024-01-15T10:29:30Z an instance was started...",
  "Event": "autoscaling:EC2_INSTANCE_LAUNCH"
}
```

### Lambda Processing Example

```python
import json
import boto3

def lambda_handler(event, context):
    for record in event['Records']:
        message = json.loads(record['Sns']['Message'])
        
        # Extract key information
        asg_name = message['AutoScalingGroupName']
        event_type = message['Event']
        instance_id = message.get('EC2InstanceId')
        status_code = message['StatusCode']
        
        # Process based on event type
        if event_type == 'autoscaling:EC2_INSTANCE_LAUNCH_ERROR':
            handle_launch_error(asg_name, instance_id, message)
        elif event_type == 'autoscaling:EC2_INSTANCE_TERMINATE_ERROR':
            handle_terminate_error(asg_name, instance_id, message)
        elif event_type == 'autoscaling:EC2_INSTANCE_LAUNCH':
            handle_successful_launch(asg_name, instance_id, message)
        
    return {'statusCode': 200}
```

## Operational Monitoring Patterns

### Error-Only Monitoring Strategy

For critical production services, monitor only errors to reduce noise:

```ruby
aws_autoscaling_notification(:critical_error_monitoring, {
  group_names: [
    ref(:aws_autoscaling_group, :payment_service, :name),
    ref(:aws_autoscaling_group, :auth_service, :name)
  ],
  notifications: [
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ],
  topic_arn: ref(:aws_sns_topic, :critical_service_alerts, :arn)
})
```

### Complete Lifecycle Monitoring

For development and staging environments:

```ruby
aws_autoscaling_notification(:complete_monitoring, {
  group_names: [ref(:aws_autoscaling_group, :staging_app, :name)],
  notifications: [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ],
  topic_arn: ref(:aws_sns_topic, :staging_all_events, :arn)
})
```

## Error Handling

Comprehensive validation provides detailed error messages:

```ruby
# Group name validation errors
"Auto Scaling Group names cannot be empty"
"Auto Scaling Group name cannot exceed 255 characters: very-long-group-name..."

# Notification validation errors
"Duplicate notification types are not allowed"

# SNS ARN validation errors
"Invalid SNS topic ARN format: invalid-arn-format"
```

## Testing Strategy

### Unit Tests
- SNS topic ARN format validation across different partitions
- Group name validation for edge cases and length limits
- Notification type enum validation
- Duplicate notification detection
- Query method behavior verification

### Integration Tests  
- Notification delivery to SNS topics
- Multi-group notification configuration
- Message format validation
- Subscription processing verification

### Production Validation
- Test notification functionality
- Error notification triggering
- Message delivery confirmation
- Subscription endpoint health

## CloudWatch Integration

Notifications can be processed to create custom CloudWatch metrics:

```python
# Lambda function to create custom metrics from notifications
import boto3

cloudwatch = boto3.client('cloudwatch')

def process_autoscaling_notification(message):
    metric_data = []
    
    if message['Event'] == 'autoscaling:EC2_INSTANCE_LAUNCH':
        metric_data.append({
            'MetricName': 'InstanceLaunched',
            'Dimensions': [
                {'Name': 'AutoScalingGroup', 'Value': message['AutoScalingGroupName']}
            ],
            'Value': 1,
            'Unit': 'Count'
        })
    
    cloudwatch.put_metric_data(
        Namespace='AutoScaling/Custom',
        MetricData=metric_data
    )
```

## Terraform Resource Mapping

Maps to AWS Terraform resource `aws_autoscaling_notification`:

```hcl
resource "aws_autoscaling_notification" "production_monitoring" {
  group_names = [
    aws_autoscaling_group.web_servers.name,
    aws_autoscaling_group.api_servers.name
  ]
  
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR", 
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ]
  
  topic_arn = aws_sns_topic.autoscaling_events.arn
}
```

This implementation provides reliable, well-validated Auto Scaling notifications that enable comprehensive monitoring of scaling activities across multiple Auto Scaling Groups with flexible notification routing and processing capabilities.