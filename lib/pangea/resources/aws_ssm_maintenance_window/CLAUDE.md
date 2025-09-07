# AWS Systems Manager Maintenance Window Implementation

## Overview

The `aws_ssm_maintenance_window` resource provides type-safe AWS Systems Manager Maintenance Window management with comprehensive schedule expression validation, timezone support, and operational control features for automated maintenance operations.

## Key Features

### 1. Schedule Expression Management
- **Cron Expressions**: Full cron expression support with field validation
- **Rate Expressions**: Rate-based scheduling with minimum value constraints  
- **Schedule Parsing**: Parse and analyze schedule expressions for execution planning
- **Timezone Support**: IANA timezone specification for location-aware scheduling

### 2. Operational Controls
- **Duration Management**: Flexible window duration (1-24 hours) with cutoff controls
- **Target Association**: Control over unassociated target execution
- **Enable/Disable**: Runtime window activation control
- **Date Ranges**: Optional start/end date constraints for temporary windows

### 3. Schedule Analysis
- **Execution Estimation**: Calculate estimated monthly execution frequency
- **Schedule Parsing**: Extract and validate schedule components
- **Effective Time Calculation**: Compute actual execution time after cutoff

### 4. Validation and Safety
- **Expression Validation**: Comprehensive cron and rate expression validation
- **Time Constraint Validation**: Ensure cutoff < duration relationship
- **Date Format Validation**: ISO 8601 date format enforcement

## Type Safety Implementation

### Core Schedule Validation
```ruby
def self.new(attributes = {})
  attrs = super(attributes)
  
  schedule = attrs.schedule.strip
  
  # Validate cron expression
  if schedule.start_with?('cron(')
    unless schedule.match?(/\Acron\(\s*(\*|[0-5]?\d|\d+\-\d+|\d+(,\d+)*|\d+\/\d+)\s+(\*|[0-2]?\d|1?\d\-2?\d|\d+(,\d+)*|\d+\/\d+)\s+(\*|\?|[1-2]?\d|3[01]|\d+\-\d+|\d+(,\d+)*|L|W|\d+W|LW)\s+(\*|\?|[1-9]|1[0-2]|JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC|\d+\-\d+|\d+(,\d+)*)\s+(\*|\?|[0-6]|SUN|MON|TUE|WED|THU|FRI|SAT|\d+\-\d+|\d+(,\d+)*|L|#|\d+#\d+)\s+(\*|19[7-9]\d|20\d{2}|\d{4}\-\d{4}|\d+(,\d+)*)\s*\)\z/i)
      raise Dry::Struct::Error, "Invalid cron expression format"
    end
  # Validate rate expression
  elsif schedule.start_with?('rate(')
    unless schedule.match?(/\Arate\(\s*(\d+)\s+(minute|minutes|hour|hours|day|days)\s*\)\z/i)
      raise Dry::Struct::Error, "Invalid rate expression format"
    end
  else
    raise Dry::Struct::Error, "Schedule must be a cron() or rate() expression"
  end
  
  # ... additional validations
end
```

### Rate Value Validation
```ruby
if match
  value = match[1].to_i
  unit = match[2].downcase
  
  case unit
  when 'minute', 'minutes'
    if value < 15
      raise Dry::Struct::Error, "Rate expression minimum value for minutes is 15"
    end
  when 'hour', 'hours'
    if value < 1
      raise Dry::Struct::Error, "Rate expression minimum value for hours is 1" 
    end
  when 'day', 'days'
    if value < 1
      raise Dry::Struct::Error, "Rate expression minimum value for days is 1"
    end
  end
end
```

### Time Constraint Validation
```ruby
# Validate cutoff is less than duration
if attrs.cutoff >= attrs.duration
  raise Dry::Struct::Error, "Cutoff must be less than duration"
end

# Validate date relationship
if attrs.start_date && attrs.end_date
  start_time = DateTime.iso8601(attrs.start_date)
  end_time = DateTime.iso8601(attrs.end_date)
  
  if end_time <= start_time
    raise Dry::Struct::Error, "end_date must be after start_date"
  end
end
```

## Resource Synthesis

### Basic Configuration
```ruby
resource(:aws_ssm_maintenance_window, name) do
  maintenance_window_name window_attrs.name
  schedule window_attrs.schedule
  duration window_attrs.duration
  cutoff window_attrs.cutoff
  allow_unassociated_targets window_attrs.allow_unassociated_targets
  enabled window_attrs.enabled
end
```

