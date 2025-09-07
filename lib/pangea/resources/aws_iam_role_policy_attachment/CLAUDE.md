# AWS IAM Role Policy Attachment Implementation

## Overview

This implementation provides type-safe AWS IAM role policy attachment functionality with comprehensive security analysis, AWS managed policy constants, and common attachment patterns for streamlined IAM management.

## Architecture

### Type Safety & Validation
- **dry-struct validation** for role and policy ARN formats
- **ARN format validation** for both AWS managed and customer managed policies
- **Role name/ARN validation** with proper format checking
- **Cross-account policy support** with account ID extraction

### Security Analysis Framework
- **Automatic risk assessment** based on policy type and scope
- **Dangerous policy detection** for administrative access policies
- **Policy categorization** by access level and service scope
- **Security warning system** for high-risk attachments

### AWS Managed Policy Library
- **Complete constant definitions** for AWS managed policies
- **Service-organized structure** (S3, EC2, Lambda, etc.)
- **Pre-defined attachment patterns** for common scenarios
- **Environment-based policy collections** (dev/prod patterns)

## Key Components

### 1. IamRolePolicyAttachmentAttributes Class
```ruby
class IamRolePolicyAttachmentAttributes < Dry::Struct
  attribute :role, Types::String          # Role name or ARN (required)
  attribute :policy_arn, Types::String    # Policy ARN (required)
end
```

### 2. Security Analysis Methods

#### Policy Type Detection
```ruby
def aws_managed_policy?
  policy_arn.include?("arn:aws:iam::aws:policy/")
end

def customer_managed_policy?
  policy_arn.match?(/\Aarn:aws:iam::[0-9]{12}:policy\//)
end
```

#### Risk Assessment
```ruby
def security_risk_level
  if potentially_dangerous?
    :high
  elsif policy_category == :administrative
    :high
  elsif policy_category == :power_user
    :medium
  elsif aws_managed_policy? && policy_category == :read_only
    :low
  elsif customer_managed_policy?
    :medium # Requires manual review
  else
    :low
  end
end
```

### 3. AWS Managed Policies Module

#### Service-Organized Structure
```ruby
module AwsManagedPolicies
  module S3
    FULL_ACCESS = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    READ_ONLY = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  end

  module Lambda
    BASIC_EXECUTION_ROLE = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    VPC_ACCESS_EXECUTION_ROLE = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  end
end
```

### 4. Attachment Patterns Module

#### Common Service Patterns
```ruby
module AttachmentPatterns
  def self.lambda_execution_role_policies
    [AwsManagedPolicies::Lambda::BASIC_EXECUTION_ROLE]
  end

  def self.ecs_task_execution_policies
    [AwsManagedPolicies::ECS::TASK_EXECUTION_ROLE]
  end
end
```

## Implementation Decisions

### 1. Comprehensive Policy Library
- **Complete AWS managed policy coverage** for major services
- **Service-organized constants** for better discoverability
- **Helper methods** for policy organization and filtering
- **Pattern-based collections** for common use cases

### 2. Security-First Approach
- **Automatic risk assessment** for all policy attachments
- **Dangerous policy identification** (AdministratorAccess, etc.)
- **Category-based classification** for policy organization
- **Security warnings** without blocking legitimate use cases

### 3. Cross-Account Support
- **ARN-based role references** for cross-account scenarios
- **Account ID extraction** from customer managed policies
- **Policy ARN validation** for both AWS and customer managed
- **Flexible role specification** (name or ARN)

## Usage Patterns

### 1. Service Role Attachments
```ruby
aws_iam_role_policy_attachment(:lambda_execution, {
  role: "lambda-execution-role",
  policy_arn: AwsManagedPolicies::Lambda::BASIC_EXECUTION_ROLE
})
```

### 2. Pattern-Based Attachments
```ruby
AttachmentPatterns.lambda_execution_role_policies.each_with_index do |policy_arn, index|
  aws_iam_role_policy_attachment(:"lambda_policy_#{index}", {
    role: "lambda-role",
    policy_arn: policy_arn
  })
end
```

### 3. Cross-Account Attachments
```ruby
aws_iam_role_policy_attachment(:cross_account_policy, {
  role: "arn:aws:iam::123456789012:role/CrossAccountRole",
  policy_arn: "arn:aws:iam::987654321098:policy/SharedPolicy"
})
```

## Computed Properties Analysis

### Security Analysis
- `security_risk_level`: Risk assessment (:low, :medium, :high)
- `potentially_dangerous`: Boolean flag for high-risk policies
- `policy_category`: Classification by access type and scope

### Policy Information
- `aws_managed_policy`: Boolean for AWS vs customer managed
- `policy_name`: Extracted policy name from ARN
- `policy_account_id`: Account ID for customer managed policies

