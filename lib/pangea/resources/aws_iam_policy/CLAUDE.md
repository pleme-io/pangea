# AWS IAM Policy Implementation

## Overview

This implementation provides type-safe AWS IAM customer-managed policy creation with comprehensive security validation, policy templates, and complexity analysis.

## Architecture

### Type Safety & Validation
- **dry-struct validation** for all policy attributes
- **Policy document structure validation** with proper IAM schema
- **Path format validation** (must start/end with /, 1-512 chars)
- **Policy size validation** (max 6144 chars for managed policies)
- **Reserved name detection** (AWS/Amazon prefixes)

### Security Features
- **Automatic security analysis** with risk level assessment
- **Wildcard permission detection** with warnings
- **Dangerous action identification** (iam:*, admin actions)
- **Root resource access warnings**
- **Complexity scoring** for policy review

### Policy Templates
- **Pre-defined templates** for common use cases
- **Service-specific policies** (S3, CloudWatch, RDS, Lambda, etc.)
- **Security-focused patterns** with least privilege principles
- **Cross-service access patterns** for microservices

## Key Components

### 1. IamPolicyAttributes Class
```ruby
class IamPolicyAttributes < Dry::Struct
  attribute :name, Types::String                    # Policy name (required)
  attribute :path, Types::String.default("/")       # Policy path
  attribute? :description, Types::String.optional   # Policy description
  attribute :policy, Types::Hash.schema(...)        # Policy document
  attribute :tags, Types::AwsTags.default({})       # Resource tags
end
```

### 2. Policy Document Schema
```ruby
Types::Hash.schema(
  Version: Types::String.default("2012-10-17"),
  Statement: Types::Array.of(
    Types::Hash.schema(
      Sid?: Types::String.optional,
      Effect: Types::String.enum("Allow", "Deny"),
      Action: Types::String | Types::Array.of(Types::String),
      Resource: Types::String | Types::Array.of(Types::String),
      Condition?: Types::Hash.optional,
      # Additional IAM-specific fields...
    )
  )
)
```

### 3. Security Validation Methods

#### Risk Assessment
```ruby
def security_level
  if has_wildcard_permissions?
    :high_risk
  elsif allows_action?("iam:*") || allows_action?("sts:AssumeRole")
    :medium_risk
  else
    :low_risk
  end
end
```

#### Complexity Scoring
```ruby
def complexity_score
  statements_count = policy[:Statement].length
  actions_count = all_actions.length
  resources_count = all_resources.length
  conditions_count = policy[:Statement].count { |s| s[:Condition] }
  
  statements_count + actions_count + resources_count + (conditions_count * 2)
end
```

### 4. Policy Templates Module

#### S3 Access Patterns
```ruby
module PolicyTemplates
  def self.s3_bucket_readonly(bucket_name)
    {
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Action: ["s3:GetObject", "s3:GetObjectVersion"],
          Resource: "arn:aws:s3:::#{bucket_name}/*"
        },
        {
          Effect: "Allow", 
          Action: ["s3:ListBucket"],
          Resource: "arn:aws:s3:::#{bucket_name}"
        }
      ]
    }
  end
end
```

## Implementation Decisions

### 1. Security-First Approach
- **Automatic warnings** for overly permissive policies
- **Best practice guidance** through computed properties
- **Template-based policies** following least privilege
- **Risk assessment** for all policies

### 2. Comprehensive Validation
- **Schema validation** for policy document structure
- **Size constraints** matching AWS limits
- **Format validation** for paths and names
- **Content analysis** for security implications

### 3. Developer Experience
- **Rich computed properties** for policy analysis
- **Template library** for common patterns
- **Clear error messages** for validation failures
- **Security guidance** through warnings and scoring

## Usage Patterns

### 1. Simple Policies
```ruby
aws_iam_policy(:readonly_policy, {
  name: "ReadOnlyAccess",
  policy: PolicyTemplates.s3_bucket_readonly("my-bucket")
})
```

### 2. Complex Conditional Policies
```ruby
aws_iam_policy(:conditional_policy, {
  name: "ConditionalAccess",
  policy: {
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Action: "s3:GetObject",
      Resource: "*",
      Condition: {
        IpAddress: { "aws:SourceIp": "203.0.113.0/24" },
        DateGreaterThan: { "aws:CurrentTime": "08:00Z" }
      }
    }]
  }
})
```

### 3. Multi-Statement Policies
```ruby
aws_iam_policy(:microservice_policy, {
  name: "MicroserviceAccess", 
  policy: {
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: ["s3:GetObject", "s3:PutObject"],
        Resource: "arn:aws:s3:::app-data/*"
      },
      {
        Effect: "Allow",
        Action: "logs:CreateLogStream",
        Resource: "arn:aws:logs:*:*:log-group:/aws/lambda/app-*"
      }
    ]
  }
})
```

## Computed Properties Analysis

The implementation provides rich computed properties for policy analysis:

### Security Analysis
- `security_level`: Risk assessment (:low_risk, :medium_risk, :high_risk)
- `has_wildcard_permissions`: Boolean wildcard detection
- `complexity_score`: Numeric complexity for review prioritization

### Content Analysis
- `all_actions`: Complete list of actions across all statements
- `all_resources`: Complete list of resources across all statements
- `service_role_policy`: Identifies policies for role assumption

### Validation Helpers
- `uses_reserved_name`: Detects AWS reserved naming patterns
- `allows_action?(action)`: Tests if policy allows specific action

## Security Considerations

### 1. Automatic Security Analysis
```ruby
def validate_policy_security!
  warnings = []

  if has_wildcard_permissions?
    warnings << "Policy contains wildcard (*) permissions"
  end

  dangerous_actions = ["iam:*", "iam:CreateRole", "iam:AttachRolePolicy"]
  dangerous_actions.each do |action|
    if allows_action?(action)
      warnings << "Policy allows potentially dangerous action: #{action}"
    end
  end

  # Log warnings but don't fail validation
  unless warnings.empty?
    puts "IAM Policy Security Warnings for '#{name}':"
    warnings.each { |warning| puts "  - #{warning}" }
  end
end
```

### 2. Best Practice Templates
- **Least privilege** policy templates
- **Service-specific** access patterns
- **Conditional access** examples
- **Cross-service** integration patterns

### 3. Compliance Support
- **Policy complexity scoring** for review processes
- **Security level classification** for risk management
- **Automatic documentation** through computed properties
- **Audit trail** through comprehensive resource references

## Testing Approach

### 1. Type Safety Tests
- Validate all dry-struct constraints
- Test policy document schema validation
- Verify size and format constraints

### 2. Security Validation Tests
- Test security warning generation
- Verify risk level classification
- Check complexity scoring accuracy

### 3. Template Tests
- Validate all policy templates
- Test template parameter substitution
- Verify generated policy correctness

### 4. Integration Tests
- Test with terraform-synthesizer
- Verify resource reference outputs
- Check computed properties accuracy

## Future Enhancements

### 1. Advanced Security Features
- **Policy simulation** integration with AWS APIs
- **Least privilege recommendations** based on usage
- **Cross-policy conflict detection**
- **Automated policy optimization**

### 2. Enhanced Templates
- **Industry-specific** policy templates
- **Compliance framework** templates (SOC2, HIPAA, etc.)
- **Multi-cloud** policy translation
- **Dynamic policy generation** based on resources

### 3. Integration Features
- **Policy version management** and rollback
- **Cross-account policy** validation
- **Service catalog** integration
- **Cost impact analysis** for policies