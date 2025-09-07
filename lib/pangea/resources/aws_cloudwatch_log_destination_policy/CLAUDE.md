# AWS CloudWatch Log Destination Policy - Architecture Documentation

## Core Concepts

### Policy Design Philosophy

CloudWatch Log Destination Policies implement a critical security layer for cross-account logging architectures. This resource implements:

1. **Zero-Trust Access Control**: Explicit permission model for log destinations
2. **Policy as Code**: Version-controlled access management
3. **Granular Permissions**: Fine-grained control over subscription filter operations
4. **Audit Trail**: Clear documentation of access grants and denials

### Implementation Architecture

```
Destination Policy
├── Policy Document
│   ├── Version
│   ├── Statements[]
│   │   ├── Effect (Allow/Deny)
│   │   ├── Principal
│   │   ├── Action
│   │   ├── Resource
│   │   └── Condition
│   └── Policy Validation
├── Access Analysis
│   ├── Principal Extraction
│   ├── Permission Calculation
│   └── Conflict Detection
└── Update Management
    ├── Policy Versioning
    ├── Force Update Logic
    └── Change Tracking
```

## Type Safety Implementation

### Validation Layers

1. **JSON Validation**
   - Syntax validation
   - Schema compliance
   - Required field verification

2. **Policy Structure Validation**
   - Statement array presence
   - Effect validation (Allow/Deny)
   - Action validation for log operations
   - Resource format checking

3. **Semantic Validation**
   - Principal format verification
   - Condition logic validation
   - Permission conflict detection

### Type Definitions

```ruby
# Policy validation with comprehensive checks
def self.new(attributes)
  # JSON parsing and structure validation
  policy = JSON.parse(attrs[:access_policy])
  
  # Statement-level validation
  policy['Statement'].each do |statement|
    validate_effect(statement['Effect'])
    validate_actions(statement['Action'])
    validate_principals(statement['Principal'])
  end
end
```

## Advanced Patterns

### 1. Progressive Access Control

Implement staged rollout of cross-account access:

```ruby
# Stage 1: Single account pilot
pilot_policy = aws_cloudwatch_log_destination_policy(:pilot, {
  destination_name: destination.name,
  access_policy: jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Sid: "PilotAccess",
      Effect: "Allow",
      Principal: { AWS: "arn:aws:iam::#{pilot_account}:root" },
      Action: "logs:PutSubscriptionFilter",
      Resource: destination.arn,
      Condition: {
        DateGreaterThan: {
          "aws:CurrentTime": "2024-01-01T00:00:00Z"
        },
        DateLessThan: {
          "aws:CurrentTime": "2024-02-01T00:00:00Z"
        }
      }
    }]
  })
})

# Stage 2: Production rollout
prod_policy = aws_cloudwatch_log_destination_policy(:production, {
  destination_name: destination.name,
  access_policy: jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Sid: "ProductionAccess",
        Effect: "Allow",
        Principal: { 
          AWS: production_accounts.map { |acc| "arn:aws:iam::#{acc}:root" }
        },
        Action: "logs:PutSubscriptionFilter",
        Resource: destination.arn
      },
      {
        Sid: "DenyLegacyAccounts",
        Effect: "Deny",
        Principal: { AWS: legacy_accounts.map { |acc| "arn:aws:iam::#{acc}:root" } },
        Action: "logs:PutSubscriptionFilter",
        Resource: destination.arn
      }
    ]
  }),
  force_update: true
})
```

### 2. Service-Based Access Control

Control access based on service identity:

```ruby
# Allow only specific services
service_policy = aws_cloudwatch_log_destination_policy(:service_based, {
  destination_name: destination.name,
  access_policy: jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Effect: "Allow",
      Principal: { AWS: "*" },
      Action: "logs:PutSubscriptionFilter",
      Resource: destination.arn,
      Condition: {
        StringEquals: {
          "aws:PrincipalOrgID": organization.id
        },
        StringLike: {
          "aws:userid": [
            "AIDACKCEVSQ6C2EXAMPLE:*",  # ECS task role
            "AIDAI23HXD87UAT6DO3JR:*"   # Lambda execution role
          ]
        }
      }
    }]
  })
})
```

