# AWS Secrets Manager Secret Implementation

## Resource Overview

**Resource Type**: `aws_secretsmanager_secret`  
**Terraform Provider**: AWS  
**Purpose**: Secure storage and management of sensitive configuration data

## Implementation Architecture

### Type Safety Structure

```
SecretsManagerSecretAttributes (dry-struct)
├── name (SecretName) - Secret identifier with AWS naming rules
├── description (String) - Human-readable description
├── kms_key_id (String) - KMS key for encryption (ID/ARN/alias)
├── policy (SecretResourcePolicy) - Resource-based access policy JSON
├── recovery_window_in_days (SecretsManagerRecoveryWindowInDays) - 7-30 days
├── force_overwrite_replica_secret (Bool) - Replica overwrite control
├── replica (Array<SecretsManagerReplicaRegion>) - Cross-region replication
└── tags (AwsTags) - Resource tagging
```

### Validation Logic

**Secret Name Validation**:
```ruby
SecretName = String.constrained(
  format: /\A[a-zA-Z0-9\/_+=.@-]{1,512}\z/
).constructor { |value|
  # AWS Secrets Manager naming rules enforcement
  if value.start_with?('/') || value.end_with?('/')
    raise Dry::Types::ConstraintError, "Secret name cannot start or end with slash"
  end
  
  if value.include?('//')
    raise Dry::Types::ConstraintError, "Secret name cannot contain consecutive slashes"
  end
  
  value
}

def self.validate_secret_name(name)
  # Length limit: 512 characters max
  if name.length > 512
    raise Dry::Struct::Error, "Secret name too long: #{name.length} characters (max 512)"
  end
  
  # Valid characters: alphanumeric + /_+=.@-
  unless name.match?(/\A[a-zA-Z0-9\/_+=.@-]+\z/)
    raise Dry::Struct::Error, "Secret name contains invalid characters: #{name}"
  end
end
```

**KMS Key ID Validation**:
```ruby
def self.validate_kms_key_id(key_id)
  valid_formats = [
    /\A[a-f0-9-]{36}\z/,  # Key ID: 12345678-1234-1234-1234-123456789012
    /\Aarn:aws:kms:[a-z0-9-]+:\d{12}:key\/[a-f0-9-]{36}\z/,  # Key ARN
    /\Aalias\/[a-zA-Z0-9:/_-]+\z/,  # Alias name: alias/my-key
    /\Aarn:aws:kms:[a-z0-9-]+:\d{12}:alias\/[a-zA-Z0-9:/_-]+\z/  # Alias ARN
  ]
  
  unless valid_formats.any? { |format| key_id.match?(format) }
    raise Dry::Struct::Error, "Invalid KMS key ID format: #{key_id}"
  end
end
```

**Secret Policy Validation**:
```ruby
SecretResourcePolicy = String.constructor { |value|
  begin
    parsed = JSON.parse(value)
    unless parsed.is_a?(Hash)
      raise Dry::Types::ConstraintError, "Secret policy must be a JSON object"
    end
    
    # Verify essential policy structure
    unless parsed['Version'] && parsed['Statement']
      raise Dry::Types::ConstraintError, "Secret policy should have Version and Statement fields"
    end
    
    value
  rescue JSON::ParserError => e
    raise Dry::Types::ConstraintError, "Invalid JSON in secret policy: #{e.message}"
  end
}
```

**Cross-Region Replica Validation**:
```ruby
def self.validate_replica_config(replicas)
  # Check for duplicate regions
  regions = replicas.map { |r| r[:region] }
  if regions.uniq.length != regions.length
    raise Dry::Struct::Error, "Duplicate regions found in replica configuration"
  end
  
  # Validate KMS key for each replica
  replicas.each do |replica|
    if replica[:kms_key_id]
      validate_kms_key_id(replica[:kms_key_id])
    end
  end
end
```

### Resource Synthesis

**Terraform Resource Generation**:
```ruby
resource(:aws_secretsmanager_secret, name) do
  # Optional secret name (AWS generates if omitted)
  name secret_attrs.name if secret_attrs.name
  
  # Optional description
  description secret_attrs.description if secret_attrs.description
  
  # KMS encryption key (uses AWS managed key if omitted)
  kms_key_id secret_attrs.kms_key_id if secret_attrs.kms_key_id
  
  # Resource-based policy
  policy secret_attrs.policy if secret_attrs.policy
  
  # Recovery configuration
  recovery_window_in_days secret_attrs.recovery_window_in_days if secret_attrs.recovery_window_in_days
  
  # Cross-region replication
  if secret_attrs.replica&.any?
    secret_attrs.replica.each do |replica_config|
      replica do
        region replica_config[:region]
        kms_key_id replica_config[:kms_key_id] if replica_config[:kms_key_id]
      end
    end
  end
  
  # Resource tagging
  if secret_attrs.tags&.any?
    tags do
      secret_attrs.tags.each { |key, value| public_send(key, value) }
    end
  end
end
```

