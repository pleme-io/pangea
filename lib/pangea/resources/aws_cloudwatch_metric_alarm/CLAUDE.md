# AWS CloudWatch Metric Alarm Resource Implementation

## Overview

The `aws_cloudwatch_metric_alarm` resource creates CloudWatch alarms that monitor metrics and perform actions when thresholds are breached. CloudWatch supports two types of alarms: traditional metric alarms that monitor a single metric, and metric math alarms that perform calculations across multiple metrics.

## Type Safety Implementation

### Attributes Structure

```ruby
class CloudWatchMetricAlarmAttributes < Dry::Struct
  # Common attributes
  attribute :alarm_name, String.optional
  attribute :alarm_description, String.optional
  attribute :comparison_operator, String.enum(
    'GreaterThanThreshold',
    'GreaterThanOrEqualToThreshold',
    'LessThanThreshold',
    'LessThanOrEqualToThreshold',
    'LessThanLowerOrGreaterThanUpperThreshold',  # Anomaly detector
    'LessThanLowerThreshold',                     # Anomaly detector
    'GreaterThanUpperThreshold'                    # Anomaly detector
  )
  attribute :evaluation_periods, Integer
  attribute :threshold, Float.optional               # For traditional alarms
  attribute :threshold_metric_id, String.optional    # For metric math alarms
  
  # Traditional alarm attributes
  attribute :metric_name, String.optional
  attribute :namespace, String.optional
  attribute :period, Integer.optional
  attribute :statistic, String.enum(...)
  attribute :extended_statistic, String.optional     # Percentiles
  attribute :dimensions, Hash
  
  # Metric math alarm attributes
  attribute :metric_query, Array.of(MetricQuery)
  
  # Actions
  attribute :alarm_actions, Array.of(String)
  attribute :ok_actions, Array.of(String)
  attribute :insufficient_data_actions, Array.of(String)
end
```

### Key Design Decisions

1. **Alarm Type Detection**:
   - Traditional: Has `metric_name` and `namespace`
   - Metric Math: Has `metric_query` array
   - Mutually exclusive validation

2. **Threshold Validation**:
   - Traditional alarms require `threshold`
   - Metric math can use `threshold` or `threshold_metric_id`
   - Cannot specify both threshold types

3. **Statistic Exclusivity**:
   - Either `statistic` (standard) or `extended_statistic` (percentiles)
   - Cannot specify both

4. **Metric Query Structure**:
   - Each query has either `expression` or `metric`
   - Supports complex math expressions
   - Enables multi-metric calculations

5. **Anomaly Detector Support**:
   - Special comparison operators for anomaly bands
   - Detected via comparison operator type

## Resource Function Pattern

The `aws_cloudwatch_metric_alarm` function handles both alarm types:

```ruby
def aws_cloudwatch_metric_alarm(name, attributes = {})
  # 1. Validate attributes with dry-struct
  alarm_attrs = Types::CloudWatchMetricAlarmAttributes.new(attributes)
  
  # 2. Generate Terraform resource via synthesizer
  resource(:aws_cloudwatch_metric_alarm, name) do
    # Common configuration
    comparison_operator alarm_attrs.comparison_operator
    evaluation_periods alarm_attrs.evaluation_periods
    
    # Type-specific configuration
    if alarm_attrs.is_traditional_alarm?
      # Traditional metric configuration
      metric_name alarm_attrs.metric_name
      namespace alarm_attrs.namespace
      period alarm_attrs.period
      statistic alarm_attrs.statistic
      threshold alarm_attrs.threshold
      dimensions alarm_attrs.dimensions
    elsif alarm_attrs.is_metric_math_alarm?
      # Metric math configuration
      alarm_attrs.metric_query.each do |query|
        metric_query do
          # Query configuration
        end
      end
    end
  end
  
  # 3. Return ResourceReference with outputs and computed properties
  ResourceReference.new(
    type: 'aws_cloudwatch_metric_alarm',
    name: name,
    outputs: { id, arn, alarm_name, ... },
    computed_properties: { is_metric_math_alarm, uses_anomaly_detector }
  )
end
```

## Integration with Terraform Synthesizer

### Traditional Alarm
```ruby
resource(:aws_cloudwatch_metric_alarm, :high_cpu) do
  alarm_name "high-cpu-alarm"
  comparison_operator "GreaterThanThreshold"
  evaluation_periods 2
  metric_name "CPUUtilization"
  namespace "AWS/EC2"
  period 300
  statistic "Average"
  threshold 80.0
  alarm_actions ["${aws_sns_topic.alerts.arn}"]
  
  dimensions do
    InstanceId "${aws_instance.web.id}"
  end
end
```