### 3. Time-Based Access Windows

Implement maintenance windows and temporary access:

```ruby
# Temporary access for migration
migration_policy = aws_cloudwatch_log_destination_policy(:migration, {
  destination_name: destination.name,
  access_policy: jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Sid: "TemporaryMigrationAccess",
      Effect: "Allow",
      Principal: { AWS: migration_accounts.map { |acc| "arn:aws:iam::#{acc}:root" } },
      Action: "logs:PutSubscriptionFilter",
      Resource: destination.arn,
      Condition: {
        DateGreaterThan: {
          "aws:CurrentTime": migration_start_date
        },
        DateLessThan: {
          "aws:CurrentTime": migration_end_date
        },
        IpAddress: {
          "aws:SourceIp": migration_ip_whitelist
        }
      }
    }]
  })
})
```

### 4. Compliance-Driven Policies

Implement regulatory compliance requirements:

```ruby
# HIPAA-compliant access policy
hipaa_policy = aws_cloudwatch_log_destination_policy(:hipaa_compliant, {
  destination_name: hipaa_destination.name,
  access_policy: jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Sid: "HIPAACompliantAccess",
        Effect: "Allow",
        Principal: { AWS: hipaa_accounts.map { |acc| "arn:aws:iam::#{acc}:root" } },
        Action: "logs:PutSubscriptionFilter",
        Resource: hipaa_destination.arn,
        Condition: {
          Bool: {
            "aws:SecureTransport": "true"
          },
          StringEquals: {
            "aws:PrincipalTag/Compliance": "HIPAA",
            "aws:PrincipalTag/DataClassification": "PHI"
          }
        }
      },
      {
        Sid: "DenyNonCompliantAccess",
        Effect: "Deny",
        Principal: "*",
        Action: "logs:PutSubscriptionFilter",
        Resource: hipaa_destination.arn,
        Condition: {
          StringNotEquals: {
            "aws:PrincipalTag/Compliance": "HIPAA"
          }
        }
      }
    ]
  })
})
```

## Security Patterns

### Defense in Depth

```ruby
# Layered security approach
layered_policy = aws_cloudwatch_log_destination_policy(:layered_security, {
  destination_name: secure_destination.name,
  access_policy: jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Sid: "RequireOrganizationMembership",
        Effect: "Deny",
        Principal: "*",
        Action: "logs:PutSubscriptionFilter",
        Resource: destination.arn,
        Condition: {
          StringNotEquals: {
            "aws:PrincipalOrgID": organization.id
          }
        }
      },
      {
        Sid: "RequireSecureTransport",
        Effect: "Deny",
        Principal: "*",
        Action: "logs:PutSubscriptionFilter",
        Resource: destination.arn,
        Condition: {
          Bool: {
            "aws:SecureTransport": "false"
          }
        }
      },
      {
        Sid: "AllowApprovedAccounts",
        Effect: "Allow",
        Principal: { AWS: approved_accounts.map { |acc| "arn:aws:iam::#{acc}:root" } },
        Action: "logs:PutSubscriptionFilter",
        Resource: destination.arn,
        Condition: {
          IpAddress: {
            "aws:SourceIp": corporate_ip_ranges
          }
        }
      }
    ]
  })
})
```

### Least Privilege Implementation

```ruby
# Granular permissions
least_privilege_policy = aws_cloudwatch_log_destination_policy(:least_privilege, {
  destination_name: destination.name,
  access_policy: jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Sid: "AllowSpecificLogGroups",
        Effect: "Allow",
        Principal: { AWS: "arn:aws:iam::123456789012:root" },
        Action: "logs:PutSubscriptionFilter",
        Resource: destination.arn,
        Condition: {
          StringLike: {
            "logs:FilterName": ["app-logs-*", "api-logs-*"]
          }
        }
      },
      {
        Sid: "DenySystemLogs",
        Effect: "Deny",
        Principal: "*",
        Action: "logs:PutSubscriptionFilter",
        Resource: destination.arn,
        Condition: {
          StringLike: {
            "logs:FilterName": ["system-*", "audit-*"]
          }
        }
      }
    ]
  })
})
```

