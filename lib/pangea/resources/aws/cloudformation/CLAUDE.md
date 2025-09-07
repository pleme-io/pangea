# AWS CloudFormation Extended Resources

This module provides advanced CloudFormation resource management capabilities for enterprise-scale deployments, including stack sets, type registration, and publishing functionality.

## Key Resources

### Stack Sets (`aws_cloudformation_stack_set`)
- **Purpose**: Deploy CloudFormation stacks across multiple AWS accounts and regions
- **Use Cases**: Organization-wide security baselines, compliance templates, shared infrastructure
- **Features**: Auto-deployment, managed execution, operation preferences

### Stack Set Instances (`aws_cloudformation_stack_set_instance`) 
- **Purpose**: Manage individual stack instances within a stack set
- **Use Cases**: Account-specific or region-specific deployments
- **Features**: Parameter overrides, retention policies, operation preferences

### Stack Instances (`aws_cloudformation_stack_instances`)
- **Purpose**: Bulk management of multiple stack instances
- **Use Cases**: Multi-region deployments, organization-wide rollouts
- **Features**: Deployment targets, region concurrency, failure tolerance

### Type Registration (`aws_cloudformation_type`)
- **Purpose**: Register custom CloudFormation resource types and hooks
- **Use Cases**: Custom resource providers, pre/post deployment validation
- **Features**: Schema validation, execution roles, logging configuration

## DevOps Integration Patterns

### Multi-Account Security Baseline
```ruby
template :organization_security do
  # Register security baseline stack set
  security_baseline = aws_cloudformation_stack_set(:security_baseline, {
    name: "OrganizationSecurityBaseline",
    template_url: "s3://cf-templates/security-baseline.yaml",
    permission_model: "SERVICE_MANAGED",
    auto_deployment: {
      enabled: true,
      retain_stacks_on_account_removal: false
    }
  })

  # Deploy to all organization accounts
  aws_cloudformation_stack_instances(:org_security_deployment, {
    stack_set_name: security_baseline.name,
    deployment_targets: {
      organizational_unit_ids: ["ou-root-123456789"]
    },
    regions: ["us-east-1", "us-west-2", "eu-west-1"]
  })
end
```

### Custom Resource Type with Validation
```ruby
template :custom_resources do
  # Register custom S3 bucket type with security defaults
  secure_bucket_type = aws_cloudformation_type(:secure_s3_bucket, {
    type: "RESOURCE",
    type_name: "Company::S3::SecureBucket",
    schema_handler_package: "s3://cf-types/secure-s3-bucket.zip",
    execution_role_arn: execution_role.arn,
    logging_config: {
      log_group_name: "CloudFormationTypes",
      log_role_arn: logging_role.arn
    }
  })

  # Register deployment validation hook
  validation_hook = aws_cloudformation_type(:deployment_validator, {
    type: "HOOK",
    type_name: "Company::Security::DeploymentValidator",
    schema_handler_package: "s3://cf-hooks/validator.zip",
    execution_role_arn: hook_role.arn
  })
end
```

## Compliance and Governance

### Stack Set Deployment Controls
- **Failure Tolerance**: Configure acceptable failure thresholds
- **Concurrency Limits**: Control rollout speed across accounts/regions  
- **Auto-Rollback**: Automatic rollback on deployment failures
- **Drift Detection**: Monitor and alert on configuration drift

### Type Registration Governance
- **Publisher Registration**: Establish organizational type publishers
- **Version Management**: Control type version defaults and updates
- **Logging and Monitoring**: Track type usage and execution

### Enterprise Patterns
- **Multi-Environment Promotion**: Dev → Test → Prod stack set workflows
- **Compliance Templates**: Organization-wide policy enforcement
- **Custom Resource Validation**: Pre-deployment security and compliance checks
- **Cross-Account Resource Sharing**: Centralized resource management

This implementation enables enterprise-scale CloudFormation management with the operational controls and governance capabilities required for large-scale AWS deployments.