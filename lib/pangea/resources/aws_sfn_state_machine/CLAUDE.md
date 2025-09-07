# AWS Step Functions State Machine Implementation

## Overview

This implementation provides a type-safe, validation-rich interface for AWS Step Functions state machines with comprehensive Amazon States Language (ASL) support.

## Architecture

### Type System
- **SfnStateMachineAttributes**: Main dry-struct with ASL validation
- **ASL Parser**: Custom JSON validation for Amazon States Language
- **State Validators**: Type-specific validation for each state type
- **Configuration Helpers**: Pre-built logging and tracing configurations

### Validation Layers

1. **Structural Validation**: dry-struct ensures required fields and types
2. **ASL Validation**: Custom logic validates Amazon States Language syntax
3. **State-Specific Validation**: Each state type has specific requirements
4. **Reference Validation**: Ensures state references are valid

## Amazon States Language Support

### Core ASL Features
- **Complete State Types**: Task, Pass, Fail, Succeed, Choice, Wait, Parallel, Map
- **Field Validation**: Required fields per state type
- **Reference Checking**: StartAt and Next field validation
- **Error Handling**: Retry and Catch block support

### State Type Validation

**Task States**:
```ruby
# Must have Resource field
{
  "Type" => "Task",
  "Resource" => "arn:aws:states:::service:action",  # Required
  "Parameters" => { ... },                         # Optional
  "ResultPath" => "$.result",                      # Optional
  "Next" => "NextState"                           # Or "End": true
}
```

**Choice States**:
```ruby
# Must have Choices array
{
  "Type" => "Choice",
  "Choices" => [                                  # Required
    {
      "Variable" => "$.type",
      "StringEquals" => "value",
      "Next" => "NextState"
    }
  ],
  "Default" => "DefaultState"                     # Optional
}
```

**Wait States**:
```ruby
# Must have exactly one timing field
{
  "Type" => "Wait",
  "Seconds" => 10,          # OR SecondsPath, Timestamp, TimestampPath
  "Next" => "NextState"
}
```

**Parallel States**:
```ruby
# Must have Branches array
{
  "Type" => "Parallel",
  "Branches" => [                                 # Required
    {
      "StartAt" => "BranchStart",
      "States" => { ... }
    }
  ],
  "Next" => "NextState"
}
```

## Pattern Generators

### Simple Task Pattern
```ruby
Types::SfnStateMachineAttributes.simple_task_definition(
  "arn:aws:lambda:us-east-1:123456789012:function:my-function"
)
```

Generates:
```json
{
  "Comment": "Simple task state machine",
  "StartAt": "Task", 
  "States": {
    "Task": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:us-east-1:123456789012:function:my-function",
      "End": true
    }
  }
}
```

### Sequential Tasks Pattern
```ruby
Types::SfnStateMachineAttributes.sequential_tasks_definition([
  ["Step1", "arn:aws:lambda:us-east-1:123456789012:function:step1"],
  ["Step2", "arn:aws:lambda:us-east-1:123456789012:function:step2"]
])
```

### Parallel Tasks Pattern
```ruby
Types::SfnStateMachineAttributes.parallel_tasks_definition({
  "Branch1" => [["Task1", "arn:aws:lambda:us-east-1:123456789012:function:task1"]],
  "Branch2" => [["Task2", "arn:aws:lambda:us-east-1:123456789012:function:task2"]]
})
```

### Choice Pattern
```ruby
Types::SfnStateMachineAttributes.choice_definition([
  {
    { variable: "$.type", operator: "StringEquals", value: "A" } => "TaskA"
  }
], "DefaultTask")
```

## Configuration Patterns

### Logging Configuration
```ruby
# Standard logging
{
  level: "ERROR",                    # ALL, ERROR, FATAL, OFF
  include_execution_data: false,
  destinations: [
    {
      cloud_watch_logs_log_group: {
        log_group_arn: "arn:aws:logs:..."
      }
    }
  ]
}

# Helper method
Types::SfnStateMachineAttributes.cloudwatch_logging(
  "arn:aws:logs:us-east-1:123456789012:log-group:/aws/stepfunctions/my-workflow",
  "ALL",    # level
  true      # include_execution_data
)
```

### Tracing Configuration
```ruby
# Enable X-Ray tracing
Types::SfnStateMachineAttributes.enable_xray_tracing
# Returns: { enabled: true }

# Disable tracing
Types::SfnStateMachineAttributes.disable_tracing  
# Returns: { enabled: false }
```

## State Machine Types

### Standard Workflows
- **Duration**: Long-running (up to 1 year)
- **Execution Model**: Exactly-once workflow execution
- **Performance**: 2,000 executions/second per account
- **History**: Full execution history retained
- **Use Cases**: Long-running processes, human approval workflows

### Express Workflows
- **Duration**: Short-duration (up to 5 minutes)
- **Execution Model**: At-least-once workflow execution
- **Performance**: 100,000+ executions/second per account  
- **History**: Optional execution history
- **Use Cases**: Event processing, data transformation, IoT data processing

## Validation Error Examples

### Missing Required Fields
```ruby
# This will fail
aws_sfn_state_machine(:invalid, {
  name: "test",
  definition: JSON.generate({
    # Missing StartAt
    States: {
      Task1: { Type: "Task", Resource: "arn:aws:lambda:::" }
    }
  })
})
# Error: "Definition must include 'StartAt' field"
```

