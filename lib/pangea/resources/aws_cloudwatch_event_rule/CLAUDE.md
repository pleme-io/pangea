# AWS CloudWatch Event Rule - Architecture Documentation

## Core Concepts

### Event Rule Design Philosophy

CloudWatch Event Rules (the precursor to EventBridge) implement event-driven architectures by matching events and routing them to targets. This resource implements:

1. **Event Pattern Matching**: Complex event filtering with JSON patterns
2. **Scheduled Execution**: Time-based triggers using rate or cron expressions
3. **Multi-Source Integration**: Unified event handling from AWS services
4. **Custom Event Support**: Application-specific event processing

### Implementation Architecture

```
CloudWatch Event Rule
├── Event Matching Engine
│   ├── Pattern Evaluator
│   ├── Source Filter
│   ├── Detail Type Filter
│   └── Content Filter
├── Schedule Engine
│   ├── Rate Calculator
│   ├── Cron Parser
│   └── UTC Time Handler
└── Target Management
    ├── Permission Validator
    ├── Retry Configuration
    └── Dead Letter Queue
```

## Type Safety Implementation

### Validation Layers

1. **Pattern Validation**
   - JSON syntax verification
   - Event pattern structure validation
   - Schedule expression format checking

2. **Configuration Validation**
   - Name format constraints
   - State enumeration
   - Mutual exclusivity checks (pattern vs schedule)

3. **ARN Validation**
   - Role ARN format verification
   - Service-specific requirements
   - Cross-service compatibility

### Type Definitions

```ruby
# Mutual exclusivity validation
unless attrs[:event_pattern] || attrs[:schedule_expression]
  raise Dry::Struct::Error, "Must specify either event_pattern or schedule_expression"
end

if attrs[:event_pattern] && attrs[:schedule_expression]
  raise Dry::Struct::Error, "Cannot specify both event_pattern and schedule_expression"
end

# Schedule expression validation
unless expr.match?(/^rate\(.+\)$/) || expr.match?(/^cron\(.+\)$/)
  raise Dry::Struct::Error, "schedule_expression must be a rate() or cron() expression"
end
```

## Advanced Patterns

### 1. Event Correlation and Aggregation

Implement complex event processing with correlation:

```ruby
# Collect related events for correlation
correlation_rule = aws_cloudwatch_event_rule(:event_correlation, {
  name: "correlated-events-collector",
  event_pattern: jsonencode({
    source: ["aws.ec2", "aws.autoscaling", "aws.elasticloadbalancing"],
    "detail-type": [
      "EC2 Instance State-change Notification",
      "EC2 Instance Launch Successful",
      "Auto Scaling Instance Launch",
      "ELB Instance Health Check"
    ]
  })
})

# Process with Lambda for correlation
correlation_processor = aws_lambda_function(:correlator, {
  function_name: "event-correlation-processor",
  environment: {
    variables: {
      CORRELATION_WINDOW: "300",  # 5 minutes
      CORRELATION_TABLE: correlation_table.name
    }
  }
})

# Advanced pattern matching for security correlation
security_correlation = aws_cloudwatch_event_rule(:security_correlation, {
  name: "security-event-correlation",
  event_pattern: jsonencode({
    source: ["aws.signin", "aws.iam", "aws.cloudtrail"],
    "detail-type": ["AWS Console Sign In via CloudTrail"],
    detail: {
      eventName: [
        "ConsoleLogin",
        "AssumeRole",
        "GetSessionToken",
        "CreateAccessKey"
      ],
      responseElements: {
        ConsoleLogin: ["Failure"]
      }
    },
    # Time-based correlation window
    time: [{
      # Events within last 5 minutes
      after: { 
        subtract: ["NOW", 300000]  # milliseconds
      }
    }]
  })
})
```

### 2. Intelligent Event Routing

Build smart routing based on event content:

```ruby
# Content-based routing rule
routing_rule = aws_cloudwatch_event_rule(:intelligent_router, {
  name: "content-based-router",
  event_pattern: jsonencode({
    source: ["myapp.orders"],
    "detail-type": ["Order Event"]
  })
})

# Multiple targets with input transformation
high_value_target = aws_cloudwatch_event_target(:high_value, {
  rule: routing_rule.name,
  arn: high_value_processor.arn,
  input_transformer: {
    input_paths_map: {
      order_id: "$.detail.orderId",
      amount: "$.detail.amount",
      customer: "$.detail.customerId"
    },
    input_template: jsonencode({
      orderId: "<order_id>",
      amount: "<amount>",
      customer: "<customer>",
      priority: "HIGH"
    })
  },
  # Only for high-value orders
  event_pattern: jsonencode({
    detail: {
      amount: [{ numeric: [">", 1000] }]
    }
  })
})

# Regular order processing
normal_target = aws_cloudwatch_event_target(:normal, {
  rule: routing_rule.name,
  arn: normal_processor.arn,
  # For all other orders
  event_pattern: jsonencode({
    detail: {
      amount: [{ numeric: ["<=", 1000] }]
    }
  })
})
```

### 3. Scheduled Task Orchestration