### Optional Date Range
```ruby
if window_attrs.start_date
  start_date window_attrs.start_date
end

if window_attrs.end_date
  end_date window_attrs.end_date
end
```

### Schedule Configuration
```ruby
if window_attrs.schedule_timezone
  schedule_timezone window_attrs.schedule_timezone
end

if window_attrs.schedule_offset
  schedule_offset window_attrs.schedule_offset
end
```

## Helper Configurations

### Daily Maintenance Pattern
```ruby
def self.daily_maintenance_window(name, hour: 2, duration: 4, cutoff: 1)
  {
    name: name,
    schedule: "cron(0 #{hour} * * ? *)",
    duration: duration,
    cutoff: cutoff,
    description: "Daily maintenance window"
  }
end
```

### Weekly Maintenance Pattern
```ruby
def self.weekly_maintenance_window(name, day_of_week: "SUN", hour: 2, duration: 6, cutoff: 1)
  {
    name: name,
    schedule: "cron(0 #{hour} ? * #{day_of_week} *)",
    duration: duration,
    cutoff: cutoff,
    description: "Weekly maintenance window"
  }
end
```

### Business Hours Pattern
```ruby
def self.business_hours_maintenance_window(name, day_of_week: "MON-FRI", hour: 14, timezone: "America/New_York")
  {
    name: name,
    schedule: "cron(0 #{hour} ? * #{day_of_week} *)",
    duration: 4,
    cutoff: 1,
    schedule_timezone: timezone,
    description: "Business hours maintenance window"
  }
end
```

## Computed Properties

### Schedule Type Detection
```ruby
def uses_cron_schedule?
  schedule.start_with?('cron(')
end

def uses_rate_schedule?
  schedule.start_with?('rate(')
end

def schedule_type
  if uses_cron_schedule?
    'cron'
  elsif uses_rate_schedule?
    'rate'
  else
    'unknown'
  end
end
```

### Schedule Parsing
```ruby
def parsed_schedule_info
  if uses_cron_schedule?
    match = schedule.match(/\Acron\(\s*([^)]+)\s*\)\z/)
    return {} unless match
    
    fields = match[1].split(/\s+/)
    return {} unless fields.length == 6
    
    {
      minute: fields[0],
      hour: fields[1],
      day_of_month: fields[2],
      month: fields[3],
      day_of_week: fields[4],
      year: fields[5]
    }
  elsif uses_rate_schedule?
    match = schedule.match(/\Arate\(\s*(\d+)\s+(minute|minutes|hour|hours|day|days)\s*\)\z/i)
    return {} unless match
    
    {
      value: match[1].to_i,
      unit: match[2].downcase.sub(/s$/, '')
    }
  else
    {}
  end
end
```

### Execution Frequency Estimation
```ruby
def estimated_monthly_executions
  schedule_info = parsed_schedule_info
  return "Unknown" if schedule_info.empty?

  if uses_rate_schedule?
    case schedule_info[:unit]
    when 'minute'
      (30 * 24 * 60) / schedule_info[:value]
    when 'hour'
      (30 * 24) / schedule_info[:value]
    when 'day'
      30 / schedule_info[:value]
    else
      "Unknown"
    end
  elsif uses_cron_schedule?
    cron = schedule_info
    if cron[:day_of_week] != '*' && cron[:day_of_week] != '?'
      4  # Weekly pattern
    elsif cron[:day_of_month] != '*' && cron[:day_of_month] != '?'
      1  # Monthly pattern
    elsif cron[:hour] != '*'
      30 # Daily pattern
    else
      "Variable"
    end
  else
    "Unknown"
  end
end
```

### Time Calculations
```ruby
def effective_execution_time_hours
  duration - cutoff
end

def duration_hours
  duration
end

def cutoff_hours
  cutoff
end
```

## Integration Patterns