### Invalid State References
```ruby
# This will fail
aws_sfn_state_machine(:invalid, {
  name: "test", 
  definition: JSON.generate({
    StartAt: "NonExistentState",  # References non-existent state
    States: {
      Task1: { Type: "Task", Resource: "arn:aws:lambda:::" }
    }
  })
})
# Error: "'StartAt' must reference an existing state: NonExistentState"
```

### Invalid State Types
```ruby
# This will fail
aws_sfn_state_machine(:invalid, {
  name: "test",
  definition: JSON.generate({
    StartAt: "InvalidTask",
    States: {
      InvalidTask: { 
        Type: "InvalidType"  # Invalid state type
      }
    }
  })
})
# Error: "State 'InvalidTask' has invalid type 'InvalidType'"
```

### Missing Task Resource
```ruby
# This will fail
aws_sfn_state_machine(:invalid, {
  name: "test",
  definition: JSON.generate({
    StartAt: "Task",
    States: {
      Task: { 
        Type: "Task"
        # Missing Resource field
      }
    }
  })
})
# Error: "Task state 'Task' must have a 'Resource' field"
```

## Integration Service Patterns

### AWS Service Integrations

**Lambda (Invoke)**:
```ruby
{
  Type: "Task",
  Resource: "arn:aws:states:::lambda:invoke",
  Parameters: {
    FunctionName: "my-function",
    "Payload.$": "$"
  }
}
```

**Batch (Submit Job)**:
```ruby
{
  Type: "Task", 
  Resource: "arn:aws:states:::batch:submitJob.sync",
  Parameters: {
    JobDefinition: "my-job-def",
    JobName: "my-job",
    JobQueue: "my-queue"
  }
}
```

**ECS (Run Task)**:
```ruby
{
  Type: "Task",
  Resource: "arn:aws:states:::ecs:runTask.sync", 
  Parameters: {
    LaunchType: "FARGATE",
    TaskDefinition: "my-task-def",
    Cluster: "my-cluster"
  }
}
```

**SNS (Publish)**:
```ruby
{
  Type: "Task",
  Resource: "arn:aws:states:::sns:publish",
  Parameters: {
    TopicArn: "arn:aws:sns:us-east-1:123456789012:my-topic",
    Message: "Hello from Step Functions"
  }
}
```

**SQS (Send Message)**:
```ruby
{
  Type: "Task",
  Resource: "arn:aws:states:::sqs:sendMessage",
  Parameters: {
    QueueUrl: "https://sqs.us-east-1.amazonaws.com/123456789012/my-queue",
    MessageBody: "Message from Step Functions"
  }
}
```

**DynamoDB (Put Item)**:
```ruby
{
  Type: "Task",
  Resource: "arn:aws:states:::dynamodb:putItem",
  Parameters: {
    TableName: "my-table",
    Item: {
      id: { S: "12345" },
      data: { S: "example" }
    }
  }
}
```

## Error Handling Patterns

### Retry Configuration
```ruby
{
  Type: "Task",
  Resource: "arn:aws:lambda:us-east-1:123456789012:function:unreliable",
  Retry: [{
    ErrorEquals: [
      "Lambda.ServiceException",
      "Lambda.AWSLambdaException", 
      "Lambda.SdkClientException"
    ],
    IntervalSeconds: 2,
    MaxAttempts: 6,
    BackoffRate: 2.0
  }]
}
```

### Catch Configuration
```ruby
{
  Type: "Task",
  Resource: "arn:aws:lambda:us-east-1:123456789012:function:may-fail",
  Catch: [{
    ErrorEquals: ["States.TaskFailed"],
    Next: "HandleFailure",
    ResultPath: "$.error"
  }, {
    ErrorEquals: ["States.ALL"],
    Next: "DefaultErrorHandler"
  }]
}
```

## Performance Considerations

### Standard vs Express Selection
- Use **Standard** for workflows requiring exactly-once execution, long duration, or full execution history
- Use **Express** for high-volume, short-duration, event-driven processing

### Resource Optimization
- Use appropriate service integrations (`.sync` suffix for synchronous operations)
- Consider parallel processing for independent tasks
- Use Map states for array processing
- Implement proper error handling to avoid unnecessary retries

## Security Considerations

### IAM Role Requirements
The execution role must have permissions for:
- Step Functions service trust policy
- Permissions for all integrated services (Lambda, Batch, etc.)
- CloudWatch Logs permissions (if logging enabled)
- X-Ray permissions (if tracing enabled)

### Example Execution Role Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction",
        "batch:SubmitJob",
        "batch:DescribeJobs",
        "ecs:RunTask",
        "ecs:StopTask",
        "ecs:DescribeTasks"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow", 
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
```

## Testing Strategies

### Unit Testing ASL Definitions
```ruby
# Test ASL validation
definition = {
  StartAt: "Start",
  States: {
    Start: {
      Type: "Task",
      Resource: "arn:aws:lambda:us-east-1:123456789012:function:test",
      End: true
    }
  }
}

# Should not raise error
Types::SfnStateMachineAttributes.new({
  name: "test",
  role_arn: "arn:aws:iam::123456789012:role/test",
  definition: JSON.generate(definition)
})
```

### Integration Testing
Test state machines with actual AWS services in development environment before deploying to production.

## Monitoring and Observability

### CloudWatch Metrics
Step Functions automatically provides metrics:
- ExecutionsSucceeded
- ExecutionsFailed
- ExecutionTime
- ExecutionsAborted

### Logging Levels
- **OFF**: No logging
- **ERROR**: Only errors logged
- **FATAL**: Only fatal errors logged
- **ALL**: All events logged (including input/output data)

### X-Ray Tracing
Enable distributed tracing to understand execution flow across services and identify performance bottlenecks.