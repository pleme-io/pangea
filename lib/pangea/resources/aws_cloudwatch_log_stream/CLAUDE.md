# AWS CloudWatch Log Stream Implementation

## Overview

This implementation provides type-safe AWS CloudWatch Log Stream resources with intelligent stream type detection and enterprise logging organization patterns.

## Architecture

### Type System
- **`CloudWatchLogStreamAttributes`**: dry-struct validation with CloudWatch-specific constraints
- **Name Validation**: AWS log stream naming pattern enforcement (more restrictive than log groups)
- **Stream Type Detection**: Automatic detection of Lambda, ECS, and application streams
- **Hierarchy Analysis**: Log group path decomposition for organizational insights

### Key Features

#### 1. Enhanced Name Validation
- Stricter character set validation than log groups
- Supports colons (`:`) in addition to log group valid characters
- Prevents colon at start/end and consecutive colons
- Maintains forward slash path validation

#### 2. Intelligent Stream Type Detection
- **Lambda Detection**: Identifies Lambda-generated stream patterns (`[version]` notation)
- **ECS Detection**: Recognizes ECS service stream patterns (`ecs/` prefix)
- **Application Streams**: Default category for custom application streams

#### 3. Log Group Integration
- Validates log group name using same rules as log group resource
- Provides hierarchy analysis for organizational insights
- Supports referencing existing log groups

#### 4. Organizational Intelligence
- Stream type classification for monitoring patterns
- Hierarchy decomposition for structured analysis
- Naming pattern recognition for automated tooling

## Implementation Details

### Validation Logic

#### Log Stream Name Validation
```ruby
# Extended character set including colons
name.match?(/\A[a-zA-Z0-9._\-:\/]+\z/)

# Colon restrictions
name.start_with?(':')  # Forbidden
name.end_with?(':')    # Forbidden
name.include?('::')    # Forbidden consecutive colons

# Path validation (inherited from log groups)
name.include?('//')    # Forbidden consecutive slashes
```

#### Log Group Name Validation
```ruby
# Same validation as log group resource
log_group_name.match?(/\A[a-zA-Z0-9._\-\/]+\z/)
log_group_name.length <= 512
!log_group_name.empty?
```

### Stream Type Detection Algorithm

```ruby
def stream_type
  return 'lambda' if is_lambda_stream?
  return 'ecs' if is_ecs_stream?
  'application'
end

def is_lambda_stream?
  name.include?('[') && name.include?(']')  # Lambda version notation
end

def is_ecs_stream?
  name.start_with?('ecs/')  # ECS service prefix
end
```

### Hierarchy Analysis

```ruby
def log_group_hierarchy
  log_group_name.split('/').reject(&:empty?)
end

# Example: "/aws/lambda/function-name" => ["aws", "lambda", "function-name"]
# Example: "/application/web-servers" => ["application", "web-servers"]
```

### Computed Properties

1. **`is_lambda_stream?`**: Boolean indicating Lambda-generated stream pattern
2. **`is_ecs_stream?`**: Boolean indicating ECS-generated stream pattern  
3. **`is_application_stream?`**: Boolean indicating custom application stream
4. **`stream_type`**: String classification (`lambda`, `ecs`, `application`)
5. **`log_group_hierarchy`**: Array of log group path components

### Terraform Resource Mapping

```ruby
resource(:aws_cloudwatch_log_stream, name) do
  name_attr log_stream_attrs.name              # Required
  log_group_name log_stream_attrs.log_group_name  # Required
end
```

### Resource Reference Outputs

```ruby
outputs: {
  arn: "${aws_cloudwatch_log_stream.#{name}.arn}",
  name: "${aws_cloudwatch_log_stream.#{name}.name}",
  log_group_name: "${aws_cloudwatch_log_stream.#{name}.log_group_name}"
}
```

## Enterprise Patterns

### 1. Multi-Instance Application Streams
- Consistent naming patterns across instances
- Instance ID integration for debugging
- Separate streams for different log types per instance

### 2. Microservices Stream Organization
- Service-based stream grouping
- Instance replica stream management
- Performance and application log separation

### 3. AWS Service Integration Streams
- Lambda execution stream patterns
- ECS task-based stream organization
- Load balancer and database log streams

### 4. Time-Based Stream Management
- Date-based stream naming for rotation
- Session-based stream identification
- Automatic timestamp integration

## Stream Naming Conventions

### Lambda Stream Patterns
```ruby
# AWS Lambda automatic pattern
"YYYY/MM/DD/[$LATEST]xxxxxxxxx"
"YYYY/MM/DD/[version]xxxxxxxxx"

# Custom Lambda stream
"scheduled-execution/YYYY/MM/DD"
```

### ECS Stream Patterns  
```ruby
# ECS service pattern
"ecs/service-name/task-revision/container"
"ecs/service-name/instance-id"

# Custom ECS pattern
"ecs/web-service/#{task_definition_revision}/task-#{task_id}"
```

### Application Stream Patterns
```ruby
# Instance-based
"#{instance_id}/#{log_type}"
"server-01/application"
"worker-03/errors"

# Service-based
"#{service}/#{environment}/#{component}"
"api/production/access-logs"
"worker/staging/processing"

# Time-based
"#{service}/#{date}/#{session}"
"user-service/2023-12-01/session-abc123"
```

## Stream Type Detection Benefits

### 1. Monitoring Automation
- Automatic metric creation based on stream type
- Type-specific log parsing and analysis
- Service-aware alerting configuration

### 2. Cost Analysis
- Stream type cost attribution
- Service-specific usage analysis
- Lambda vs ECS vs application cost breakdown

### 3. Operational Intelligence
- Stream lifecycle management
- Type-specific retention policies
- Service-aware log aggregation

### 4. Security and Compliance
- Stream type access controls
- Service-specific audit requirements
- Type-based encryption policies

## Validation Error Messages

The implementation provides clear error messages for validation failures:

- Character set violations with supported characters
- Colon usage restrictions with examples
- Length constraints with AWS limits
- Log group name validation with pattern requirements

## Integration Patterns

### 1. Reference-Based Integration
```ruby
# Reference existing log group
log_stream = aws_cloudwatch_log_stream(:app_stream, {
  name: "instance-001/application",
  log_group_name: app_log_group.name  # Reference
})
```

### 2. Dynamic Stream Creation
```ruby
# Generate streams based on infrastructure
instances.each_with_index do |instance, index|
  aws_cloudwatch_log_stream(:"instance_#{index}", {
    name: "#{instance.id}/application",
    log_group_name: "/application/#{service_name}"
  })
end
```

### 3. Service Discovery Integration
```ruby
# Create streams for service discovery
services.each do |service|
  aws_cloudwatch_log_stream(:"#{service}_stream", {
    name: "#{service}/#{environment}/main",
    log_group_name: "/services/#{service}"
  })
end
```

## Testing Considerations

The implementation supports testing through:
- Deterministic stream type detection
- Predictable hierarchy analysis  
- Clear validation rules with specific error messages
- Type safety through dry-struct validation
- Computed properties for testing stream classification

## Best Practices Encoded

1. **Naming Consistency**: Enforced naming patterns across stream types
2. **Type Detection**: Automatic classification for operational tooling
3. **Hierarchy Analysis**: Path decomposition for organizational insights
4. **Integration Support**: Reference-based log group integration
5. **Validation Clarity**: Clear error messages for troubleshooting