### Output Mapping

**Resource Reference Outputs**:
```ruby
outputs: {
  id: "${aws_secretsmanager_secret.#{name}.id}",                           # Secret unique ID
  arn: "${aws_secretsmanager_secret.#{name}.arn}",                         # Secret ARN (for IAM policies)
  name: "${aws_secretsmanager_secret.#{name}.name}",                       # Secret name (for API calls)
  description: "${aws_secretsmanager_secret.#{name}.description}",         # Secret description
  kms_key_id: "${aws_secretsmanager_secret.#{name}.kms_key_id}",          # KMS key used
  policy: "${aws_secretsmanager_secret.#{name}.policy}",                   # Resource policy JSON
  recovery_window_in_days: "${aws_secretsmanager_secret.#{name}.recovery_window_in_days}", # Recovery period
  replica: "${aws_secretsmanager_secret.#{name}.replica}"                  # Replica configuration
}
```

## Security Implementation Details

### Encryption Management

**AWS Managed Encryption (Default)**:
```ruby
# Uses aws/secretsmanager key automatically
secret = aws_secretsmanager_secret(:default_encryption, {
  name: "app/config"
  # kms_key_id omitted - uses AWS managed key
})
```

**Customer Managed KMS Key**:
```ruby
# Custom KMS key for enhanced control
custom_key = aws_kms_key(:secrets_key, {
  description: "Secrets Manager encryption key",
  key_usage: "ENCRYPT_DECRYPT",
  enable_key_rotation: true
})

secret = aws_secretsmanager_secret(:custom_encryption, {
  name: "app/secure-config",
  kms_key_id: custom_key.arn  # Use customer managed key
})
```

### Access Control Patterns

**Resource-Based Policy Example**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowApplicationAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/ApplicationRole"
      },
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "secretsmanager:VersionStage": "AWSCURRENT"
        },
        "DateLessThan": {
          "aws:TokenIssueTime": "2024-01-01T01:00:00Z"
        }
      }
    },
    {
      "Sid": "DenyDirectUserAccess",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalType": "User"
        }
      }
    }
  ]
}
```

**IAM Policy for Secret Access**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:123456789012:secret:production/app/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "secretsmanager.us-east-1.amazonaws.com"
        }
      }
    }
  ]
}
```

### Cross-Region Replication

**Multi-Region Secret Configuration**:
```ruby
# Primary secret with replicas
global_secret = aws_secretsmanager_secret(:global_config, {
  name: "global/app/config",
  replica: [
    {
      region: "us-west-2",
      kms_key_id: "alias/secrets-west"  # Region-specific KMS key
    },
    {
      region: "eu-west-1",
      kms_key_id: "arn:aws:kms:eu-west-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    },
    {
      region: "ap-southeast-1"
      # Uses AWS managed key in this region
    }
  ]
})
```

**Replica Security Considerations**:
- Each replica can have its own KMS key
- IAM permissions must exist in each replica region
- Network connectivity required for replication
- Eventual consistency across regions

## Computed Properties

**Secret Analysis Methods**:
```ruby
def is_cross_region?
  replica&.any?
end

def replica_count
  replica&.length || 0
end

def uses_custom_kms_key?
  !kms_key_id.nil?
end

def secret_scope
  if is_cross_region?
    "Multi-region secret replicated to #{replica_count} regions"
  else
    "Single-region secret"
  end
end

def encryption_details
  if uses_custom_kms_key?
    "Custom KMS key: #{kms_key_id}"
  else
    "AWS managed key (aws/secretsmanager)"
  end
end
```

## AWS Service Integration Patterns

### RDS Database Integration

```ruby
# Secret for RDS master password
db_secret = aws_secretsmanager_secret(:rds_master, {
  name: "production/rds/master-password",
  description: "RDS master user password"
})

# RDS instance with Secrets Manager integration
db_instance = aws_db_instance(:primary_db, {
  identifier: "production-db",
  engine: "postgres",
  instance_class: "db.t3.micro",
  
  # Automatic password management
  manage_master_user_password: true,
  master_user_secret_kms_key_id: db_secret.kms_key_id,
  
  username: "admin",
  # Password stored in Secrets Manager automatically
})
```

### Lambda Function Integration

