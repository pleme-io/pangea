# AWS Auto Scaling Group Resource Implementation

## Overview

The `aws_autoscaling_group` resource creates an AWS Auto Scaling Group (ASG) that automatically adjusts the number of EC2 instances based on demand. Auto Scaling Groups ensure application availability and allow you to scale EC2 capacity up or down automatically according to conditions you define.

## Type Safety Implementation

### Attributes Structure

```ruby
class AutoScalingGroupAttributes < Dry::Struct
  # Required sizing
  attribute :min_size, Integer.constrained(gteq: 0)
  attribute :max_size, Integer.constrained(gteq: 0)
  
  # Optional sizing
  attribute :desired_capacity, Integer.optional
  attribute :default_cooldown, Integer.default(300)
  
  # Launch configuration (one required)
  attribute :launch_configuration, String.optional
  attribute :launch_template, LaunchTemplateSpecification.optional
  attribute :mixed_instances_policy, Hash.optional
  
  # Network configuration
  attribute :vpc_zone_identifier, Array.of(String)
  attribute :availability_zones, Array.of(String)
  
  # Health checks
  attribute :health_check_type, String.enum('EC2', 'ELB')
  attribute :health_check_grace_period, Integer
  
  # Tags
  attribute :tags, Array.of(AutoScalingTag)
end
```

### Key Design Decisions

1. **Launch Configuration Flexibility**:
   - Supports launch configurations (legacy)
   - Supports launch templates (recommended)
   - Supports mixed instances policy (spot/on-demand)
   - Validates exactly one is specified

2. **Network Configuration Validation**:
   - Requires either `vpc_zone_identifier` (VPC) or `availability_zones` (EC2-Classic)
   - Most users will use `vpc_zone_identifier` with subnet IDs

3. **Capacity Validation**:
   - Ensures `min_size` ≤ `max_size`
   - Ensures `min_size` ≤ `desired_capacity` ≤ `max_size`
   - Default `desired_capacity` to `min_size` if not specified

4. **Tag Structure**:
   - Uses `AutoScalingTag` type with `key`, `value`, and `propagate_at_launch`
   - Converts to array format expected by Terraform

5. **Computed Properties**:
   - `uses_launch_template?`: Whether using launch templates
   - `uses_mixed_instances?`: Whether using mixed instances
   - `uses_target_groups?`: Whether attached to ALB/NLB
   - `uses_classic_load_balancers?`: Whether attached to CLB

## Resource Function Pattern

The `aws_autoscaling_group` function handles complex nested configurations:

```ruby
def aws_autoscaling_group(name, attributes = {})
  # 1. Validate attributes with dry-struct
  asg_attrs = Types::AutoScalingGroupAttributes.new(attributes)
  
  # 2. Generate Terraform resource via synthesizer
  resource(:aws_autoscaling_group, name) do
    # Required attributes
    min_size asg_attrs.min_size
    max_size asg_attrs.max_size
    
    # Conditional launch configuration
    if asg_attrs.launch_template
      launch_template do
        id asg_attrs.launch_template.id if asg_attrs.launch_template.id
        name asg_attrs.launch_template.name if asg_attrs.launch_template.name
        version asg_attrs.launch_template.version
      end
    end
    
    # Tag handling - convert to array format
    tag asg_attrs.tags.map(&:to_h) if asg_attrs.tags.any?
  end
  
  # 3. Return ResourceReference with outputs and computed properties
  ResourceReference.new(
    type: 'aws_autoscaling_group',
    name: name,
    outputs: { id, arn, name, desired_capacity, ... },
    computed_properties: { uses_launch_template, uses_target_groups, ... }
  )
end
```

## Integration with Terraform Synthesizer

The resource handles various configuration patterns:

```ruby
resource(:aws_autoscaling_group, name) do
  # Basic configuration
  min_size 2
  max_size 10
  desired_capacity 4
  
  # Launch template block
  launch_template do
    id "${aws_launch_template.web.id}"
    version "$Latest"
  end
  
  # Network configuration
  vpc_zone_identifier ["${aws_subnet.private_a.id}", "${aws_subnet.private_b.id}"]
  
  # Health checks
  health_check_type "ELB"
  health_check_grace_period 300
  
  # Tags as array
  tag [
    { key: "Name", value: "web-server", propagate_at_launch: true },
    { key: "Environment", value: "production", propagate_at_launch: true }
  ]
  
  # Target groups for ALB
  target_group_arns ["${aws_lb_target_group.web.arn}"]
end
```

## Common Usage Patterns

### 1. Basic Web Application ASG
```ruby
asg = aws_autoscaling_group(:web, {
  min_size: 2,
  max_size: 10,
  desired_capacity: 4,
  vpc_zone_identifier: [subnet_a.id, subnet_b.id],
  launch_template: {
    id: web_template.id,
    version: "$Latest"
  },
  health_check_type: "ELB",
  health_check_grace_period: 300,
  target_group_arns: [web_tg.arn],
  tags: [
    { key: "Name", value: "web-asg", propagate_at_launch: true }
  ]
})
```

### 2. ASG with Mixed Instances (Spot + On-Demand)
```ruby
asg = aws_autoscaling_group(:mixed, {
  min_size: 3,
  max_size: 20,
  mixed_instances_policy: {
    launch_template: {
      launch_template_specification: {
        launch_template_id: base_template.id,
        version: "$Latest"
      },
      overrides: [
        { instance_type: "t3.medium" },
        { instance_type: "t3.large" },
        { instance_type: "t3a.medium" },
        { instance_type: "t3a.large" }
      ]
    },
    instances_distribution: {
      on_demand_base_capacity: 2,
      on_demand_percentage_above_base_capacity: 20,
      spot_allocation_strategy: "lowest-price",
      spot_instance_pools: 4
    }
  }
})
```

### 3. ASG with Instance Refresh
```ruby
asg = aws_autoscaling_group(:refreshable, {
  min_size: 3,
  max_size: 9,
  vpc_zone_identifier: private_subnets,
  launch_template: { id: app_template.id },
  instance_refresh: {
    min_healthy_percentage: 90,
    instance_warmup: 120,
    checkpoint_percentages: [50],
    checkpoint_delay: 300
  }
})
```

### 4. ASG with Lifecycle Hooks
```ruby
asg = aws_autoscaling_group(:lifecycle, {
  min_size: 1,
  max_size: 5,
  vpc_zone_identifier: [subnet.id],
  launch_template: { name: "app-template" },
  max_instance_lifetime: 604800, # 7 days
  protect_from_scale_in: true,
  termination_policies: ["OldestInstance", "Default"]
})
```

## Testing Considerations

1. **Type Validation**:
   - Test size constraint validation (min/max/desired)
   - Test launch configuration mutual exclusivity
   - Test network configuration requirements
   - Test tag structure validation

2. **Nested Structure Generation**:
   - Verify launch template block generation
   - Test tag array format conversion
   - Test instance refresh preferences
   - Test mixed instances policy

3. **Terraform Generation**:
   - Verify conditional attribute inclusion
   - Test array handling for subnets and tags
   - Test nested block syntax

4. **Edge Cases**:
   - ASG with no desired capacity specified
   - Multiple availability zones vs VPC subnets
   - Empty tag arrays
   - Complex mixed instances policies

## Future Enhancements

1. **Enhanced Validation**:
   - Subnet availability zone consistency
   - Target group compatibility checks
   - Launch template version validation

2. **Computed Properties**:
   - Estimated costs based on instance types
   - Capacity utilization metrics
   - Scaling policy recommendations

3. **Helper Methods**:
   - Scaling policy builders
   - Lifecycle hook creators
   - Blue/green deployment helpers

4. **Advanced Features**:
   - Warm pool configuration
   - Predictive scaling setup
   - Custom termination policy builders