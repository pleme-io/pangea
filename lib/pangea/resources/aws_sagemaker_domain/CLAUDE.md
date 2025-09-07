# AWS SageMaker Domain - Implementation Notes

## Resource Overview

The `aws_sagemaker_domain` resource implements SageMaker Studio domain management with comprehensive MLOps-focused validation and enterprise security features. This is the foundational resource for SageMaker Studio, providing the environment where data scientists and ML engineers work.

## Key Implementation Features

### 1. Comprehensive ML-Specific Validation

**Authentication Mode Validation**:
- SSO vs IAM mode consistency checking
- Execution role identity configuration validation
- Single sign-on managed application requirements

**VPC and Network Security**:
- Multi-AZ subnet requirement validation (minimum 2 subnets)
- VPC-only access mode security requirements
- Custom security group management validation
- App network access type consistency checking

**Resource Specification Validation**:
- ML instance type enumeration and validation
- Lifecycle configuration ARN format validation
- SageMaker image and version ARN validation

### 2. Enterprise Security Features

**Encryption and Key Management**:
- KMS key validation (ARN, alias, or key ID formats)
- Encryption at rest configuration
- Canvas workspace encryption settings

**Access Control**:
- IAM execution role permission validation
- Security group reference validation
- Notebook sharing and output control

**Network Isolation**:
- VPC-only access mode support
- Customer-managed security groups
- Domain boundary security group management

### 3. Advanced Application Integration

**SageMaker Canvas**:
- Time series forecasting settings with Amazon Forecast integration
- Model registry cross-account configuration
- Workspace settings with S3 artifact paths

**R Studio Server Pro**:
- Domain execution role configuration
- Default resource specifications
- R Studio Connect and package manager URL settings

**Jupyter and Kernel Gateway**:
- Custom image and lifecycle configuration support
- Code repository integration
- Default resource specifications

### 4. MLOps and Governance Features

**Security Scoring**:
```ruby
def security_score
  score = 0
  score += 20 if supports_vpc_only?
  score += 15 if uses_custom_kms_key?
  score += 10 if has_custom_security_groups?
  score += 15 if uses_sso_auth?
  score += 10 if subnet_count >= 3
  [score, 100].min
end
```

**Compliance Status**:
- Automated security configuration validation
- Best practices compliance checking
- Issue identification and recommendations

**Cost Estimation**:
- Domain and compute cost calculations
- Storage cost estimation for EFS
- Usage-based pricing considerations

## Type System Architecture

### Core Types

**SageMakerDomainExecutionRole**:
- IAM role ARN format validation
- SageMaker service trust relationship requirements
- Required policy validation framework

**SageMakerDomainAuthMode**:
- SSO vs IAM authentication modes
- Integration with AWS SSO requirements
- Identity configuration consistency

**SageMakerDomainInstanceType**:
- Comprehensive ML instance type enumeration
- GPU and CPU instance categories
- Cost and performance optimization guidance

### Application-Specific Types

**SageMakerDomainJupyterServerAppSettings**:
- Default resource specification validation
- Lifecycle configuration ARN validation
- Code repository URL and branch validation

**SageMakerDomainCanvasAppSettings**:
- Time series forecasting configuration
- Model registry settings
- Workspace S3 path validation

**SageMakerDomainRStudioServerProAppSettings**:
- User group and access status management
- Resource specification validation
- Integration endpoint configuration

## Validation Logic

### Network Configuration Validation
```ruby
if attrs[:app_network_access_type] == 'VpcOnly'
  if attrs[:vpc_id].nil? || attrs[:subnet_ids].nil?
    raise Dry::Struct::Error, "vpc_id and subnet_ids are required when app_network_access_type is VpcOnly"
  end
end
```

### Authentication Mode Consistency
```ruby
if attrs[:auth_mode] == 'SSO'
  if attrs[:domain_settings] && attrs[:domain_settings][:execution_role_identity_config] == 'DISABLED'
    raise Dry::Struct::Error, "execution_role_identity_config cannot be DISABLED when auth_mode is SSO"
  end
end
```

### Subnet Requirements
```ruby
if subnet_ids.size < 2
  raise Dry::Struct::Error, "SageMaker Domain requires at least 2 subnets in different Availability Zones"
end
```

## Resource Reference Attributes

The resource reference provides comprehensive attributes for integration:

**Core Attributes**:
- `id`, `arn`, `domain_name`, `auth_mode`
- `vpc_id`, `subnet_ids`, `kms_key_id`
- `app_network_access_type`

**Computed Attributes**:
- `home_efs_file_system_id`: EFS file system for user home directories
- `security_group_id_for_domain_boundary`: Auto-created security group
- `url`: Studio domain URL for web access

**Helper Attributes**:
- `studio_url`: Alias for the domain URL
- `is_vpc_only`: Boolean indicator for network access type
- `uses_sso`: Boolean indicator for authentication mode

## Integration Patterns

### Multi-Environment Domain Management
```ruby
template :ml_platform do
  # Development domain with public access
  aws_sagemaker_domain(:dev_domain, {
    domain_name: "ml-development",
    auth_mode: "IAM",
    app_network_access_type: "PublicInternetOnly"
  })
  
  # Production domain with VPC-only access
  aws_sagemaker_domain(:prod_domain, {
    domain_name: "ml-production", 
    auth_mode: "SSO",
    app_network_access_type: "VpcOnly",
    kms_key_id: kms_key_ref.arn
  })
end
```

### Domain with User Profiles and Spaces
```ruby
domain_ref = aws_sagemaker_domain(:ml_platform, { ... })

aws_sagemaker_user_profile(:data_scientist, {
  domain_id: domain_ref.id,
  user_settings: {
    execution_role: data_scientist_role_ref.arn
  }
})

aws_sagemaker_space(:team_space, {
  domain_id: domain_ref.id,
  space_name: "data-science-team"
})
```

## Security Best Practices Implementation

### 1. Network Security
- Always use VPC-only access for production environments
- Configure private subnets without internet gateway access
- Use VPC endpoints for AWS service communication
- Implement network ACLs for additional security

### 2. Encryption and Key Management
- Use customer-managed KMS keys for regulatory compliance
- Configure encryption for EFS home directories
- Enable encryption for Canvas workspace artifacts
- Implement key rotation policies

### 3. Access Control
- Use SSO for centralized identity management
- Implement least-privilege IAM roles
- Configure security groups with minimal required access
- Enable CloudTrail for API call auditing

### 4. Compliance and Governance
- Use security scoring for configuration assessment
- Implement automated compliance checking
- Configure resource tagging for cost allocation
- Enable monitoring for security events

## Cost Optimization Strategies

### 1. Instance Type Selection
- Use smaller instance types for development
- Implement automatic stopping of idle instances
- Use Spot instances for training workloads
- Monitor usage patterns for rightsizing

### 2. Storage Management
- Configure EFS lifecycle policies
- Use S3 Intelligent Tiering for artifacts
- Implement data retention policies
- Monitor storage growth patterns

### 3. Network Optimization
- Use VPC endpoints to reduce data transfer costs
- Optimize subnet placement for AZ balance
- Consider Regional vs Cross-AZ data transfer
- Monitor network usage patterns

This implementation provides enterprise-grade SageMaker domain management with comprehensive security, compliance, and cost optimization features suitable for production ML platforms.