```ruby
# Application secrets
app_secrets = aws_secretsmanager_secret(:app_config, {
  name: "production/lambda/config",
  description: "Lambda function configuration"
})

# Lambda function with secret access
lambda_function = aws_lambda_function(:app_function, {
  function_name: "production-app",
  runtime: "python3.12",
  
  # Pass secret ARN via environment
  environment: {
    variables: {
      SECRETS_ARN: app_secrets.arn,
      SECRET_NAME: app_secrets.name
    }
  }
})

# IAM role for Lambda secret access
lambda_role = aws_iam_role(:lambda_secrets_role, {
  assume_role_policy: lambda_trust_policy.to_json
})

# Policy for secret access
secret_access_policy = aws_iam_policy(:lambda_secret_access, {
  policy: {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": app_secrets.arn
    }]
  }.to_json
})
```

### ECS/Fargate Integration

```ruby
# Secrets for ECS task
ecs_secrets = aws_secretsmanager_secret(:ecs_app_config, {
  name: "production/ecs/application-config",
  description: "ECS application secrets"
})

# ECS task definition with secrets
task_definition = aws_ecs_task_definition(:app_task, {
  family: "production-app",
  container_definitions: [
    {
      name: "app",
      image: "app:latest",
      secrets: [
        {
          name: "DATABASE_PASSWORD",
          valueFrom: ecs_secrets.arn
        }
      ]
    }
  ].to_json
})
```

## Lifecycle Management

### Secret Recovery Window

```ruby
# Production secret with full recovery window
prod_secret = aws_secretsmanager_secret(:prod_critical, {
  name: "production/critical/api-keys",
  recovery_window_in_days: 30,  # Maximum recovery time
  force_overwrite_replica_secret: false  # Prevent accidental overwrite
})

# Development secret with minimal recovery
dev_secret = aws_secretsmanager_secret(:dev_config, {
  name: "development/app/config", 
  recovery_window_in_days: 7,    # Minimum recovery time
  force_overwrite_replica_secret: true   # Allow quick iteration
})
```

### Secret Rotation Integration

```ruby
# Secret with automatic rotation capability
rotated_secret = aws_secretsmanager_secret(:rotated_db_password, {
  name: "production/database/rotated-password",
  description: "Database password with automatic rotation",
  tags: {
    RotationEnabled: "true",
    RotationInterval: "30-days"
  }
})

# Lambda function for secret rotation (would be defined separately)
# rotation_lambda = aws_lambda_function(:rotation_function, {...})

# Secret rotation configuration (would use aws_secretsmanager_secret_rotation)
# rotation_config = aws_secretsmanager_secret_rotation(:db_rotation, {
#   secret_id: rotated_secret.arn,
#   rotation_lambda_arn: rotation_lambda.arn,
#   rotation_rules: {
#     automatically_after_days: 30
#   }
# })
```

## Error Handling & Troubleshooting

### Common Validation Errors

1. **Invalid Secret Name Format**:
   ```
   Error: Secret name contains invalid characters: my-secret!
   ```
   - **Cause**: Special characters not allowed in secret names
   - **Solution**: Use only: `a-z`, `A-Z`, `0-9`, `/`, `_`, `+`, `=`, `.`, `@`, `-`

2. **KMS Key Access Issues**:
   ```
   Error: User is not authorized to perform: kms:CreateGrant
   ```
   - **Cause**: Insufficient KMS permissions for Secrets Manager
   - **Solution**: Add Secrets Manager to KMS key policy

3. **Replica Region Configuration**:
   ```
   Error: Cannot create replica in region us-west-2
   ```
   - **Cause**: KMS key not available in replica region
   - **Solution**: Ensure KMS key exists in target region

4. **Policy JSON Validation**:
   ```
   Error: Invalid JSON in secret policy
   ```
   - **Cause**: Malformed JSON in resource policy
   - **Solution**: Validate JSON syntax and structure

### Production Validation Checklist

- [ ] Secret name follows organizational naming conventions
- [ ] KMS key policy allows Secrets Manager service access
- [ ] Resource policy restricts access to required principals only
- [ ] Cross-region replicas have appropriate KMS keys
- [ ] Recovery window appropriate for secret criticality
- [ ] IAM roles have minimal required permissions
- [ ] Tags applied for resource management and billing

### Monitoring & Observability

**CloudWatch Metrics**:
- Secret access frequency
- Failed secret retrievals
- Cross-region replication lag
- KMS key usage for secrets

**Operational Alerts**:
- Secret access from unexpected sources
- Failed secret replications
- KMS key access denials
- Secret policy violations

This implementation provides enterprise-grade secret management with comprehensive security controls, cross-region capabilities, and seamless integration with AWS services while maintaining strict type safety and validation.