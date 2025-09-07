# AWS AppStream Fleet - Implementation Notes

## Resource Overview

The `aws_appstream_fleet` resource manages Amazon AppStream 2.0 fleets, which provide scalable application streaming infrastructure. Unlike WorkSpaces (persistent desktops), AppStream provides non-persistent application streaming sessions.

## Architectural Considerations

### AppStream vs WorkSpaces
- **AppStream**: Application streaming, non-persistent, session-based
- **WorkSpaces**: Full desktop, persistent, user-assigned
- **Use Case**: AppStream for apps, WorkSpaces for desktops

### Fleet Architecture
```
Fleet → Instances → Sessions → Users
         ↓
      App Image → Applications
         ↓
    Stack Association → User Access
```

### Instance Lifecycle
- **ON_DEMAND**: Instances start on user connection
- **ALWAYS_ON**: Instances run continuously
- **Scaling**: Managed automatically by AppStream

## Implementation Details

### Fleet Name Validation

```ruby
attribute :name, Resources::Types::String.constrained(
  min_size: 1,
  max_size: 100,
  format: /\A[a-zA-Z0-9][a-zA-Z0-9_-]*\z/
)
```

### Instance Type Validation

```ruby
attribute :instance_type, Resources::Types::String.constrained(
  format: /\Astream\.[a-z0-9]+\.[a-z0-9]+\z/
)
```

Ensures valid AppStream instance type format.

### Image Configuration Validation

```ruby
def self.new(attributes)
  attrs = attributes.is_a?(Hash) ? attributes : {}
  
  # Must specify either image_name or image_arn
  if !attrs[:image_name] && !attrs[:image_arn]
    raise Dry::Struct::Error, "Either image_name or image_arn must be specified"
  end
  
  if attrs[:image_name] && attrs[:image_arn]
    raise Dry::Struct::Error, "Cannot specify both image_name and image_arn"
  end
  
  super(attrs)
end
```

### Cost Estimation

```ruby
def estimated_monthly_cost
  hourly_rate = case instance_type
               when /stream\.standard\.small/ then 0.08
               when /stream\.standard\.medium/ then 0.16
               # ... other instance types
               end
  
  if always_on?
    hourly_rate * 730 * compute_capacity.desired_instances
  else
    # Estimate 8 hours/day, 22 days/month for on-demand
    hourly_rate * 8 * 22 * compute_capacity.desired_instances
  end
end
```

## Advanced Usage Patterns

### 1. Application-Specific Fleet Strategy
```ruby
def create_app_specific_fleet(app_type, image_id)
  case app_type
  when :office_apps
    aws_appstream_fleet(:office_fleet, {
      name: "OfficeAppsFleet",
      instance_type: "stream.standard.medium",
      fleet_type: "ON_DEMAND",
      compute_capacity: { desired_instances: 5 },
      image_name: image_id,
      stream_view: "APP",
      max_user_duration_in_seconds: 28800  # 8 hours
    })
  when :engineering_tools
    aws_appstream_fleet(:engineering_fleet, {
      name: "EngineeringToolsFleet",
      instance_type: "stream.compute.xlarge",
      fleet_type: "ALWAYS_ON",
      compute_capacity: { desired_instances: 10 },
      image_name: image_id,
      stream_view: "DESKTOP",
      max_user_duration_in_seconds: 43200  # 12 hours
    })
  when :graphics_apps
    aws_appstream_fleet(:graphics_fleet, {
      name: "GraphicsAppsFleet",
      instance_type: "stream.graphics.g4dn.xlarge",
      fleet_type: "ON_DEMAND",
      compute_capacity: { desired_instances: 3 },
      image_name: image_id,
      stream_view: "DESKTOP",
      enable_default_internet_access: false
    })
  end
end
```

### 2. Multi-Region Fleet Deployment
```ruby
def deploy_global_fleet(regions, base_config)
  regions.map do |region, region_config|
    aws_appstream_fleet(:"fleet_#{region}", base_config.merge({
      name: "Fleet-#{region.upcase}",
      description: "Fleet for #{region_config[:description]}",
      compute_capacity: {
        desired_instances: region_config[:capacity]
      },
      vpc_config: {
        subnet_ids: region_config[:subnet_ids],
        security_group_ids: region_config[:security_group_ids]
      },
      tags: base_config[:tags].merge({
        Region: region.to_s,
        Timezone: region_config[:timezone]
      })
    }))
  end
end

# Usage
global_fleets = deploy_global_fleet({
  us_east: {
    description: "US East Coast",
    capacity: 10,
    subnet_ids: [us_east_subnet_a.id, us_east_subnet_b.id],
    security_group_ids: [us_east_sg.id],
    timezone: "America/New_York"
  },
  eu_west: {
    description: "Europe West",
    capacity: 8,
    subnet_ids: [eu_west_subnet_a.id, eu_west_subnet_b.id],
    security_group_ids: [eu_west_sg.id],
    timezone: "Europe/London"
  }
}, {
  instance_type: "stream.standard.large",
  fleet_type: "ON_DEMAND",
  image_name: "GlobalApps-v1"
})
```

