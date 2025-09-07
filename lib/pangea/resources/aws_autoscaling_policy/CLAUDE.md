# AWS Auto Scaling Policy Resource Implementation

## Overview

The `aws_autoscaling_policy` resource creates scaling policies for Auto Scaling Groups that define when and how to scale. AWS supports four types of scaling policies: Simple Scaling, Step Scaling, Target Tracking Scaling, and Predictive Scaling. Each type offers different capabilities for responding to changing demand.

## Type Safety Implementation

### Attributes Structure

```ruby
class AutoScalingPolicyAttributes < Dry::Struct
  # Required
  attribute :autoscaling_group_name, String
  attribute :name, String.optional
  
  # Policy type determines valid attributes
  attribute :policy_type, String.enum(
    'SimpleScaling',      # Basic scaling by fixed amount
    'StepScaling',        # Scaling by ranges
    'TargetTrackingScaling',  # Maintain target metric
    'PredictiveScaling'   # ML-based prediction
  )
  
  # Simple/Step scaling attributes
  attribute :adjustment_type, String.enum(
    'ChangeInCapacity',        # Add/remove specific count
    'ExactCapacity',          # Set to specific count
    'PercentChangeInCapacity' # Scale by percentage
  )
  attribute :scaling_adjustment, Integer       # For SimpleScaling
  attribute :step_adjustments, Array          # For StepScaling
  
  # Target tracking
  attribute :target_tracking_configuration, TargetTrackingConfiguration
  
  # Predictive scaling
  attribute :predictive_scaling_configuration, PredictiveScalingConfiguration
end
```

### Key Design Decisions

1. **Policy Type Validation**:
   - Each policy type has specific required attributes
   - Validation ensures incompatible attributes aren't mixed
   - Clear error messages for configuration issues

2. **Nested Configuration Types**:
   - `StepAdjustment`: Defines scaling steps based on metric ranges
   - `TargetTrackingConfiguration`: Maintains a target metric value
   - `PredictiveScalingConfiguration`: ML-based scaling settings

3. **Metric Specifications**:
   - Predefined metrics (CPU, Network, Request Count)
   - Custom CloudWatch metrics with dimensions
   - Validation ensures exactly one metric type

4. **Type-Specific Validations**:
   - SimpleScaling requires adjustment_type and scaling_adjustment
   - StepScaling requires step_adjustments array
   - TargetTracking prohibits manual adjustment settings

5. **Computed Properties**:
   - `is_simple_scaling?`, `is_step_scaling?`, etc.
   - Helps templates make decisions based on policy type

## Resource Function Pattern

The `aws_autoscaling_policy` function handles multiple policy types:

```ruby
def aws_autoscaling_policy(name, attributes = {})
  # 1. Validate attributes with dry-struct
  policy_attrs = Types::AutoScalingPolicyAttributes.new(attributes)
  
  # 2. Generate Terraform resource via synthesizer
  resource(:aws_autoscaling_policy, name) do
    autoscaling_group_name policy_attrs.autoscaling_group_name
    policy_type policy_attrs.policy_type
    
    # Type-specific configuration
    case policy_attrs.policy_type
    when 'SimpleScaling'
      # Simple scaling attributes
    when 'StepScaling'
      # Step adjustments blocks
    when 'TargetTrackingScaling'
      # Target tracking configuration block
    when 'PredictiveScaling'
      # Predictive scaling configuration block
    end
  end
  
  # 3. Return ResourceReference with outputs and computed properties
  ResourceReference.new(
    type: 'aws_autoscaling_policy',
    name: name,
    outputs: { id, arn, name, adjustment_type, policy_type },
    computed_properties: { is_simple_scaling, is_target_tracking, ... }
  )
end
```

## Integration with Terraform Synthesizer

Different policy types generate different configurations:

### Simple Scaling
```ruby
resource(:aws_autoscaling_policy, :scale_up) do
  autoscaling_group_name "web-asg"
  policy_type "SimpleScaling"
  adjustment_type "ChangeInCapacity"
  scaling_adjustment 2
  cooldown 300
end
```

