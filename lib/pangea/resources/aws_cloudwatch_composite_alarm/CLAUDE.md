# AWS CloudWatch Composite Alarm - Architecture Documentation

## Core Concepts

### Composite Alarm Design Philosophy

CloudWatch Composite Alarms represent a higher-order monitoring abstraction that enables sophisticated alerting logic by combining multiple metric alarms into logical expressions. This resource implements:

1. **Boolean Logic for Alarms**: Enables AND, OR, NOT operations on alarm states
2. **Hierarchical Monitoring**: Build alarm trees with parent-child relationships
3. **Maintenance Window Support**: Suppress actions during planned maintenance
4. **State Machine Abstraction**: Each composite alarm is a state machine responding to child alarm states

### Implementation Architecture

```
Composite Alarm
├── Alarm Rule Engine
│   ├── Expression Parser
│   ├── State Evaluator
│   └── Action Trigger
├── Child Alarm References
│   ├── Metric Alarms
│   ├── Other Composite Alarms
│   └── State Tracking
└── Action Management
    ├── SNS Topics
    ├── Lambda Functions
    └── Suppression Logic
```

## Type Safety Implementation

### Validation Layers

1. **Structural Validation**
   - dry-struct ensures all required fields are present
   - Type constraints prevent invalid attribute types
   - Custom validators for complex business rules

2. **Semantic Validation**
   - Alarm rule syntax checking
   - Parentheses matching validation
   - Operator keyword validation
   - Actions suppressor mutual exclusivity

3. **Referential Validation**
   - Referenced alarm extraction
   - Circular reference prevention (at application level)
   - Action ARN format validation

### Type Definitions

```ruby
# Core attribute types
attribute :alarm_name, Resources::Types::String
attribute :alarm_rule, Resources::Types::String

# Actions suppressor with schema validation
attribute :actions_suppressor, Resources::Types::Hash.schema(
  alarm: Resources::Types::String,
  extension_period: Resources::Types::Integer.optional,
  wait_period: Resources::Types::Integer.optional
).optional.default(nil)
```

## Advanced Patterns

### 1. Cascade Failure Detection

Composite alarms excel at detecting cascade failures across infrastructure layers:

```ruby
# Detect when load balancer issues cascade to application errors
cascade_alarm = aws_cloudwatch_composite_alarm(:cascade_detector, {
  alarm_name: "infrastructure-cascade-detector",
  alarm_rule: <<~RULE,
    (ALARM(alb-unhealthy-hosts) AND ALARM(ecs-task-failures)) OR
    (ALARM(alb-target-response-time) AND ALARM(api-timeouts))
  RULE
  alarm_description: "Detects cascading failures from load balancer to application"
})
```

### 2. Quorum-Based Alerting

Implement M-of-N alerting patterns:

```ruby
# Alert when 2 out of 3 availability zones have issues
quorum_alarm = aws_cloudwatch_composite_alarm(:az_quorum, {
  alarm_name: "multi-az-quorum-failure",
  alarm_rule: <<~RULE,
    (ALARM(az-a-unhealthy) AND ALARM(az-b-unhealthy)) OR
    (ALARM(az-a-unhealthy) AND ALARM(az-c-unhealthy)) OR
    (ALARM(az-b-unhealthy) AND ALARM(az-c-unhealthy))
  RULE
})
```

### 3. Time-Based Suppression

Implement business hours vs off-hours alerting:

```ruby
# Suppress non-critical alerts during off-hours
business_hours_alarm = aws_cloudwatch_composite_alarm(:business_hours_alert, {
  alarm_name: "business-hours-monitoring",
  alarm_rule: "ALARM(application-warnings) AND NOT ALARM(off-hours-window)",
  actions_suppressor: {
    alarm: off_hours_suppressor.alarm_name,
    extension_period: 1800  # 30 minutes grace period
  }
})
```

### 4. Service Dependency Modeling

Model service dependencies explicitly:

```ruby
# Alert only when downstream service issues affect upstream
dependency_alarm = aws_cloudwatch_composite_alarm(:service_impact, {
  alarm_name: "service-dependency-impact",
  alarm_rule: <<~RULE,
    ALARM(payment-service-down) AND 
    (ALARM(order-service-payment-errors) OR ALARM(checkout-failures))
  RULE
  alarm_description: "Alerts when payment service issues impact user-facing services"
})
```

