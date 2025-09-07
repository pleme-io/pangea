# AWS Config Config Rule Implementation

## Overview

This implementation provides type-safe AWS Config Config Rule resources with comprehensive validation, cost estimation, and enterprise compliance patterns for automated governance.

## Architecture

### Type System
- **`ConfigConfigRuleAttributes`**: dry-struct validation with AWS Config rule-specific constraints
- **Name Validation**: AWS Config rule naming pattern enforcement
- **Source Validation**: Complex source configuration validation for different rule types
- **Scope Validation**: Resource type and tag-based scope validation
- **Parameter Validation**: JSON input parameter validation
- **Cost Estimation**: Built-in monthly cost estimation based on evaluation frequency and rule type

### Key Features

#### 1. Multi-Source Rule Support
- **AWS Managed Rules**: Pre-built rules from AWS with source_identifier
- **Custom Lambda Rules**: Lambda function-based rules with ARN validation
- **Custom Policy Rules**: Policy-based rules with source_detail configuration
- **Automatic Validation**: Source-specific validation for each rule type

#### 2. Comprehensive Scope Configuration
- **Resource Type Scoping**: Target specific AWS resource types
- **Tag-Based Scoping**: Target resources with specific tag keys/values
- **Resource ID Scoping**: Target specific resource instances
- **Combined Scoping**: Mix multiple scope criteria

#### 3. Execution Model Support
- **Configuration Change Triggered**: React to resource configuration changes
- **Periodic Evaluation**: Run on configurable time schedules
- **Hybrid Execution**: Combine change-triggered and periodic evaluation
- **Cost-Aware Scheduling**: Balance compliance needs with evaluation costs

#### 4. Enterprise Compliance Features
- **Multi-Framework Support**: SOX, PCI, GDPR, HIPAA compliance patterns
- **Cost Optimization**: Built-in cost estimation and optimization recommendations
- **Dependency Management**: Proper sequencing with Config recorder and delivery channel
- **Integration Ready**: SNS notifications, remediation, monitoring integration

#### 5. Advanced Parameter Handling
- **JSON Parameter Validation**: Structured input parameter support
- **Type-Safe Parameters**: Parameter validation for common compliance scenarios
- **Dynamic Parameters**: Support for environment-specific parameter values
- **Secret-Safe**: Avoid exposing sensitive data in parameters

## Implementation Details

### Validation Logic

#### Config Rule Name Validation
```ruby
# Pattern: alphanumeric, hyphens, underscores only
name.match?(/\A[a-zA-Z0-9_-]+\z/)

# Length validation
name.length <= 128 && !name.empty?
```

#### Source Configuration Validation
```ruby
# Owner validation
valid_owners = ['AWS', 'AWS_CONFIG_RULE', 'CUSTOM_LAMBDA', 'CUSTOM_POLICY']
source[:owner].in?(valid_owners)

# AWS managed rule validation
case source[:owner]
when 'AWS'
  source[:source_identifier].present? # Required AWS rule identifier
when 'CUSTOM_LAMBDA'
  # Lambda ARN format validation
  source[:source_identifier].match?(/\Aarn:aws:lambda:[^:]+:\d{12}:function:/)
when 'CUSTOM_POLICY'
  # Source detail array validation
  source[:source_detail].is_a?(Array) && !source[:source_detail].empty?
end
```

#### Scope Configuration Validation
```ruby
# Resource types validation
if scope[:compliance_resource_types]
  scope[:compliance_resource_types].is_a?(Array)
end

# Tag scope validation
if scope[:tag_key] || scope[:tag_value]
  scope[:tag_key].is_a?(String) && scope[:tag_value].is_a?(String)
end
```

#### Execution Frequency Validation
```ruby
# Valid execution frequencies
valid_frequencies = [
  'One_Hour', 'Three_Hours', 'Six_Hours', 
  'Twelve_Hours', 'TwentyFour_Hours'
]

maximum_execution_frequency.in?(valid_frequencies)
```

### Cost Estimation Algorithm

