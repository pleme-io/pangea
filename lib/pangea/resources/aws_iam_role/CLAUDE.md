# AWS IAM Role Implementation Documentation

## Overview

This directory contains the implementation for the `aws_iam_role` resource function, providing type-safe creation and management of AWS Identity and Access Management (IAM) roles through terraform-synthesizer integration.

## Implementation Architecture

### Core Components

#### 1. Resource Function (`resource.rb`)
The main `aws_iam_role` function that:
- Accepts a symbol name and attributes hash
- Validates attributes using dry-struct types
- Generates terraform resource blocks via terraform-synthesizer
- Returns ResourceReference with computed outputs and properties

#### 2. Type Definitions (`types.rb`)
IamRoleAttributes dry-struct defining:
- Required attributes: `assume_role_policy`
- Optional attributes: `name`, `name_prefix`, `path`, `description`, `permissions_boundary`
- Inline policy support
- Common trust policy templates

#### 3. Documentation
- **CLAUDE.md** (this file): Implementation details for developers
- **README.md**: User-facing documentation with examples

## Technical Implementation Details

### IAM Role Components

#### Trust Policy (Assume Role Policy)
The trust policy defines who can assume the role:
- **Service principals**: AWS services (EC2, Lambda, ECS, etc.)
- **AWS accounts**: Cross-account access
- **Federated identities**: SAML, OIDC providers

#### Permissions
Permissions can be attached in multiple ways:
- **Managed policies**: Attached via `aws_iam_role_policy_attachment`
- **Inline policies**: Defined directly in the role
- **Permissions boundary**: Maximum permissions the role can have

### Type Validation Logic

```ruby
class IamRoleAttributes < Dry::Struct
  # Core validation
  attribute :assume_role_policy, Types::Hash.schema(
    Version: Types::String.default("2012-10-17"),
    Statement: Types::Array.of(
      Types::Hash.schema(
        Effect: Types::String.enum("Allow", "Deny"),
        Principal: Types::Hash,
        Action: Types::String | Types::Array.of(Types::String),
        Condition?: Types::Hash.optional
      )
    )
  )
  
  # Custom validation
  def self.new(attributes = {})
    attrs = super(attributes)
    
    # Cannot use both name and name_prefix
    if attrs.name && attrs.name_prefix
      raise Dry::Struct::Error, "Cannot specify both 'name' and 'name_prefix'"
    end
    
    # Must have at least one statement
    if attrs.assume_role_policy[:Statement].empty?
      raise Dry::Struct::Error, "Assume role policy must have at least one statement"
    end
    
    attrs
  end
end
```

### Terraform Synthesis

The resource function generates terraform JSON through terraform-synthesizer:

```ruby
resource(:aws_iam_role, name) do
  name role_attrs.name if role_attrs.name
  name_prefix role_attrs.name_prefix if role_attrs.name_prefix
  path role_attrs.path if role_attrs.path
  description role_attrs.description if role_attrs.description
  
  # Trust policy (required)
  assume_role_policy JSON.pretty_generate(role_attrs.assume_role_policy)
  
  # Optional configurations
  force_detach_policies role_attrs.force_detach_policies
  max_session_duration role_attrs.max_session_duration
  permissions_boundary role_attrs.permissions_boundary if role_attrs.permissions_boundary
  
  # Inline policies
  if role_attrs.inline_policies.any?
    role_attrs.inline_policies.each do |policy_name, policy_doc|
      inline_policy do
        name policy_name
        policy JSON.pretty_generate(policy_doc)
      end
    end
  end
  
  # Tags
  if role_attrs.tags.any?
    tags do
      role_attrs.tags.each do |key, value|
        public_send(key, value)
      end
    end
  end
end
```

### ResourceReference Return Value

The function returns a ResourceReference providing:

#### Terraform Outputs
- `id`: Role ID (same as name)
- `arn`: Full ARN of the role
- `name`: Role name
- `unique_id`: Unique identifier
- `create_date`: Creation timestamp

#### Computed Properties
- `service_principal`: Extracted service principal from trust policy
- `is_service_role`: Boolean indicating if it's a service role
- `is_federated_role`: Boolean indicating if it's a federated role
- `trust_policy_type`: Type of trust policy (`:service`, `:federated`, `:aws_account`)

#### Usage Pattern
```ruby
# Create role and get reference
ec2_role = aws_iam_role(:ec2_instance, {
  description: "Role for EC2 instances",
  assume_role_policy: TrustPolicies.ec2_service,
  tags: { Application: "web-app" }
})

# Use reference outputs
puts "Role ARN: #{ec2_role.arn}"
puts "Role name: #{ec2_role.name}"
puts "Is service role: #{ec2_role.is_service_role?}"

# Use in instance profile
aws_iam_instance_profile(:ec2_profile, {
  name: "ec2-instance-profile",
  role: ec2_role.name
})
```

## Trust Policy Templates

The implementation includes pre-defined trust policy templates for common scenarios:

### Service Role Templates
```ruby
# EC2 instances
TrustPolicies.ec2_service

# Lambda functions  
TrustPolicies.lambda_service

# ECS tasks
TrustPolicies.ecs_task_service
```

### Cross-Account Access
```ruby
# Trust another AWS account
TrustPolicies.cross_account("123456789012")
```

### Federated Access
```ruby
# SAML federation
TrustPolicies.saml_federated("arn:aws:iam::123456789012:saml-provider/MyProvider")
```

## Integration Patterns