### Patch Management Integration
```ruby
# Create maintenance window for patching
patch_window = aws_ssm_maintenance_window(:weekly_patching, {
  name: "WeeklyPatchManagement",
  schedule: "cron(0 2 ? * SAT *)",  # Saturdays at 2 AM
  duration: 6,                      # 6-hour window
  cutoff: 1,                        # 1-hour cutoff
  description: "Weekly patch management window"
})

# Patch baseline for the maintenance
patch_baseline = aws_ssm_patch_baseline(:production_patches, {
  name: "ProductionPatchBaseline",
  operating_system: "AMAZON_LINUX_2",
  approved_patches_compliance_level: "HIGH",
  approval_rule: [
    {
      approve_after_days: 7,
      compliance_level: "HIGH",
      patch_filter: [
        {
          key: "CLASSIFICATION",
          values: ["Security"]
        }
      ]
    }
  ]
})

# Window could be used with maintenance window tasks (separate resources)
```

### Multi-Environment Windows
```ruby
environments = ["development", "staging", "production"]

environments.each_with_index do |env, index|
  # Stagger maintenance windows by 4 hours
  hour = 2 + (index * 4)
  
  aws_ssm_maintenance_window(:"#{env}_maintenance", {
    name: "#{env.capitalize}MaintenanceWindow",
    schedule: "cron(0 #{hour} ? * SUN *)",
    duration: env == "production" ? 8 : 4,
    cutoff: env == "production" ? 2 : 1,
    description: "#{env.capitalize} environment maintenance",
    tags: {
      Environment: env,
      MaintenanceType: "System"
    }
  })
end
```

### Emergency Maintenance Pattern
```ruby
# Emergency window (disabled by default)
emergency_window = aws_ssm_maintenance_window(:emergency, {
  name: "EmergencyMaintenanceWindow",
  schedule: "rate(30 days)",        # Fallback schedule
  duration: 12,                     # Long duration for emergencies
  cutoff: 2,
  enabled: false,                   # Disabled until needed
  allow_unassociated_targets: true, # Allow any targets
  description: "Emergency maintenance window",
  tags: {
    Purpose: "Emergency",
    AutoEnable: "false"
  }
})

# Enable in emergency situations with separate update
```

## Error Handling

### Schedule Expression Errors
- **Cron Format**: Comprehensive regex validation with specific field constraints
- **Rate Format**: Value and unit validation with minimum constraints
- **Expression Type**: Ensures expression starts with 'cron(' or 'rate('

### Time Constraint Errors
- **Cutoff Validation**: Ensures cutoff < duration relationship
- **Date Format**: ISO 8601 format validation for start/end dates
- **Date Logic**: Validates end_date > start_date when both specified

### Schedule Component Validation
- **Timezone Format**: IANA timezone name validation
- **Schedule Offset**: Only allowed with cron expressions
- **Description Length**: Maximum 128 character limit

## Output Reference Structure

```ruby
outputs: {
  id: "${aws_ssm_maintenance_window.#{name}.id}",
  name: "${aws_ssm_maintenance_window.#{name}.name}",
  arn: "${aws_ssm_maintenance_window.#{name}.arn}",
  created_date: "${aws_ssm_maintenance_window.#{name}.created_date}",
  modified_date: "${aws_ssm_maintenance_window.#{name}.modified_date}",
  enabled: "${aws_ssm_maintenance_window.#{name}.enabled}",
  schedule: "${aws_ssm_maintenance_window.#{name}.schedule}",
  schedule_timezone: "${aws_ssm_maintenance_window.#{name}.schedule_timezone}",
  duration: "${aws_ssm_maintenance_window.#{name}.duration}",
  cutoff: "${aws_ssm_maintenance_window.#{name}.cutoff}",
  description: "${aws_ssm_maintenance_window.#{name}.description}",
  tags_all: "${aws_ssm_maintenance_window.#{name}.tags_all}"
}
```

## Best Practices

### Scheduling
1. **Off-Hours Execution**: Schedule during low-usage periods
2. **Timezone Awareness**: Use appropriate timezones for global deployments
3. **Staggered Windows**: Avoid overlapping windows across environments
4. **Adequate Duration**: Allow sufficient time for completion including cutoff

### Operational Excellence
1. **Conservative Cutoff**: Provide adequate buffer time before window end
2. **Environment-Specific Settings**: Different durations for different environments
3. **Emergency Preparedness**: Maintain disabled emergency windows for incidents
4. **Monitoring Integration**: Tag windows for monitoring and alerting

### Performance
1. **Rate Limits**: Respect minimum rate expression values
2. **Target Association**: Use allow_unassociated_targets judiciously
3. **Window Sizing**: Balance execution time with service availability
4. **Schedule Optimization**: Use appropriate schedule expressions for workload patterns