### Target Tracking
```ruby
resource(:aws_autoscaling_policy, :cpu_target) do
  autoscaling_group_name "web-asg"
  policy_type "TargetTrackingScaling"
  
  target_tracking_configuration do
    target_value 70.0
    
    predefined_metric_specification do
      predefined_metric_type "ASGAverageCPUUtilization"
    end
  end
end
```

## Common Usage Patterns

### 1. Simple Scaling Policies
```ruby
# Scale up policy
scale_up = aws_autoscaling_policy(:scale_up, {
  autoscaling_group_name: asg.name,
  policy_type: "SimpleScaling",
  adjustment_type: "ChangeInCapacity",
  scaling_adjustment: 2,
  cooldown: 300
})

# Scale down policy
scale_down = aws_autoscaling_policy(:scale_down, {
  autoscaling_group_name: asg.name,
  policy_type: "SimpleScaling",
  adjustment_type: "ChangeInCapacity",
  scaling_adjustment: -1,
  cooldown: 600
})
```

### 2. Step Scaling Policy
```ruby
step_policy = aws_autoscaling_policy(:cpu_steps, {
  autoscaling_group_name: asg.name,
  policy_type: "StepScaling",
  adjustment_type: "PercentChangeInCapacity",
  metric_aggregation_type: "Average",
  step_adjustments: [
    {
      metric_interval_lower_bound: 0,
      metric_interval_upper_bound: 10,
      scaling_adjustment: 10
    },
    {
      metric_interval_lower_bound: 10,
      metric_interval_upper_bound: 20,
      scaling_adjustment: 20
    },
    {
      metric_interval_lower_bound: 20,
      scaling_adjustment: 30
    }
  ]
})
```

### 3. Target Tracking Policies
```ruby
# CPU utilization tracking
cpu_policy = aws_autoscaling_policy(:cpu_tracking, {
  autoscaling_group_name: asg.name,
  policy_type: "TargetTrackingScaling",
  target_tracking_configuration: {
    target_value: 70.0,
    predefined_metric_specification: {
      predefined_metric_type: "ASGAverageCPUUtilization"
    },
    scale_in_cooldown: 300,
    scale_out_cooldown: 60
  }
})

# ALB request count tracking
alb_policy = aws_autoscaling_policy(:request_tracking, {
  autoscaling_group_name: asg.name,
  policy_type: "TargetTrackingScaling",
  target_tracking_configuration: {
    target_value: 1000.0,
    predefined_metric_specification: {
      predefined_metric_type: "ALBRequestCountPerTarget",
      resource_label: alb_arn
    }
  }
})
```

### 4. Custom Metric Target Tracking
```ruby
custom_policy = aws_autoscaling_policy(:custom_metric, {
  autoscaling_group_name: asg.name,
  policy_type: "TargetTrackingScaling",
  target_tracking_configuration: {
    target_value: 50.0,
    customized_metric_specification: {
      metric_name: "ActiveConnections",
      namespace: "MyApp/Metrics",
      statistic: "Average",
      unit: "Count",
      dimensions: {
        Service: "WebServer",
        Environment: "Production"
      }
    }
  }
})
```

## Testing Considerations

1. **Type Validation**:
   - Test policy type specific requirements
   - Test invalid attribute combinations
   - Test metric specification validation

2. **Nested Structure Generation**:
   - Verify step adjustments array handling
   - Test target tracking configuration blocks
   - Test metric specification nesting

3. **Terraform Generation**:
   - Verify type-specific block generation
   - Test conditional attribute inclusion
   - Test complex nested structures

4. **Edge Cases**:
   - Empty step adjustments array
   - Conflicting cooldown settings
   - Invalid metric bounds

## Future Enhancements

1. **Enhanced Validation**:
   - Step adjustment bound validation
   - Metric value range validation
   - Cross-policy conflict detection

2. **Predictive Scaling Support**:
   - Full metric specification types
   - ML configuration options
   - Forecast visualization helpers

3. **Policy Coordination**:
   - Multiple policy interaction helpers
   - Conflict detection between policies
   - Policy priority management

4. **Advanced Features**:
   - Warm pool integration
   - Instance refresh coordination
   - Multi-metric target tracking