### 3. Environment-Based Fleet Configuration
```ruby
def create_environment_fleet(environment, image_name)
  base_config = {
    image_name: image_name,
    stream_view: "APP"
  }
  
  case environment
  when :production
    aws_appstream_fleet(:prod_fleet, base_config.merge({
      name: "Production-Fleet",
      instance_type: "stream.compute.large",
      fleet_type: "ALWAYS_ON",
      compute_capacity: { desired_instances: 20 },
      vpc_config: {
        subnet_ids: [prod_subnet_a.id, prod_subnet_b.id],
        security_group_ids: [prod_sg.id]
      },
      enable_default_internet_access: false,
      max_user_duration_in_seconds: 28800,
      idle_disconnect_timeout_in_seconds: 900,
      tags: {
        Environment: "Production",
        CriticalityLevel: "High",
        BackupRequired: "true"
      }
    }))
  when :staging
    aws_appstream_fleet(:staging_fleet, base_config.merge({
      name: "Staging-Fleet",
      instance_type: "stream.standard.medium",
      fleet_type: "ON_DEMAND",
      compute_capacity: { desired_instances: 5 },
      enable_default_internet_access: true,
      max_user_duration_in_seconds: 14400,
      tags: {
        Environment: "Staging",
        CriticalityLevel: "Medium"
      }
    }))
  when :development
    aws_appstream_fleet(:dev_fleet, base_config.merge({
      name: "Development-Fleet",
      instance_type: "stream.standard.small",
      fleet_type: "ON_DEMAND",
      compute_capacity: { desired_instances: 2 },
      enable_default_internet_access: true,
      idle_disconnect_timeout_in_seconds: 300,
      tags: {
        Environment: "Development",
        CriticalityLevel: "Low"
      }
    }))
  end
end
```

### 4. Domain-Joined Fleet Pattern
```ruby
def create_domain_joined_fleet(domain_config)
  aws_appstream_fleet(:domain_fleet, {
    name: "DomainJoined-Fleet",
    instance_type: domain_config[:instance_type],
    fleet_type: "ALWAYS_ON",
    compute_capacity: {
      desired_instances: domain_config[:capacity]
    },
    image_name: domain_config[:image_name],
    vpc_config: {
      subnet_ids: domain_config[:subnet_ids],
      security_group_ids: [domain_sg.id]
    },
    domain_join_info: {
      directory_name: domain_config[:directory_name],
      organizational_unit_distinguished_name: domain_config[:ou_dn]
    },
    enable_default_internet_access: false,
    tags: {
      DomainJoined: "true",
      Directory: domain_config[:directory_name],
      SecurityCompliance: "Required"
    }
  })
end
```

## Integration Patterns

### With AppStream Stack
```ruby
# Create fleet
fleet = aws_appstream_fleet(:app_fleet, {
  name: "ApplicationFleet",
  instance_type: "stream.standard.large",
  compute_capacity: { desired_instances: 5 },
  image_name: "MyApps"
})

# Create stack (separate resource)
stack = aws_appstream_stack(:app_stack, {
  name: "ApplicationStack"
})

# Associate fleet with stack
fleet_stack_association = aws_appstream_fleet_stack_association(:association, {
  fleet_name: fleet.name,
  stack_name: stack.name
})
```

### With Custom Images
```ruby
# Reference custom image
custom_image = aws_appstream_image(:custom_app, {
  name: "CustomApp-v2",
  base_image_arn: "arn:aws:appstream:us-east-1::image/AppStream-WinServer2019-01-01-2024"
})

# Use in fleet
fleet = aws_appstream_fleet(:custom_fleet, {
  name: "CustomAppFleet",
  instance_type: "stream.standard.medium",
  compute_capacity: { desired_instances: 3 },
  image_arn: custom_image.arn
})
```

## Performance Optimization