## Integration Patterns

### SNS Topic Integration

```ruby
# Tiered alerting based on severity
critical_topic = aws_sns_topic(:critical, { name: "critical-alerts" })
warning_topic = aws_sns_topic(:warning, { name: "warning-alerts" })

composite_alarm = aws_cloudwatch_composite_alarm(:tiered_alert, {
  alarm_name: "tiered-severity-alerting",
  alarm_rule: "ALARM(critical-1) OR ALARM(critical-2)",
  alarm_actions: [critical_topic.arn],
  ok_actions: [warning_topic.arn]
})
```

### Lambda Function Integration

```ruby
# Custom remediation via Lambda
remediation_function = aws_lambda_function(:auto_remediate, {
  function_name: "auto-remediation-handler",
  runtime: "python3.9"
})

composite_alarm = aws_cloudwatch_composite_alarm(:auto_remediate, {
  alarm_name: "auto-remediation-trigger",
  alarm_rule: "ALARM(service-degraded) AND NOT ALARM(remediation-in-progress)",
  alarm_actions: [remediation_function.arn]
})
```

## State Management

### State Transitions

Composite alarms follow these state transitions:

```
        ┌─────────┐
        │   OK    │
        └────┬────┘
             │ Rule evaluates to TRUE
        ┌────▼────┐
        │  ALARM  │
        └────┬────┘
             │ Rule evaluates to FALSE
        ┌────▼────┐
        │   OK    │
        └─────────┘
```

### State Propagation

- Child alarm state changes trigger immediate re-evaluation
- Composite alarm state calculated from current child states
- Actions triggered only on state transitions, not continuous states

## Performance Considerations

### Evaluation Optimization

1. **Rule Complexity**: Keep rules under 10 logical operators for optimal performance
2. **Alarm References**: Limit to 100 child alarm references
3. **Evaluation Frequency**: Composite alarms evaluate within 1 minute of child state changes

### Cost Optimization

1. **Alarm Consolidation**: Use composite alarms to reduce total alarm count
2. **Action Deduplication**: Centralize actions in composite alarms vs individual alarms
3. **Hierarchical Design**: Build alarm hierarchies to minimize redundant monitoring

## Security Best Practices

### IAM Permissions

```ruby
# Minimum permissions for composite alarm management
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutCompositeAlarm",
        "cloudwatch:DeleteAlarms",
        "cloudwatch:DescribeAlarms"
      ],
      "Resource": "*"
    }
  ]
}
```

### Cross-Account Monitoring

```ruby
# Reference alarms from other accounts
cross_account_alarm = aws_cloudwatch_composite_alarm(:multi_account, {
  alarm_name: "cross-account-monitoring",
  alarm_rule: "ALARM(arn:aws:cloudwatch:us-east-1:123456789012:alarm:external-alarm)",
  alarm_actions: [central_monitoring_topic.arn]
})
```

## Troubleshooting Guide

### Common Issues

1. **Rule Syntax Errors**
   - Ensure balanced parentheses
   - Verify alarm names are properly quoted
   - Check operator capitalization (AND, OR, NOT)

2. **Missing Alarm References**
   - Verify referenced alarms exist
   - Check for typos in alarm names
   - Ensure proper permissions to read child alarms

3. **Actions Not Firing**
   - Verify `actions_enabled` is true
   - Check IAM permissions for action targets
   - Validate action ARN formats

### Debugging Techniques

```ruby
# Add debugging information to alarm description
debug_alarm = aws_cloudwatch_composite_alarm(:debug, {
  alarm_name: "debug-composite-alarm",
  alarm_description: <<~DESC,
    Evaluates: #{alarm_rule}
    Child alarms: #{referenced_alarms.join(', ')}
    Last modified: #{Time.now}
  DESC
  alarm_rule: complex_rule
})
```

## Future Enhancements

### Planned Features

1. **Alarm Rule Builder DSL**: Ruby DSL for building complex rules programmatically
2. **Validation Webhooks**: Pre-deployment validation of alarm rules
3. **Metrics Integration**: Direct metric queries in composite alarms
4. **Event Pattern Matching**: EventBridge integration for richer conditions

### Extension Points

The current implementation provides extension points for:
- Custom validation rules
- Rule optimization algorithms
- Action transformation pipelines
- State machine customization