### 1. EC2 Instance Role
```ruby
template :ec2_infrastructure do
  # Create role for EC2 instances
  ec2_role = aws_iam_role(:ec2_instance, {
    name: "MyEC2Role",
    description: "Role for EC2 instances to access S3",
    assume_role_policy: TrustPolicies.ec2_service,
    tags: {
      Purpose: "ec2-s3-access",
      Environment: "production"
    }
  })
  
  # Create instance profile
  ec2_profile = aws_iam_instance_profile(:ec2_profile, {
    name: "MyEC2Profile",
    role: ec2_role.name
  })
  
  # Attach managed policy
  aws_iam_role_policy_attachment(:s3_read_policy, {
    role: ec2_role.name,
    policy_arn: "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  })
  
  # Use in EC2 instance
  aws_instance(:web, {
    ami: "ami-12345678",
    instance_type: "t3.micro",
    iam_instance_profile: ec2_profile.name
  })
end
```

### 2. Lambda Function Role
```ruby
template :serverless_function do
  # Lambda execution role with inline policy
  lambda_role = aws_iam_role(:lambda_exec, {
    name_prefix: "lambda-function-",
    assume_role_policy: TrustPolicies.lambda_service,
    inline_policies: {
      "CloudWatchLogs" => {
        Version: "2012-10-17",
        Statement: [{
          Effect: "Allow",
          Action: [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource: "arn:aws:logs:*:*:*"
        }]
      }
    },
    tags: {
      Function: "data-processor",
      Type: "serverless"
    }
  })
  
  # Use in Lambda function
  aws_lambda_function(:processor, {
    function_name: "data-processor",
    role: lambda_role.arn,
    runtime: "python3.9",
    handler: "index.handler"
  })
end
```

### 3. Cross-Account Access Role
```ruby
template :cross_account_access do
  # Role for cross-account access with conditions
  cross_account_role = aws_iam_role(:cross_account, {
    name: "CrossAccountAccessRole",
    description: "Allow trusted account to access resources",
    assume_role_policy: {
      Version: "2012-10-17",
      Statement: [{
        Effect: "Allow",
        Principal: { AWS: "arn:aws:iam::987654321098:root" },
        Action: "sts:AssumeRole",
        Condition: {
          StringEquals: {
            "sts:ExternalId": "unique-external-id-12345"
          }
        }
      }]
    },
    max_session_duration: 7200,  # 2 hours
    tags: {
      Purpose: "cross-account-access",
      TrustedAccount: "987654321098"
    }
  })
end
```

## Error Handling and Validation

### Common Validation Errors

#### 1. Name Conflicts
```ruby
# ERROR: Both name and name_prefix
aws_iam_role(:bad_role, {
  name: "MyRole",
  name_prefix: "MyRole-",  # Can't use both
  assume_role_policy: TrustPolicies.ec2_service
})
# Raises: Dry::Struct::Error: "Cannot specify both 'name' and 'name_prefix'"
```

#### 2. Invalid Trust Policy
```ruby
# ERROR: Empty statements
aws_iam_role(:bad_role, {
  assume_role_policy: {
    Version: "2012-10-17",
    Statement: []  # Must have at least one statement
  }
})
# Raises: Dry::Struct::Error: "Assume role policy must have at least one statement"
```

#### 3. Session Duration Limits
```ruby
# ERROR: Session duration too long
aws_iam_role(:bad_role, {
  assume_role_policy: TrustPolicies.ec2_service,
  max_session_duration: 86400  # 24 hours, exceeds 12 hour limit
})
# Raises: Dry::Struct::Error due to constraint violation
```

## Testing Strategy

### Unit Tests
```ruby
RSpec.describe Pangea::Resources::AWS do
  describe "#aws_iam_role" do
    it "creates IAM role with valid trust policy" do
      role_ref = aws_iam_role(:test, {
        assume_role_policy: TrustPolicies.ec2_service,
        description: "Test role"
      })
      
      expect(role_ref).to be_a(ResourceReference)
      expect(role_ref.type).to eq('aws_iam_role')
      expect(role_ref.service_principal).to eq('ec2.amazonaws.com')
      expect(role_ref.is_service_role?).to be true
    end
    
    it "validates name exclusivity" do
      expect {
        aws_iam_role(:test, {
          name: "MyRole",
          name_prefix: "MyRole-",
          assume_role_policy: TrustPolicies.ec2_service
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both/)
    end
    
    it "supports inline policies" do
      role_ref = aws_iam_role(:test, {
        assume_role_policy: TrustPolicies.lambda_service,
        inline_policies: {
          "S3Access" => {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: "s3:GetObject",
              Resource: "arn:aws:s3:::my-bucket/*"
            }]
          }
        }
      })
      
      expect(role_ref.resource_attributes[:inline_policies]).to have_key("S3Access")
    end
  end
end
```

## Security Considerations

### 1. Least Privilege
- Start with minimal permissions and add as needed
- Use managed policies when possible
- Avoid wildcard (*) resources unless necessary

### 2. Trust Policy Security
- Always specify conditions for cross-account access
- Use external IDs for third-party access
- Limit session duration appropriately

### 3. Permissions Boundaries
- Use permissions boundaries to limit maximum permissions
- Useful for delegated administration scenarios

### 4. Regular Auditing
- Review and remove unused roles
- Monitor role usage with CloudTrail
- Use access analyzer to identify external access

## Future Enhancements

### 1. Policy Validation
- Validate IAM policy syntax before applying
- Check for overly permissive policies
- Suggest policy improvements

### 2. Trust Policy Builder
- Fluent interface for building complex trust policies
- Validation of principal formats
- Condition builder helpers

### 3. Compliance Templates
- PCI-DSS compliant role templates
- HIPAA compliant role templates
- SOC2 compliant role templates

### 4. Integration Helpers
- Automatic instance profile creation
- Policy attachment helpers
- Role chaining patterns

This implementation provides a robust foundation for IAM role management within the Pangea resource system, emphasizing security, type safety, and ease of use.