### Metric Math Alarm
```ruby
resource(:aws_cloudwatch_metric_alarm, :error_rate) do
  alarm_name "high-error-rate"
  comparison_operator "GreaterThanThreshold"
  evaluation_periods 3
  threshold 1.0
  
  metric_query do
    id "e1"
    expression "m2/m1*100"
    return_data true
  end
  
  metric_query do
    id "m1"
    metric do
      metric_name "RequestCount"
      namespace "AWS/ApplicationELB"
      period 60
      stat "Sum"
    end
  end
end
```

## Common Usage Patterns

### 1. EC2 Instance Monitoring
```ruby
cpu_alarm = aws_cloudwatch_metric_alarm(:high_cpu, {
  alarm_name: "#{instance_name}-high-cpu",
  alarm_description: "Triggers when instance CPU exceeds 80%",
  comparison_operator: "GreaterThanThreshold",
  evaluation_periods: 2,
  metric_name: "CPUUtilization",
  namespace: "AWS/EC2",
  period: 300,
  statistic: "Average",
  threshold: 80.0,
  alarm_actions: [sns_topic.arn],
  dimensions: {
    InstanceId: instance.id
  },
  treat_missing_data: "notBreaching"
})
```

### 2. Auto Scaling Triggers
```ruby
scale_up_alarm = aws_cloudwatch_metric_alarm(:scale_up_trigger, {
  alarm_name: "asg-scale-up",
  comparison_operator: "GreaterThanThreshold",
  evaluation_periods: 1,
  metric_name: "CPUUtilization",
  namespace: "AWS/EC2",
  period: 300,
  statistic: "Average",
  threshold: 70.0,
  alarm_actions: [scale_up_policy.arn],
  dimensions: {
    AutoScalingGroupName: asg.name
  }
})
```

### 3. Application Error Rate
```ruby
error_rate_alarm = aws_cloudwatch_metric_alarm(:high_error_rate, {
  alarm_name: "application-error-rate",
  comparison_operator: "GreaterThanThreshold",
  evaluation_periods: 3,
  threshold: 5.0,
  datapoints_to_alarm: 2,
  treat_missing_data: "notBreaching",
  metric_query: [
    {
      id: "error_rate",
      expression: "(m2/m1)*100",
      label: "Error Rate Percentage",
      return_data: true
    },
    {
      id: "m1",
      metric: {
        metric_name: "RequestCount",
        namespace: "AWS/ApplicationELB",
        period: 300,
        stat: "Sum",
        dimensions: {
          LoadBalancer: alb.arn_suffix
        }
      }
    },
    {
      id: "m2",
      metric: {
        metric_name: "HTTPCode_Target_5XX_Count",
        namespace: "AWS/ApplicationELB",
        period: 300,
        stat: "Sum",
        dimensions: {
          LoadBalancer: alb.arn_suffix
        }
      }
    }
  ],
  alarm_actions: [sns_critical.arn]
})
```

### 4. Anomaly Detection
```ruby
anomaly_alarm = aws_cloudwatch_metric_alarm(:traffic_anomaly, {
  alarm_name: "unusual-traffic-pattern",
  comparison_operator: "LessThanLowerOrGreaterThanUpperThreshold",
  evaluation_periods: 2,
  threshold_metric_id: "ad1",
  metric_query: [
    {
      id: "m1",
      metric: {
        metric_name: "RequestCount",
        namespace: "AWS/ApplicationELB",
        period: 300,
        stat: "Average"
      }
    },
    {
      id: "ad1",
      expression: "ANOMALY_DETECTION_BAND(m1, 2)"
    }
  ],
  alarm_actions: [sns_anomaly.arn]
})
```

## Testing Considerations

1. **Type Validation**:
   - Test mutual exclusivity of alarm types
   - Test threshold requirements
   - Test statistic/extended_statistic exclusivity
   - Test comparison operator enums

2. **Metric Query Validation**:
   - Test expression vs metric exclusivity
   - Test return_data flag handling
   - Test metric query ID uniqueness

3. **Nested Structure Generation**:
   - Verify metric query block nesting
   - Test dimension handling
   - Test conditional attribute inclusion

4. **Edge Cases**:
   - Empty metric_query array
   - Missing required traditional alarm fields
   - Invalid datapoints_to_alarm values

## Future Enhancements

1. **Enhanced Validation**:
   - Validate metric math expressions
   - Check dimension key/value formats
   - Validate namespace against known AWS namespaces

2. **Composite Alarms**:
   - Support for composite alarm resources
   - Alarm dependency management
   - Complex alarm hierarchies

3. **Computed Properties**:
   - Estimated alarm frequency
   - Cost estimation based on metrics
   - Alarm state predictions

4. **Helper Methods**:
   - Common alarm templates
   - Metric math expression builders
   - Anomaly detection configuration helpers