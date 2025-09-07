# AWS CloudFormation Stack Set Implementation

## Overview

The `aws_cloudformation_stack_set` resource provides type-safe CloudFormation stack set management for multi-account and multi-region deployments. It supports both SERVICE_MANAGED (AWS Organizations) and SELF_MANAGED permission models with comprehensive validation and operational controls.

## Key Features

### 1. Multi-Account Deployment Models
- **SERVICE_MANAGED**: Integration with AWS Organizations for automatic permission management
- **SELF_MANAGED**: Manual role-based cross-account deployment with explicit permissions
- **Permission Validation**: Enforces model-specific requirements (roles, auto-deployment)

### 2. Template Source Flexibility
- **Inline Templates**: Support for JSON/YAML template bodies with validation
- **S3 Templates**: Support for template URLs with HTTP/HTTPS validation
- **Template Validation**: JSON/YAML syntax validation for inline templates

### 3. Operation Preferences
- **Concurrency Control**: Parallel vs sequential deployment with configurable limits
- **Failure Tolerance**: Configurable failure thresholds for deployment resilience
- **Regional Deployment**: Fine-grained control over multi-region deployments

### 4. Auto-Deployment Management
- **Organization Integration**: Automatic deployment to new accounts in Organizations
- **Stack Retention**: Control over stack lifecycle during account removal
- **Deployment Triggers**: Configurable auto-deployment behavior

## Type Safety Implementation

### Core Validation
```ruby
def self.new(attributes = {})
  attrs = super(attributes)
  
  # Template source validation
  if !attrs.template_body && !attrs.template_url
    raise Dry::Struct::Error, "Either template_body or template_url must be specified"
  end
  
  # Permission model validation
  if attrs.permission_model == "SELF_MANAGED"
    unless attrs.administration_role_arn
      raise Dry::Struct::Error, "administration_role_arn is required for SELF_MANAGED"
    end
  end
  
  # ... additional validations
end
```

### Permission Model Validation
- **SELF_MANAGED Requirements**: Validates presence of administration_role_arn and execution_role_name
- **SERVICE_MANAGED Restrictions**: Prevents role specification for service-managed stack sets
- **Auto-deployment Logic**: Validates auto-deployment only applies to SERVICE_MANAGED

### Operation Preferences Validation
```ruby
# Mutual exclusivity validation
if prefs[:max_concurrent_percentage] && prefs[:max_concurrent_count]
  raise Dry::Struct::Error, "Cannot specify both max_concurrent_percentage and max_concurrent_count"
end

if prefs[:failure_tolerance_percentage] && prefs[:failure_tolerance_count]
  raise Dry::Struct::Error, "Cannot specify both failure_tolerance_percentage and failure_tolerance_count"
end
```

## Resource Synthesis

### Permission Model Configuration
```ruby
# Permission model
permission_model stack_set_attrs.permission_model

# Service-managed configuration
if stack_set_attrs.auto_deployment
  auto_deployment do
    enabled stack_set_attrs.auto_deployment[:enabled]
    retain_stacks_on_account_removal stack_set_attrs.auto_deployment[:retain_stacks_on_account_removal]
  end
end

# Self-managed configuration
if stack_set_attrs.administration_role_arn
  administration_role_arn stack_set_attrs.administration_role_arn
end
```

### Operation Preferences Synthesis
```ruby
if stack_set_attrs.operation_preferences
  operation_preferences do
    prefs = stack_set_attrs.operation_preferences
    
    region_concurrency_type prefs[:region_concurrency_type] if prefs[:region_concurrency_type]
    max_concurrent_percentage prefs[:max_concurrent_percentage] if prefs[:max_concurrent_percentage]
    max_concurrent_count prefs[:max_concurrent_count] if prefs[:max_concurrent_count]
    failure_tolerance_percentage prefs[:failure_tolerance_percentage] if prefs[:failure_tolerance_percentage]
    failure_tolerance_count prefs[:failure_tolerance_count] if prefs[:failure_tolerance_count]
  end
end
```

## Helper Configurations

### Service-Managed Stack Set Pattern
```ruby
def self.service_managed_stack_set(name, template_body)
  {
    name: name,
    template_body: template_body,
    permission_model: "SERVICE_MANAGED",
    auto_deployment: {
      enabled: true,
      retain_stacks_on_account_removal: false
    },
    call_as: "DELEGATED_ADMIN"
  }
end
```

### Parallel Deployment Pattern
```ruby
def self.parallel_deployment_stack_set(name, template_url)
  {
    name: name,
    template_url: template_url,
    permission_model: "SERVICE_MANAGED",
    auto_deployment: {
      enabled: true,
      retain_stacks_on_account_removal: false
    },
    operation_preferences: {
      region_concurrency_type: "PARALLEL",
      max_concurrent_percentage: 100,
      failure_tolerance_percentage: 10
    }
  }
end
```

### Conservative Deployment Pattern
```ruby
def self.conservative_deployment_stack_set(name, template_body)
  {
    name: name,
    template_body: template_body,
    permission_model: "SERVICE_MANAGED",
    auto_deployment: {
      enabled: false,
      retain_stacks_on_account_removal: true
    },
    operation_preferences: {
      region_concurrency_type: "SEQUENTIAL",
      max_concurrent_count: 1,
      failure_tolerance_count: 0
    }
  }
end
```