```ruby
def estimated_monthly_cost_usd
  # Base evaluation count calculation
  base_evaluations = if has_periodic_execution?
                      # Frequency-based evaluation count
                      case maximum_execution_frequency
                      when 'One_Hour' then 30 * 24      # 720 evaluations
                      when 'Three_Hours' then 30 * 8    # 240 evaluations
                      when 'Six_Hours' then 30 * 4      # 120 evaluations
                      when 'Twelve_Hours' then 30 * 2   # 60 evaluations
                      else 30                            # 30 evaluations (daily)
                      end
                    else
                      # Change-triggered evaluation estimate
                      100 # Based on typical resource change frequency
                    end
  
  # Scope-based multiplier
  if has_resource_type_scope?
    resource_multiplier = [scope[:compliance_resource_types].length / 5.0, 1.0].max
    evaluations = (base_evaluations * resource_multiplier).to_i
  else
    evaluations = base_evaluations
  end
  
  # Rule evaluation cost: $0.001 per evaluation
  evaluation_cost = evaluations * 0.001
  
  # Custom Lambda additional costs
  lambda_cost = if is_custom_lambda?
                  lambda_executions = evaluations
                  execution_time_ms = 5000  # 5 second average
                  memory_mb = 128
                  
                  # Lambda pricing: $0.0000166667 per GB-second
                  gb_seconds = (memory_mb / 1024.0) * (execution_time_ms / 1000.0) * lambda_executions
                  gb_seconds * 0.0000166667
                else
                  0.0
                end
  
  (evaluation_cost + lambda_cost).round(4)
end
```

### Computed Properties

1. **`is_aws_managed?`**: Boolean indicating AWS managed rule
2. **`is_custom_lambda?`**: Boolean indicating custom Lambda rule
3. **`is_custom_policy?`**: Boolean indicating custom policy rule
4. **`has_scope?`**: Boolean indicating scope configuration
5. **`has_resource_type_scope?`**: Boolean indicating resource type scoping
6. **`has_tag_scope?`**: Boolean indicating tag-based scoping
7. **`has_periodic_execution?`**: Boolean indicating periodic evaluation
8. **`estimated_monthly_cost_usd`**: Float with comprehensive cost estimation

### Terraform Resource Mapping

```ruby
resource(:aws_config_config_rule, name) do
  name rule_attrs.name
  description rule_attrs.description if rule_attrs.description
  
  # Source configuration block
  source do
    owner rule_attrs.source[:owner]
    source_identifier rule_attrs.source[:source_identifier] if rule_attrs.source[:source_identifier]
    
    # Custom policy source detail
    if rule_attrs.source[:source_detail].is_a?(Array)
      rule_attrs.source[:source_detail].each do |detail|
        source_detail do
          event_source detail[:event_source] if detail[:event_source]
          message_type detail[:message_type] if detail[:message_type]
          maximum_execution_frequency detail[:maximum_execution_frequency] if detail[:maximum_execution_frequency]
        end
      end
    end
  end
  
  # Input parameters as JSON string
  input_parameters rule_attrs.input_parameters if rule_attrs.input_parameters
  
  # Periodic execution frequency
  maximum_execution_frequency rule_attrs.maximum_execution_frequency if rule_attrs.has_periodic_execution?
  
  # Scope configuration block
  if rule_attrs.has_scope?
    scope do
      compliance_resource_types rule_attrs.scope[:compliance_resource_types] if rule_attrs.scope[:compliance_resource_types]
      tag_key rule_attrs.scope[:tag_key] if rule_attrs.scope[:tag_key]
      tag_value rule_attrs.scope[:tag_value] if rule_attrs.scope[:tag_value]
      compliance_resource_id rule_attrs.scope[:compliance_resource_id] if rule_attrs.scope[:compliance_resource_id]
    end
  end
  
  # Dependencies
  depends_on rule_attrs.depends_on if rule_attrs.depends_on.any?
  
  # Tags block
  tags do
    rule_attrs.tags.each do |key, value|
      public_send(key, value)
    end
  end
end
```

### Resource Reference Outputs

```ruby
outputs: {
  arn: "${aws_config_config_rule.#{name}.arn}",
  name: "${aws_config_config_rule.#{name}.name}",
  rule_id: "${aws_config_config_rule.#{name}.rule_id}",
  source: "${aws_config_config_rule.#{name}.source}",
  scope: "${aws_config_config_rule.#{name}.scope}",
  tags_all: "${aws_config_config_rule.#{name}.tags_all}"
}
```

## Enterprise Patterns

### 1. Multi-Framework Compliance
- **SOX Compliance**: Financial controls with appropriate rule selection
- **PCI DSS**: Payment card industry security standards
- **GDPR**: Data protection and privacy rules
- **HIPAA**: Healthcare data protection requirements
- **Custom Frameworks**: Organization-specific compliance requirements

### 2. Cost-Optimized Rule Deployment
- **High-Priority Rules**: Frequent evaluation for critical compliance
- **Standard Rules**: Daily evaluation for general compliance
- **Cost-Conscious Rules**: Weekly evaluation for non-critical requirements
- **Resource-Scoped Rules**: Targeted evaluation to minimize costs

### 3. Environment-Specific Compliance
- **Production**: Comprehensive rule coverage with high frequency
- **Staging**: Subset of rules with moderate frequency
- **Development**: Basic rules with low frequency
- **Sandbox**: Minimal rules for experimentation