### Instance Type Selection
```ruby
def select_instance_type(workload_profile)
  case workload_profile
  when :light_office
    "stream.standard.small"  # Basic office apps
  when :standard_office
    "stream.standard.medium"  # Standard productivity
  when :power_user
    "stream.compute.large"  # Development, analysis
  when :graphics_2d
    "stream.graphics.g4dn.xlarge"  # 2D CAD, design
  when :graphics_3d
    "stream.graphics.g4dn.4xlarge"  # 3D modeling
  when :rendering
    "stream.graphics-pro.16xlarge"  # Heavy rendering
  when :memory_intensive
    "stream.memory.4xlarge"  # Large datasets
  else
    "stream.standard.medium"  # Default
  end
end
```

### Capacity Planning
```ruby
def calculate_fleet_capacity(user_count, concurrency_rate, buffer_percentage)
  # Calculate required instances
  concurrent_users = (user_count * concurrency_rate).ceil
  buffer = (concurrent_users * buffer_percentage).ceil
  total_instances = concurrent_users + buffer
  
  # Recommendations based on total
  {
    desired_instances: total_instances,
    fleet_type: total_instances > 10 ? "ALWAYS_ON" : "ON_DEMAND",
    instance_type: select_instance_type_by_capacity(total_instances),
    estimated_monthly_cost: estimate_cost(total_instances, fleet_type)
  }
end
```

## Monitoring and Metrics

### Key CloudWatch Metrics
- `CapacityUtilization` - Percentage of fleet capacity in use
- `AvailableCapacity` - Number of available instances
- `RunningCapacity` - Number of running instances
- `InsufficientCapacityError` - Capacity errors
- `SessionDuration` - Average session length

### Alerting Configuration
```ruby
def create_fleet_alarms(fleet)
  # High utilization alarm
  cloudwatch_alarm(:high_utilization, {
    alarm_name: "AppStream-Fleet-#{fleet.name}-HighUtilization",
    metric_name: "CapacityUtilization",
    namespace: "AWS/AppStream",
    statistic: "Average",
    period: 300,
    evaluation_periods: 2,
    threshold: 90,
    comparison_operator: "GreaterThanThreshold",
    dimensions: {
      Fleet: fleet.name
    }
  })
  
  # Insufficient capacity alarm
  cloudwatch_alarm(:capacity_error, {
    alarm_name: "AppStream-Fleet-#{fleet.name}-CapacityError",
    metric_name: "InsufficientCapacityError",
    namespace: "AWS/AppStream",
    statistic: "Sum",
    period: 60,
    evaluation_periods: 1,
    threshold: 1,
    comparison_operator: "GreaterThanOrEqualToThreshold"
  })
end
```

## Best Practices

### 1. Fleet Design
- Size fleets based on concurrent usage, not total users
- Use ON_DEMAND for variable workloads
- Use ALWAYS_ON for predictable, high-volume usage
- Deploy across multiple AZs

### 2. Image Management
- Version images with clear naming conventions
- Test images thoroughly before fleet deployment
- Keep base OS and applications updated
- Minimize image size for faster streaming

### 3. Network Configuration
- Always use VPC for production fleets
- Disable internet access unless required
- Use security groups for least-privilege access
- Consider AWS PrivateLink for service access

### 4. Session Management
- Set appropriate idle timeouts
- Configure max session duration based on workload
- Monitor session metrics
- Plan for session persistence needs

## Troubleshooting

### Common Issues

1. **Fleet Stuck in STARTING State**
   - Check image availability
   - Verify VPC/subnet configuration
   - Review security group rules
   - Check service limits

2. **Users Cannot Connect**
   - Verify fleet-stack association
   - Check user pool assignment
   - Validate network connectivity
   - Review IAM permissions

3. **Performance Issues**
   - Monitor instance metrics
   - Check network latency
   - Review instance type selection
   - Verify image optimization

### Fleet States
```
STARTING → RUNNING → STOPPING → STOPPED
            ↓
         DELETING → DELETED
            ↓
          ERROR
```

## Cost Management

### Optimization Strategies
1. **Right-size instances** based on actual usage
2. **Use ON_DEMAND** for variable workloads
3. **Schedule ALWAYS_ON** fleets (stop during off-hours)
4. **Monitor utilization** and adjust capacity
5. **Set idle timeouts** to release unused sessions

### Cost Calculation Example
```ruby
def calculate_monthly_cost(fleet_config)
  instance_cost = get_instance_hourly_rate(fleet_config[:instance_type])
  
  if fleet_config[:fleet_type] == "ALWAYS_ON"
    # 24/7 operation
    monthly_hours = 730
    instance_cost * monthly_hours * fleet_config[:desired_instances]
  else
    # Estimate based on usage pattern
    daily_hours = fleet_config[:estimated_daily_hours] || 8
    monthly_days = fleet_config[:estimated_monthly_days] || 22
    instance_cost * daily_hours * monthly_days * fleet_config[:desired_instances]
  end
end
```