### Role Information
- `role_name`: Extracted role name (from ARN if needed)
- `role_specified_by_arn`: Boolean for ARN vs name specification
- `attachment_id`: Unique identifier for the attachment

## Security Considerations

### 1. Policy Risk Classification

#### High Risk Policies
- AdministratorAccess
- PowerUserAccess
- IAMFullAccess
- Policies with broad "*" permissions

#### Medium Risk Policies
- Customer managed policies (require review)
- Power user policies with extensive access
- Cross-service access policies

#### Low Risk Policies
- Read-only AWS managed policies
- Service-specific limited access policies
- Well-scoped customer managed policies

### 2. Automatic Security Warnings
```ruby
def potentially_dangerous?
  dangerous_policies = [
    "AdministratorAccess",
    "PowerUserAccess", 
    "IAMFullAccess",
    "AWSAccountManagementFullAccess"
  ]

  dangerous_policies.any? { |dangerous| policy_name.include?(dangerous) }
end
```

### 3. Policy Categorization System
- `:administrative`: Full administrative access
- `:power_user`: Extensive non-IAM access  
- `:read_only`: Read-only access to resources
- `:service_specific`: Limited to specific AWS services
- `:service_linked`: Service-linked role policies
- `:custom`: Customer-defined policies

## AWS Managed Policy Coverage

### Administrative Policies
- AdministratorAccess
- PowerUserAccess
- IAMFullAccess
- ReadOnlyAccess
- SecurityAudit

### Service-Specific Policies

#### Compute Services
- EC2FullAccess, EC2ReadOnlyAccess
- LambdaFullAccess, LambdaBasicExecutionRole
- ECSTaskExecutionRolePolicy, ECSServiceRolePolicy

#### Storage Services
- S3FullAccess, S3ReadOnlyAccess
- EFSClientRootAccess, EFSClientWrite

#### Database Services
- RDSFullAccess, RDSReadOnlyAccess
- DynamoDBFullAccess, DynamoDBReadOnlyAccess

#### Monitoring & Logging
- CloudWatchFullAccess, CloudWatchReadOnlyAccess
- CloudWatchAgentServerPolicy
- CloudTrailFullAccess

## Common Attachment Patterns

### 1. Lambda Function Patterns
```ruby
# Basic Lambda execution
lambda_execution_role_policies = [
  AwsManagedPolicies::Lambda::BASIC_EXECUTION_ROLE
]

# Lambda with VPC access
lambda_vpc_execution_role_policies = [
  AwsManagedPolicies::Lambda::BASIC_EXECUTION_ROLE,
  AwsManagedPolicies::Lambda::VPC_ACCESS_EXECUTION_ROLE
]
```

### 2. ECS Service Patterns
```ruby
# ECS task execution
ecs_task_execution_policies = [
  AwsManagedPolicies::ECS::TASK_EXECUTION_ROLE
]

# ECS service role
ecs_service_policies = [
  AwsManagedPolicies::ECS::SERVICE_ROLE
]
```

### 3. Environment-Based Patterns
```ruby
# Development (more permissive)
development_policies = [
  AwsManagedPolicies::S3::FULL_ACCESS,
  AwsManagedPolicies::CloudWatch::FULL_ACCESS
]

# Production (restrictive)
production_read_only_policies = [
  AwsManagedPolicies::S3::READ_ONLY,
  AwsManagedPolicies::CloudWatch::READ_ONLY
]
```

## Testing Approach

### 1. Validation Tests
- ARN format validation for policies and roles
- Cross-account policy ARN validation
- Role name format validation
- Invalid ARN rejection testing

### 2. Security Analysis Tests
- Risk level classification accuracy
- Dangerous policy detection
- Policy category assignment
- Security warning generation

### 3. Constants and Patterns Tests
- AWS managed policy ARN accuracy
- Service module organization
- Attachment pattern completeness
- Helper method functionality

### 4. Integration Tests
- Terraform resource generation
- Resource reference outputs
- Computed properties accuracy
- Cross-service integration

## Future Enhancements

### 1. Advanced Security Features
- **Policy conflict detection** across multiple attachments
- **Effective permissions analysis** for combined policies
- **Compliance framework mapping** (SOC2, HIPAA, etc.)
- **Usage analytics** for attached policies

### 2. Enhanced Policy Management
- **Policy version tracking** and updates
- **Attachment lifecycle management** with rollback
- **Policy template generation** from attachments
- **Cross-account trust validation**

### 3. Integration Improvements
- **AWS Config integration** for compliance monitoring
- **CloudTrail integration** for usage tracking
- **Access Analyzer integration** for unused permissions
- **Cost analysis** for policy-based resource access

### 4. Developer Experience
- **IDE integration** with policy documentation
- **Attachment validation** before deployment
- **Policy recommendation engine** based on usage
- **Visual policy mapping** and dependency analysis