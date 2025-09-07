# AWS CloudFormation Stack Implementation

## Overview

The `aws_cloudformation_stack` resource provides type-safe CloudFormation stack management with comprehensive validation, helper configurations, and support for all CloudFormation features including IAM capabilities, stack policies, and notification integration.

## Key Features

### 1. Template Source Flexibility
- **Inline Templates**: Support for JSON/YAML template bodies with validation
- **S3 Templates**: Support for template URLs with HTTP/HTTPS validation
- **Mutual Exclusivity**: Enforces template_body XOR template_url constraint

### 2. IAM Integration
- **Capability Management**: Type-safe capability specification for IAM resources
- **Service Roles**: Support for CloudFormation service role delegation
- **Capability Validation**: Automatic detection of IAM capability requirements

### 3. Stack Protection
- **Termination Protection**: Enable/disable stack termination protection
- **Stack Policies**: Support for stack update policies via JSON documents
- **Rollback Control**: Configure rollback behavior on stack failures

### 4. Operational Features
- **Parameter Management**: Type-safe parameter passing to templates
- **Notification Integration**: SNS topic ARNs for stack event notifications
- **Timeout Configuration**: Custom timeout values for stack operations
- **Tag Management**: Comprehensive tag support with inheritance

## Type Safety Implementation

### Core Validation
```ruby
# Template source validation
def self.new(attributes = {})
  attrs = super(attributes)
  
  if !attrs.template_body && !attrs.template_url
    raise Dry::Struct::Error, "Either template_body or template_url must be specified"
  end
  
  if attrs.template_body && attrs.template_url
    raise Dry::Struct::Error, "Cannot specify both template_body and template_url"
  end
  
  # ... additional validations
end
```

### Template Content Validation
- **JSON Parsing**: Validates template_body as valid JSON
- **YAML Parsing**: Falls back to YAML validation if JSON fails
- **Policy Validation**: Ensures policy_body is valid JSON
- **URL Validation**: Validates template_url and policy_url format

### Capability Type Safety
```ruby
attribute :capabilities, Types::Array.of(
  Types::String.enum(
    "CAPABILITY_IAM", 
    "CAPABILITY_NAMED_IAM", 
    "CAPABILITY_AUTO_EXPAND"
  )
).default([].freeze)
```

## Resource Synthesis

### Template Configuration
```ruby
# Template source
if stack_attrs.template_body
  template_body stack_attrs.template_body
elsif stack_attrs.template_url
  template_url stack_attrs.template_url
end
```

### Parameter Synthesis
```ruby
if stack_attrs.has_parameters?
  parameters do
    stack_attrs.parameters.each do |key, value|
      public_send(key, value)
    end
  end
end
```

### Capability Synthesis
```ruby
if stack_attrs.has_capabilities?
  capabilities stack_attrs.capabilities
end
```

## Helper Configurations

### Production Stack Pattern
```ruby
def self.production_stack(name, template_url, parameters: {})
  {
    name: name,
    template_url: template_url,
    parameters: parameters,
    capabilities: ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"],
    enable_termination_protection: true,
    disable_rollback: false,
    timeout_in_minutes: 60
  }
end
```

### IAM Stack Pattern
```ruby
def self.iam_stack(name, template_body, iam_role_arn: nil)
  {
    name: name,
    template_body: template_body,
    capabilities: ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"],
    iam_role_arn: iam_role_arn,
    enable_termination_protection: true
  }
end
```

## Computed Properties

### Template Source Detection
```ruby
def template_source
  return :body if template_body
  return :url if template_url
  :none
end
```

### Capability Analysis
```ruby
def requires_iam_capabilities?
  capabilities.any? { |cap| cap.include?("IAM") }
end
```

### Protection Status
```ruby
def termination_protected?
  enable_termination_protection
end

def rollback_disabled?
  disable_rollback
end
```

## Integration Patterns

### Cross-Stack References
```ruby
# Create foundation stack
foundation = aws_cloudformation_stack(:foundation, {
  name: "vpc-foundation",
  template_url: "https://s3.amazonaws.com/templates/vpc.yaml"
})

# Reference foundation outputs
app_stack = aws_cloudformation_stack(:application, {
  name: "application-stack",
  template_url: "https://s3.amazonaws.com/templates/app.yaml",
  parameters: {
    "VpcId" => "${#{foundation.outputs[:outputs]}.VpcId}",
    "SubnetIds" => "${#{foundation.outputs[:outputs]}.PrivateSubnetIds}"
  }
})
```

### Notification Integration
```ruby
# SNS topic for notifications
notification_topic = aws_sns_topic(:stack_notifications, {
  name: "cloudformation-notifications"
})

# Stack with notifications
monitored_stack = aws_cloudformation_stack(:monitored, {
  name: "monitored-infrastructure",
  template_body: template_content,
  notification_arns: [notification_topic.outputs[:arn]]
})
```

## Error Handling

### Template Validation Errors
- **JSON Parse Errors**: Clear error messages for malformed JSON templates
- **YAML Parse Errors**: Fallback validation with specific YAML error reporting
- **URL Format Errors**: HTTP/HTTPS URL validation with descriptive messages

### Constraint Violations
- **Template Source Conflicts**: Prevents specifying both body and URL
- **Policy Source Conflicts**: Prevents specifying both policy body and URL
- **Parameter Type Mismatches**: Ensures parameters are string key-value pairs

### Capability Requirements
- **IAM Detection**: Automatically detects when IAM capabilities are required
- **Missing Capabilities**: Clear errors when IAM resources lack proper capabilities

## Output Reference Structure

```ruby
outputs: {
  id: "${aws_cloudformation_stack.#{name}.id}",
  name: "${aws_cloudformation_stack.#{name}.name}",
  stack_id: "${aws_cloudformation_stack.#{name}.stack_id}",
  arn: "${aws_cloudformation_stack.#{name}.arn}",
  stack_status: "${aws_cloudformation_stack.#{name}.stack_status}",
  stack_status_reason: "${aws_cloudformation_stack.#{name}.stack_status_reason}",
  creation_time: "${aws_cloudformation_stack.#{name}.creation_time}",
  last_updated_time: "${aws_cloudformation_stack.#{name}.last_updated_time}",
  outputs: "${aws_cloudformation_stack.#{name}.outputs}",
  parameters: "${aws_cloudformation_stack.#{name}.parameters}",
  tags_all: "${aws_cloudformation_stack.#{name}.tags_all}"
}
```

## Best Practices

### Security
1. **Enable Termination Protection**: For production stacks
2. **Use IAM Service Roles**: Delegate permissions to CloudFormation service
3. **Stack Policies**: Protect critical resources from updates
4. **Capability Restrictions**: Only grant necessary IAM capabilities

### Operational
1. **Timeout Configuration**: Set appropriate timeouts for complex stacks
2. **Notification Setup**: Configure SNS notifications for stack events
3. **Parameter Validation**: Validate parameters in templates
4. **Tag Standardization**: Consistent tagging strategy across stacks

### Template Management
1. **S3 Storage**: Store large templates in S3 with versioning
2. **Template Validation**: Use CloudFormation designer or CLI validation
3. **Nested Stacks**: Break complex infrastructure into nested stacks
4. **Cross-Stack References**: Use exports/imports for shared resources