Complex scheduling patterns for task orchestration:

```ruby
# Staggered execution pattern
stagger_times = [0, 15, 30, 45]

stagger_times.each do |minute|
  aws_cloudwatch_event_rule(:"staggered_task_#{minute}", {
    name: "staggered-execution-#{minute}",
    description: "Executes at #{minute} minutes past each hour",
    schedule_expression: "cron(#{minute} * * * ? *)",
    tags: {
      TaskGroup: "staggered-execution",
      Offset: minute.to_s
    }
  })
end

# Conditional scheduling based on day type
business_days_rule = aws_cloudwatch_event_rule(:business_days, {
  name: "business-days-only",
  description: "Runs only on business days",
  schedule_expression: "cron(0 9 ? * MON-FRI *)"  # 9 AM Mon-Fri
})

weekends_rule = aws_cloudwatch_event_rule(:weekends, {
  name: "weekend-maintenance",
  description: "Weekend maintenance tasks",
  schedule_expression: "cron(0 2 ? * SAT-SUN *)"  # 2 AM Sat-Sun
})

# Complex scheduling with exclusions
end_of_month = aws_cloudwatch_event_rule(:month_end, {
  name: "end-of-month-processing",
  description: "Last day of month processing",
  # Last day of month at 11 PM
  schedule_expression: "cron(0 23 L * ? *)"
})
```

### 4. Event-Driven State Machines

Trigger Step Functions based on complex events:

```ruby
# Order fulfillment state machine trigger
fulfillment_rule = aws_cloudwatch_event_rule(:order_fulfillment, {
  name: "order-fulfillment-trigger",
  event_pattern: jsonencode({
    source: ["myapp.orders"],
    "detail-type": ["Order Placed"],
    detail: {
      status: ["PAID"],
      fulfillment: ["PENDING"]
    }
  })
})

# Approval workflow trigger
approval_rule = aws_cloudwatch_event_rule(:approval_workflow, {
  name: "approval-required",
  event_pattern: jsonencode({
    source: ["myapp.requests"],
    "detail-type": ["Approval Required"],
    detail: {
      # Complex approval criteria
      "$or": [
        { amount: [{ numeric: [">", 10000] }] },
        { riskScore: [{ numeric: [">", 0.8] }] },
        { requiresCompliance: [true] }
      ]
    }
  })
})

# Remediation workflow
remediation_rule = aws_cloudwatch_event_rule(:auto_remediation, {
  name: "infrastructure-remediation",
  event_pattern: jsonencode({
    source: ["aws.health", "aws.cloudwatch"],
    "detail-type": [
      "AWS Health Event",
      "CloudWatch Alarm State Change"
    ],
    detail: {
      # Trigger on specific conditions
      "$or": [
        { 
          service: ["EC2"],
          eventTypeCategory: ["issue"]
        },
        {
          alarmName: [{ prefix: "Critical-" }],
          state: { value: ["ALARM"] }
        }
      ]
    }
  })
})
```

## Event Pattern Language

### Advanced Pattern Matching

```ruby
# Complex nested patterns
complex_pattern = aws_cloudwatch_event_rule(:complex_matching, {
  name: "advanced-pattern-matching",
  event_pattern: jsonencode({
    # Multiple source matching
    source: ["aws.ec2", "custom.app"],
    
    # Array contains matching
    "detail-type": [{ prefix: "EC2" }, { suffix: "Notification" }],
    
    # Nested object matching
    detail: {
      instance: {
        state: ["running", "stopped"],
        type: [{ prefix: "t3." }],
        tags: {
          Environment: ["production", "staging"],
          Team: [{ exists: true }]
        }
      },
      
      # Numeric comparisons
      metrics: {
        cpu: [{ numeric: [">", 80] }],
        memory: [{ numeric: [">=", 90, "<=", 95] }]
      },
      
      # String patterns
      message: [
        { prefix: "ERROR:" },
        { suffix: ".failed" },
        { "anything-but": ["DEBUG", "INFO"] }
      ],
      
      # Logical operators
      "$or": [
        { severity: ["HIGH", "CRITICAL"] },
        { impact: [{ numeric: [">", 8] }] }
      ]
    }
  })
})
```

### Content-Based Filtering

```ruby
# IP address filtering
ip_filter_rule = aws_cloudwatch_event_rule(:ip_filtering, {
  name: "suspicious-ip-detection",
  event_pattern: jsonencode({
    source: ["aws.signin"],
    detail: {
      sourceIPAddress: [
        { cidr: "10.0.0.0/8" },    # Private IPs
        { cidr: "172.16.0.0/12" },
        { cidr: "192.168.0.0/16" },
        { "anything-but": { cidr: "203.0.113.0/24" } }  # Except this range
      ]
    }
  })
})

# NULL and existence checking
existence_rule = aws_cloudwatch_event_rule(:existence_check, {
  name: "field-existence-validation",
  event_pattern: jsonencode({
    source: ["custom.app"],
    detail: {
      # Required fields
      orderId: [{ exists: true }],
      customerId: [{ exists: true }],
      
      # Optional fields with NULL check
      discount: [{ exists: false }, { null: true }],
      
      # Complex existence patterns
      metadata: {
        processed: [{ exists: true, null: false }]
      }
    }
  })
})
```