## Computed Properties

### Permission Model Detection
```ruby
def is_service_managed?
  permission_model == "SERVICE_MANAGED"
end

def is_self_managed?
  permission_model == "SELF_MANAGED"
end
```

### Deployment Strategy Detection
```ruby
def uses_parallel_deployment?
  operation_preferences&.dig(:region_concurrency_type) == "PARALLEL"
end

def uses_sequential_deployment?
  operation_preferences&.dig(:region_concurrency_type) == "SEQUENTIAL"
end
```

### Auto-Deployment Analysis
```ruby
def auto_deployment_enabled?
  auto_deployment&.dig(:enabled) == true
end

def retains_stacks_on_removal?
  auto_deployment&.dig(:retain_stacks_on_account_removal) == true
end
```

## Integration Patterns

### Organization-Wide Deployment
```ruby
# Security baseline for all organization accounts
security_baseline = aws_cloudformation_stack_set(:security_baseline, {
  name: "organization-security-baseline",
  template_body: security_template,
  description: "Deploy security baseline across organization",
  permission_model: "SERVICE_MANAGED",
  auto_deployment: {
    enabled: true,
    retain_stacks_on_account_removal: false
  },
  operation_preferences: {
    region_concurrency_type: "PARALLEL",
    max_concurrent_percentage: 100,
    failure_tolerance_percentage: 5
  },
  capabilities: ["CAPABILITY_IAM"]
})
```

### Cross-Account Resource Sharing
```ruby
# Shared resources across specific accounts
shared_resources = aws_cloudformation_stack_set(:shared_resources, {
  name: "cross-account-shared-resources",
  template_url: "https://s3.amazonaws.com/templates/shared.yaml",
  permission_model: "SELF_MANAGED",
  administration_role_arn: admin_role.outputs[:arn],
  execution_role_name: "StackSetExecutionRole",
  parameters: {
    "SharedResourcePrefix" => "company",
    "Environment" => "production"
  }
})
```

### Multi-Region Disaster Recovery
```ruby
# Disaster recovery infrastructure
dr_stack_set = aws_cloudformation_stack_set(:disaster_recovery, {
  name: "disaster-recovery-infrastructure",
  template_body: dr_template,
  permission_model: "SERVICE_MANAGED",
  auto_deployment: {
    enabled: true,
    retain_stacks_on_account_removal: true
  },
  operation_preferences: {
    region_concurrency_type: "SEQUENTIAL",
    max_concurrent_count: 2,
    failure_tolerance_count: 0
  }
})
```

## Error Handling

### Permission Model Violations
- **Missing Roles**: Clear error when SELF_MANAGED lacks required roles
- **Invalid Auto-deployment**: Error when SERVICE_MANAGED configuration is applied to SELF_MANAGED
- **Role Conflicts**: Error when roles are specified for SERVICE_MANAGED

### Operation Preference Conflicts
- **Concurrency Conflicts**: Prevents specifying both percentage and count limits
- **Tolerance Conflicts**: Prevents specifying both percentage and count tolerances
- **Invalid Values**: Range validation for percentages (0-100) and positive integers

### Template Validation Errors
- **Template Source Conflicts**: Prevents specifying both body and URL
- **Template Syntax**: JSON/YAML validation with specific error reporting
- **URL Format**: HTTP/HTTPS URL validation

## Output Reference Structure

```ruby
outputs: {
  id: "${aws_cloudformation_stack_set.#{name}.id}",
  name: "${aws_cloudformation_stack_set.#{name}.name}",
  stack_set_id: "${aws_cloudformation_stack_set.#{name}.stack_set_id}",
  arn: "${aws_cloudformation_stack_set.#{name}.arn}",
  status: "${aws_cloudformation_stack_set.#{name}.status}",
  description: "${aws_cloudformation_stack_set.#{name}.description}",
  parameters: "${aws_cloudformation_stack_set.#{name}.parameters}",
  capabilities: "${aws_cloudformation_stack_set.#{name}.capabilities}",
  permission_model: "${aws_cloudformation_stack_set.#{name}.permission_model}",
  tags_all: "${aws_cloudformation_stack_set.#{name}.tags_all}",
  template_description: "${aws_cloudformation_stack_set.#{name}.template_description}"
}
```

## Best Practices

### Security
1. **Use SERVICE_MANAGED**: For organization-wide deployments to leverage automatic permission management
2. **Least Privilege Roles**: Configure minimal required permissions for execution roles
3. **Enable Termination Protection**: For production stack sets via stack-level configuration
4. **IAM Capability Control**: Only grant necessary IAM capabilities

### Operational Excellence
1. **Conservative Failure Tolerance**: Start with low failure tolerance for critical deployments
2. **Sequential Deployment**: Use for critical infrastructure that requires ordered deployment
3. **Auto-deployment Control**: Disable for production environments requiring approval
4. **Stack Retention**: Enable retention for production environments

### Performance
1. **Parallel Deployment**: Use for independent resources across regions
2. **Appropriate Concurrency**: Balance speed with resource limits and failure tolerance
3. **Template Optimization**: Keep templates focused and avoid complex dependencies
4. **S3 Template Storage**: Use S3 for large templates with versioning enabled