# AWS Auto Scaling Attachment Resource Implementation

## Overview

The `aws_autoscaling_attachment` resource creates an attachment between an Auto Scaling Group and a load balancer (either Classic Load Balancer or a Target Group for ALB/NLB). This resource manages the lifecycle of the attachment separately from the ASG and load balancer, providing flexibility in infrastructure management.

## Type Safety Implementation

### Attributes Structure

```ruby
class AutoScalingAttachmentAttributes < Dry::Struct
  # Required
  attribute :autoscaling_group_name, String
  
  # One of these is required (mutually exclusive)
  attribute :elb, String.optional                    # Classic Load Balancer
  attribute :lb_target_group_arn, String.optional    # ALB/NLB Target Group
  attribute :alb_target_group_arn, String.optional   # Deprecated alias
end
```

### Key Design Decisions

1. **Mutually Exclusive Targets**:
   - Must specify exactly one target type
   - Either `elb` (Classic LB) or `lb_target_group_arn` (ALB/NLB)
   - Validation ensures only one is provided

2. **Deprecated Alias Handling**:
   - `alb_target_group_arn` is deprecated but still supported
   - Automatically converted to `lb_target_group_arn`
   - Maintains backward compatibility

3. **Attachment Type Detection**:
   - Computed property identifies attachment type
   - `:classic_lb` for Classic Load Balancers
   - `:target_group` for ALB/NLB Target Groups

4. **Minimal Configuration**:
   - Only requires ASG name and target
   - No complex nested configurations
   - Clear separation of concerns

## Resource Function Pattern

The `aws_autoscaling_attachment` function is straightforward:

```ruby
def aws_autoscaling_attachment(name, attributes = {})
  # 1. Validate attributes with dry-struct
  attach_attrs = Types::AutoScalingAttachmentAttributes.new(attributes)
  
  # 2. Generate Terraform resource via synthesizer
  resource(:aws_autoscaling_attachment, name) do
    autoscaling_group_name attach_attrs.autoscaling_group_name
    
    # Conditional target specification
    elb attach_attrs.elb if attach_attrs.elb
    lb_target_group_arn attach_attrs.lb_target_group_arn if attach_attrs.lb_target_group_arn
  end
  
  # 3. Return ResourceReference with outputs and computed properties
  ResourceReference.new(
    type: 'aws_autoscaling_attachment',
    name: name,
    outputs: { id, autoscaling_group_name },
    computed_properties: { attachment_type, target_arn }
  )
end
```

## Integration with Terraform Synthesizer

The resource generates simple attachment configurations:

```ruby
# For ALB/NLB Target Group
resource(:aws_autoscaling_attachment, :web_attachment) do
  autoscaling_group_name "web-asg"
  lb_target_group_arn "${aws_lb_target_group.web.arn}"
end

# For Classic Load Balancer
resource(:aws_autoscaling_attachment, :classic_attachment) do
  autoscaling_group_name "legacy-asg"
  elb "my-classic-lb"
end
```

This generates the Terraform JSON:

```json
{
  "resource": {
    "aws_autoscaling_attachment": {
      "web_attachment": {
        "autoscaling_group_name": "web-asg",
        "lb_target_group_arn": "${aws_lb_target_group.web.arn}"
      }
    }
  }
}
```

## Common Usage Patterns

### 1. ALB Target Group Attachment
```ruby
# Create target group
tg = aws_lb_target_group(:web, {
  port: 80,
  protocol: "HTTP",
  vpc_id: vpc.id
})

# Create ASG
asg = aws_autoscaling_group(:web, {
  min_size: 2,
  max_size: 10,
  vpc_zone_identifier: subnet_ids,
  launch_template: { id: template.id }
})

# Attach ASG to target group
attachment = aws_autoscaling_attachment(:web_attach, {
  autoscaling_group_name: asg.name,
  lb_target_group_arn: tg.arn
})
```

### 2. Multiple Target Group Attachments
```ruby
# Single ASG attached to multiple target groups
%w[http https].each do |protocol|
  tg = aws_lb_target_group(:"#{protocol}_tg", {
    port: protocol == "https" ? 443 : 80,
    protocol: protocol.upcase,
    vpc_id: vpc.id
  })
  
  aws_autoscaling_attachment(:"#{protocol}_attach", {
    autoscaling_group_name: asg.name,
    lb_target_group_arn: tg.arn
  })
end
```

### 3. Classic Load Balancer Attachment
```ruby
# For legacy applications
attachment = aws_autoscaling_attachment(:legacy, {
  autoscaling_group_name: "legacy-app-asg",
  elb: "legacy-classic-lb"
})
```

### 4. Blue-Green Deployment Pattern
```ruby
# Blue environment attached
blue_attachment = aws_autoscaling_attachment(:blue, {
  autoscaling_group_name: blue_asg.name,
  lb_target_group_arn: prod_tg.arn
})

# Green environment ready but not attached
# Attachment created during deployment
```

## Testing Considerations

1. **Type Validation**:
   - Test mutual exclusivity of elb/lb_target_group_arn
   - Test missing target specification
   - Test multiple targets specified

2. **Deprecated Alias**:
   - Test alb_target_group_arn conversion
   - Verify backward compatibility

3. **Terraform Generation**:
   - Verify correct attribute selection
   - Test resource reference syntax

4. **Computed Properties**:
   - Test attachment type detection
   - Verify target_arn extraction

## Future Enhancements

1. **Validation Improvements**:
   - Validate ARN format for target groups
   - Verify ASG name format
   - Cross-reference validation with other resources

2. **Additional Features**:
   - Support for multiple attachments in one resource
   - Attachment health status tracking
   - Graceful attachment/detachment helpers

3. **Helper Methods**:
   - Blue-green deployment utilities
   - Attachment migration helpers
   - Load balancer type detection

## Best Practices

1. **Separate Attachment Management**:
   - Allows ASG and LB to be managed independently
   - Enables zero-downtime deployments
   - Facilitates blue-green strategies

2. **Naming Conventions**:
   - Use descriptive names for attachments
   - Include ASG and target in name
   - Maintain consistency across environments

3. **Lifecycle Management**:
   - Plan attachment order during creation
   - Consider detachment order during destruction
   - Use Terraform lifecycle rules when needed

4. **Multi-Target Patterns**:
   - One ASG can attach to multiple target groups
   - Useful for multi-port applications
   - Enables gradual migration strategies