# AWS Auto Scaling Schedule Implementation

## Overview

The `aws_autoscaling_schedule` resource creates scheduled scaling actions for Auto Scaling Groups, enabling automatic capacity adjustments at specific times or on recurring schedules. This implementation provides comprehensive validation for cron expressions, datetime formats, and capacity constraints.

## Key Features

### Schedule Types Supported
- **One-time actions**: Using `start_time` and optional `end_time`
- **Recurring actions**: Using `recurrence` with cron expressions
- **Mixed scheduling**: Combining fixed times with recurring patterns

### Validation Features
- **Cron Expression Validation**: Full 5-field cron syntax validation
- **ISO 8601 DateTime Validation**: Proper datetime format checking
- **Time Zone Validation**: Support for standard time zone identifiers
- **Capacity Constraint Validation**: Ensures logical size relationships
- **Schedule Requirement Validation**: Ensures valid scheduling configuration

## Implementation Details

### Type System Architecture

```ruby
class AutoScalingScheduleAttributes < Dry::Struct
  # Schedule configuration validation
  def self.new(attributes)
    # Validates at least one schedule method is specified
    # Validates at least one capacity parameter is specified
    # Validates capacity relationships (min ≤ desired ≤ max)
    # Validates cron expression syntax
    # Validates ISO 8601 datetime format
    # Validates time zone identifiers
  end
end
```

### Cron Expression Validation

The implementation includes comprehensive cron validation:

```ruby
def self.valid_cron_expression?(cron)
  fields = cron.split(/\s+/)
  return false unless fields.length == 5
  
  minute, hour, day_of_month, month, day_of_week = fields
  
  valid_minute?(minute) &&
    valid_hour?(hour) &&
    valid_day_of_month?(day_of_month) &&
    valid_month?(month) &&
    valid_day_of_week?(day_of_week)
end
```

**Supported Cron Features:**
- Wildcards (`*`)
- Numeric values (`5`, `23`)
- Ranges (`1-5`, `9-17`)
- Step values (`*/15`, `2-58/2`)
- Lists (`1,3,5`, `MON,WED,FRI`)

### Time Zone Support

Validates common AWS-supported time zones:
- **UTC/GMT**: Universal time zones
- **US Zones**: `US/Eastern`, `US/Central`, `US/Mountain`, `US/Pacific`
- **Regional**: `Europe/London`, `Asia/Tokyo`, `Australia/Sydney`
- **Offset Format**: `+05:00`, `-08:00`

### Capacity Validation

Enforces logical capacity relationships:
```ruby
# Validates size constraints
if attrs[:min_size] && attrs[:max_size] && attrs[:min_size] > attrs[:max_size]
  raise Dry::Struct::Error, "min_size cannot be greater than max_size"
end

# Validates desired capacity within bounds
if attrs[:desired_capacity]
  min = attrs[:min_size]
  max = attrs[:max_size]
  
  if min && attrs[:desired_capacity] < min
    raise Dry::Struct::Error, "desired_capacity cannot be less than min_size"
  end
  
  if max && attrs[:desired_capacity] > max
    raise Dry::Struct::Error, "desired_capacity cannot be greater than max_size"
  end
end
```

## Integration Patterns

### With Auto Scaling Groups
```ruby
# Create ASG first
web_asg = aws_autoscaling_group(:web_servers, {
  min_size: 2,
  max_size: 20,
  desired_capacity: 5,
  # ... other configuration
})

# Create schedule that references the ASG
aws_autoscaling_schedule(:business_hours_scale_up, {
  auto_scaling_group_name: web_asg.name,  # Reference ASG by name
  recurrence: "0 9 * * 1-5",
  desired_capacity: 10,
  min_size: 5,
  max_size: 15,
  time_zone: "US/Eastern"
})
```

### Multiple Schedule Coordination
```ruby
# Morning scale-up
aws_autoscaling_schedule(:morning_scale_up, {
  auto_scaling_group_name: ref(:aws_autoscaling_group, :api_asg, :name),
  recurrence: "0 8 * * 1-5",
  desired_capacity: 10
})

# Lunch traffic spike
aws_autoscaling_schedule(:lunch_scale_up, {
  auto_scaling_group_name: ref(:aws_autoscaling_group, :api_asg, :name),
  recurrence: "0 12 * * 1-5",
  desired_capacity: 15
})

# Evening scale-down
aws_autoscaling_schedule(:evening_scale_down, {
  auto_scaling_group_name: ref(:aws_autoscaling_group, :api_asg, :name),
  recurrence: "0 18 * * 1-5",
  desired_capacity: 5
})
```

## Production Considerations

### Cost Optimization Patterns
- **Development Environment Scheduling**: Shut down non-production instances overnight
- **Weekend Scaling**: Adjust capacity based on weekend traffic patterns
- **Seasonal Scaling**: Pre-scale for known traffic events (Black Friday, etc.)

### Operational Excellence
- **Descriptive Naming**: Use clear, descriptive names for scheduled actions
- **Time Zone Consistency**: Use consistent time zones across related schedules
- **Monitoring Integration**: Coordinate with CloudWatch alarms and notifications
- **Testing Strategy**: Test schedules in staging environments first

### High Availability Considerations
- **Gradual Scaling**: Use multiple schedules for gradual capacity changes
- **Overlap Management**: Ensure schedules don't conflict with each other
- **Emergency Overrides**: Maintain ability to manually override scheduled actions
- **Cross-AZ Distribution**: Consider availability zone distribution during scaling

## Error Handling

The implementation provides detailed error messages for common configuration issues:

```ruby
# Schedule validation errors
"Scheduled action must specify at least one of: start_time, end_time, or recurrence"
"Scheduled action must specify at least one of: min_size, max_size, or desired_capacity"

# Capacity validation errors  
"min_size (5) cannot be greater than max_size (3)"
"desired_capacity (10) cannot be greater than max_size (8)"

# Format validation errors
"Invalid cron expression format for recurrence: 0 25 * * *"  # Invalid hour
"Invalid ISO 8601 datetime format for start_time: 2024-13-01"  # Invalid month
"Invalid time zone format: US/NonExistent"
```

## Testing Strategy

### Unit Tests
- Cron expression validation for all supported formats
- ISO 8601 datetime parsing and validation
- Time zone identifier validation
- Capacity constraint validation
- Edge cases and error conditions

### Integration Tests
- Schedule creation with Auto Scaling Groups
- Multiple schedule coordination
- Time zone handling across different regions
- Schedule modification and deletion

### Production Validation
- Monitoring scheduled action execution
- Verifying capacity changes occur as scheduled
- Validating time zone handling in production
- Testing schedule modification workflows

## Terraform Resource Mapping

Maps to AWS Terraform resource `aws_autoscaling_schedule`:

```hcl
resource "aws_autoscaling_schedule" "business_hours_scale_up" {
  scheduled_action_name  = "business-hours-scale-up"
  auto_scaling_group_name = aws_autoscaling_group.web_servers.name
  recurrence            = "0 9 * * 1-5"
  desired_capacity      = 10
  min_size             = 5  
  max_size             = 15
  time_zone            = "US/Eastern"
}
```

This implementation ensures reliable, validated scheduled scaling actions that integrate seamlessly with Auto Scaling Groups and provide robust operational capabilities for production workloads.