## Performance Optimization

### Event Bus Strategies

```ruby
# Separate event buses for isolation
buses = {
  critical: "critical-events",
  normal: "normal-events",
  batch: "batch-processing"
}

buses.each do |priority, bus_name|
  # Create event bus
  bus = aws_cloudwatch_event_bus(:"#{priority}_bus", {
    name: bus_name
  })
  
  # Create rules with appropriate patterns
  aws_cloudwatch_event_rule(:"#{priority}_processor", {
    name: "process-#{priority}-events",
    event_bus_name: bus.name,
    event_pattern: jsonencode({
      source: ["myapp"],
      detail: {
        priority: [priority.to_s.upcase]
      }
    })
  })
end
```

### Rule Optimization

```ruby
# Avoid overly broad patterns
# Bad - processes too many events
inefficient_rule = aws_cloudwatch_event_rule(:inefficient, {
  name: "process-everything",
  event_pattern: jsonencode({
    source: ["aws.ec2"]  # Matches ALL EC2 events
  })
})

# Good - specific pattern matching
efficient_rule = aws_cloudwatch_event_rule(:efficient, {
  name: "process-specific",
  event_pattern: jsonencode({
    source: ["aws.ec2"],
    "detail-type": ["EC2 Instance State-change Notification"],
    detail: {
      state: ["terminated"],  # Only terminated instances
      instance: {
        tags: {
          AutoScale: ["true"]  # Only auto-scaled instances
        }
      }
    }
  })
})
```

## Monitoring and Debugging

### Rule Metrics

```ruby
# Monitor rule performance
rule_dashboard = aws_cloudwatch_dashboard(:event_rules, {
  dashboard_name: "event-rule-monitoring",
  dashboard_body: jsonencode({
    widgets: [{
      type: "metric",
      properties: {
        metrics: [
          ["AWS/Events", "SuccessfulRuleMatches", "RuleName", rule.name],
          [".", "FailedInvocations", ".", "."],
          [".", "TriggeredRules", ".", "."],
          [".", "InvocationAttempts", ".", "."]
        ],
        period: 300,
        stat: "Sum",
        region: "us-east-1",
        title: "Event Rule Performance"
      }
    }]
  })
})

# Alert on failures
rule_alarm = aws_cloudwatch_metric_alarm(:rule_failures, {
  alarm_name: "event-rule-failures",
  namespace: "AWS/Events",
  metric_name: "FailedInvocations",
  dimensions: {
    RuleName: rule.name
  },
  statistic: "Sum",
  period: 300,
  evaluation_periods: 2,
  threshold: 5,
  comparison_operator: "GreaterThanThreshold"
})
```

### Testing Event Patterns

```ruby
# Create test event rule
test_rule = aws_cloudwatch_event_rule(:pattern_test, {
  name_prefix: "test-pattern-",
  event_pattern: jsonencode(test_pattern),
  state: "DISABLED"  # Disabled by default
})

# Test with CloudWatch Logs target
test_log_group = aws_cloudwatch_log_group(:test_events, {
  name: "/aws/events/pattern-testing"
})

test_target = aws_cloudwatch_event_target(:test_logger, {
  rule: test_rule.name,
  arn: test_log_group.arn
})

# Enable for testing
# terraform apply -target=aws_cloudwatch_event_rule.pattern_test -var="rule_state=ENABLED"
```

## Security Considerations

### Least Privilege Rules

```ruby
# Restrict rule to specific resources
restricted_rule = aws_cloudwatch_event_rule(:restricted, {
  name: "restricted-ec2-events",
  event_pattern: jsonencode({
    source: ["aws.ec2"],
    resources: [
      "arn:aws:ec2:us-east-1:123456789012:instance/i-1234567890abcdef0"
    ],
    detail: {
      state: ["stopped", "terminated"]
    }
  })
})

# Role with minimal permissions
minimal_role = aws_iam_role(:event_rule_role, {
  name: "event-rule-minimal",
  assume_role_policy: jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Principal: { Service: "events.amazonaws.com" },
      Action: "sts:AssumeRole",
      Condition: {
        StringEquals: {
          "aws:SourceAccount": data.aws_caller_identity.current.account_id
        }
      }
    }]
  })
})
```

## Future Enhancements

### Planned Features

1. **Event Replay**: Support for event replay capabilities
2. **Pattern Builder**: DSL for building complex patterns
3. **Cross-Region Events**: Native cross-region event routing
4. **Event Schemas**: Integration with schema registry

### Migration to EventBridge

```ruby
# CloudWatch Events rules are compatible with EventBridge
# Consider migrating to aws_eventbridge_rule for new features:
# - Event replay
# - Schema discovery
# - Partner event sources
# - Archive and replay
```

### Extension Points

The current implementation provides extension points for:
- Custom pattern validators
- Schedule expression generators
- Event source integrations
- Pattern optimization algorithms