### 4. Integration Architecture
- **With Config Recorder**: Rules depend on active configuration recording
- **With Delivery Channel**: Compliance data delivery to S3 and SNS
- **With Remediation**: Automatic fixing of non-compliant resources
- **With Monitoring**: CloudWatch integration for rule health and compliance metrics

## Compliance Framework Mapping

### SOX (Sarbanes-Oxley) Rules
```ruby
sox_rules = [
  "IAM_PASSWORD_POLICY",           # Strong password requirements
  "IAM_USER_MFA_ENABLED",          # Multi-factor authentication
  "CLOUDTRAIL_ENABLED",            # Audit trail logging
  "S3_BUCKET_LOGGING_ENABLED",     # Access logging
  "ROOT_ACCESS_KEY_CHECK"          # Root account security
]
```

### PCI DSS (Payment Card Industry) Rules
```ruby
pci_rules = [
  "ENCRYPTED_VOLUMES",             # Data encryption at rest
  "S3_BUCKET_SSL_REQUESTS_ONLY",   # Secure data transmission
  "RDS_STORAGE_ENCRYPTED",         # Database encryption
  "SECURITY_GROUP_SSH_CHECK"       # Network access controls
]
```

### GDPR (General Data Protection Regulation) Rules
```ruby
gdpr_rules = [
  "S3_BUCKET_PUBLIC_READ_PROHIBITED",    # Data privacy protection
  "RDS_STORAGE_ENCRYPTED",               # Personal data encryption
  "CLOUDTRAIL_ENABLED",                  # Data processing audit trail
  "IAM_USER_MFA_ENABLED"                 # Access control security
]
```

### Cost Optimization Rules
```ruby
cost_optimization_rules = [
  "EC2_INSTANCE_NO_PUBLIC_IP",     # Reduce NAT gateway costs
  "EIP_ATTACHED",                  # Eliminate unused Elastic IPs
  "EC2_VOLUME_INUSE_CHECK",        # Identify unused EBS volumes
  "RDS_INSTANCE_DELETION_PROTECTION_ENABLED"  # Prevent accidental deletions
]
```

## Advanced Features

### Custom Lambda Rule Integration
- Lambda function ARN validation
- Execution role requirements
- Parameter passing to Lambda functions
- Error handling and retry logic
- Cost calculation including Lambda execution costs

### Multi-Resource Type Scoping
- Resource type array validation
- Cross-service compliance rules
- Resource relationship validation
- Scope optimization for cost reduction

### Tag-Based Compliance
- Tag key/value pair scoping
- Environment-specific rule application
- Cost center-based compliance
- Project-specific governance rules

## Validation Error Messages

The implementation provides clear error messages for common validation failures:

- Name format violations with character requirements
- Source configuration errors with owner-specific requirements
- Lambda ARN format errors with valid ARN examples
- Scope configuration errors with field-specific guidance
- Parameter validation errors with JSON format requirements

## Best Practices Encoded

1. **Rule Organization**: Framework-based rule grouping with consistent naming
2. **Cost Management**: Frequency selection based on compliance criticality
3. **Scope Optimization**: Resource-type scoping to minimize unnecessary evaluations
4. **Parameter Security**: JSON parameter validation without secret exposure
5. **Dependency Management**: Proper sequencing with Config infrastructure
6. **Integration Ready**: Built-in support for remediation and monitoring workflows

## Security Considerations

### Rule Management Security
- IAM permissions for Config rule creation and modification
- Least privilege access to rule evaluation results
- Secure parameter handling for sensitive configuration data
- Audit logging of rule changes and compliance status

### Custom Lambda Security
- Lambda execution role with minimal required permissions
- VPC configuration for Lambda functions if network isolation needed
- Encryption of Lambda environment variables
- Regular security updates for Lambda function code

### Compliance Data Security
- Encryption of compliance evaluation results
- Access control for compliance reports and dashboards
- Secure integration with external compliance management systems
- Data retention policies aligned with compliance requirements

## Testing Considerations

The implementation supports testing through:
- Deterministic cost calculations based on rule configuration
- Predictable computed properties for different rule types
- Clear validation rules with comprehensive error messages
- Type safety through dry-struct validation
- Mock-friendly resource reference outputs for integration testing

## Performance Considerations

### Evaluation Performance
- Rule frequency impact on evaluation costs and compliance latency
- Resource scope optimization for evaluation efficiency
- Parallel rule evaluation support
- Impact of custom Lambda rule complexity on execution time

### Operational Efficiency
- Rule dependency management for proper deployment sequencing
- Integration with Config recorder and delivery channel lifecycle
- Monitoring and alerting for rule evaluation failures
- Automated remediation integration for compliance drift correction

This implementation provides enterprise-grade AWS Config Rule management with built-in compliance framework support, cost optimization, security best practices, and comprehensive validation.