## Policy Analysis Features

### Computed Properties Deep Dive

1. **Principal Analysis**
   ```ruby
   def allowed_principals
     # Extract all principals with Allow effect
     # Handles various principal formats:
     # - { "AWS": "arn:..." }
     # - { "AWS": ["arn:...", "arn:..."] }
     # - { "Service": "logs.amazonaws.com" }
     # - "*"
   end
   ```

2. **Organization Detection**
   ```ruby
   def allows_organization?
     # Detects organization-based access patterns
     # Checks for aws:PrincipalOrgID conditions
   end
   ```

3. **Account Extraction**
   ```ruby
   def allowed_account_ids
     # Parses ARNs to extract account IDs
     # Returns unique list of allowed accounts
   end
   ```

## Monitoring and Compliance

### Policy Audit Trail

```ruby
# Track policy changes
policy_versions = []

# Version 1: Initial policy
v1_policy = aws_cloudwatch_log_destination_policy(:v1, {
  destination_name: destination.name,
  access_policy: initial_policy_json
})
policy_versions << { version: 1, date: Time.now, policy: v1_policy }

# Version 2: Updated policy
v2_policy = aws_cloudwatch_log_destination_policy(:v2, {
  destination_name: destination.name,
  access_policy: updated_policy_json,
  force_update: true
})
policy_versions << { version: 2, date: Time.now, policy: v2_policy }

# Generate audit report
audit_report = policy_versions.map do |pv|
  {
    version: pv[:version],
    date: pv[:date],
    allowed_accounts: pv[:policy].allowed_account_ids,
    changes: calculate_changes(pv[:policy], policy_versions[pv[:version]-2]&.dig(:policy))
  }
end
```

### Compliance Validation

```ruby
# Validate policy meets compliance requirements
def validate_compliance(policy)
  violations = []
  
  # Check for wildcard principals
  if policy.allows_all_accounts?
    violations << "Policy allows all accounts (non-compliant)"
  end
  
  # Check for secure transport
  unless policy_requires_secure_transport?(policy)
    violations << "Policy doesn't require secure transport"
  end
  
  # Check for organization boundary
  unless policy.allows_organization?
    violations << "Policy doesn't restrict to organization"
  end
  
  violations
end
```

## Troubleshooting Guide

### Policy Conflict Resolution

1. **Explicit Deny Takes Precedence**
   - Deny statements always override Allow statements
   - Check for conflicting Deny rules
   - Use policy simulator to test access

2. **Condition Evaluation**
   - All conditions must be true for statement to apply
   - Use CloudTrail to see evaluated conditions
   - Test with minimal conditions first

3. **Principal Format Issues**
   - Use full ARN format for accounts
   - Verify service principals are correct
   - Check for typos in account IDs

### Debug Techniques

```ruby
# Add debug information to policy
debug_policy = aws_cloudwatch_log_destination_policy(:debug, {
  destination_name: destination.name,
  access_policy: jsonencode({
    Version: "2012-10-17",
    Statement: [{
      Sid: "DebugAccess_#{Time.now.to_i}",
      Effect: "Allow",
      Principal: { AWS: test_account_arn },
      Action: "logs:PutSubscriptionFilter",
      Resource: destination.arn,
      Condition: {
        StringEquals: {
          "aws:userid": "${aws:userid}"  # Will be logged in CloudTrail
        }
      }
    }]
  })
})
```

## Future Enhancements

### Planned Features

1. **Policy Templates**: Pre-built policies for common scenarios
2. **Conflict Detection**: Automatic detection of policy conflicts
3. **Policy Optimizer**: Simplify complex policies automatically
4. **Compliance Profiles**: Built-in compliance validation

### Extension Points

The current implementation provides extension points for:
- Custom policy validators
- Policy transformation pipelines
- Compliance rule engines
- Automated policy generation