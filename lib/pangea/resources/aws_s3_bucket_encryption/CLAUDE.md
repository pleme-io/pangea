# AWS S3 Bucket Encryption Implementation

## Implementation Overview

The `aws_s3_bucket_encryption` resource provides type-safe S3 bucket server-side encryption configuration with comprehensive algorithm support and validation.

## Architecture

```
S3BucketEncryptionAttributes (dry-struct)
    ↓ validates
Encryption Rules Configuration
    ↓ synthesizes
aws_s3_bucket_server_side_encryption_configuration (terraform)
    ↓ returns
ResourceReference with encryption analysis
```

## Type Safety

### Attributes Structure
- **bucket**: Required string bucket name
- **server_side_encryption_configuration**: Required hash with rule array
- **expected_bucket_owner**: Optional string for multi-account scenarios

### Encryption Rule Schema
```ruby
server_side_encryption_configuration: Resources::Types::Hash.schema(
  rule: Resources::Types::Array.of(
    Resources::Types::Hash.schema(
      apply_server_side_encryption_by_default: Resources::Types::Hash.schema(
        sse_algorithm: Resources::Types::String.enum('AES256', 'aws:kms', 'aws:kms:dsse'),
        kms_master_key_id?: Resources::Types::String.optional
      ),
      bucket_key_enabled?: Resources::Types::Bool.optional
    )
  )
)
```

## Validation Logic

### Rule Validation
```ruby
def self.new(attributes = {})
  # Ensure at least one encryption rule
  unless attrs.server_side_encryption_configuration[:rule]&.any?
    raise Dry::Struct::Error, "Must have at least one encryption rule"
  end
  
  # Validate each rule
  attrs.server_side_encryption_configuration[:rule].each_with_index do |rule, index|
    validate_encryption_rule(rule, index)
  end
end
```

### KMS Key Validation
```ruby
def validate_encryption_rule(rule, index)
  encryption_config = rule[:apply_server_side_encryption_by_default]
  algorithm = encryption_config[:sse_algorithm]

  # KMS algorithms require key ID
  if (algorithm == 'aws:kms' || algorithm == 'aws:kms:dsse') && 
     encryption_config[:kms_master_key_id].nil?
    raise Dry::Struct::Error, "kms_master_key_id required for #{algorithm} in rule #{index}"
  end

  # AES256 should not have KMS key
  if algorithm == 'AES256' && encryption_config[:kms_master_key_id]
    raise Dry::Struct::Error, "kms_master_key_id not allowed for AES256 in rule #{index}"
  end
end
```

## Encryption Algorithm Support

### AES-256 (SSE-S3)
- **Algorithm**: `AES256`
- **Key Management**: AWS S3 managed
- **Cost**: No additional cost
- **Use Case**: Standard encryption needs

### AWS KMS (SSE-KMS)
- **Algorithm**: `aws:kms`
- **Key Management**: AWS KMS customer-managed or AWS-managed keys
- **Cost**: KMS API request charges
- **Use Case**: Compliance, audit trail, fine-grained access control

### KMS Dual-layer (SSE-KMS-DSSE)
- **Algorithm**: `aws:kms:dsse`
- **Key Management**: AWS KMS with dual encryption
- **Cost**: Higher than standard KMS
- **Use Case**: Highest security requirements, regulatory compliance

## Helper Methods

### Algorithm Analysis
```ruby
def primary_encryption_algorithm
  server_side_encryption_configuration[:rule].first[:apply_server_side_encryption_by_default][:sse_algorithm]
end

def uses_kms_encryption?
  server_side_encryption_configuration[:rule].any? do |rule|
    alg = rule[:apply_server_side_encryption_by_default][:sse_algorithm]
    alg == 'aws:kms' || alg == 'aws:kms:dsse'
  end
end

def uses_aes256_encryption?
  server_side_encryption_configuration[:rule].any? do |rule|
    rule[:apply_server_side_encryption_by_default][:sse_algorithm] == 'AES256'
  end
end
```

### Configuration Analysis
```ruby
def encryption_rules_count
  server_side_encryption_configuration[:rule].size
end

def bucket_key_enabled?
  server_side_encryption_configuration[:rule].any? { |rule| rule[:bucket_key_enabled] == true }
end

def kms_key_ids
  server_side_encryption_configuration[:rule]
    .map { |rule| rule[:apply_server_side_encryption_by_default][:kms_master_key_id] }
    .compact
end
```

## Terraform Integration

### Resource Generation
```ruby
resource(:aws_s3_bucket_server_side_encryption_configuration, name) do
  bucket encryption_attrs.bucket
  expected_bucket_owner encryption_attrs.expected_bucket_owner if encryption_attrs.expected_bucket_owner
  
  encryption_attrs.server_side_encryption_configuration[:rule].each do |rule_config|
    rule do
      apply_server_side_encryption_by_default do
        sse_algorithm rule_config[:apply_server_side_encryption_by_default][:sse_algorithm]
        kms_master_key_id rule_config[:apply_server_side_encryption_by_default][:kms_master_key_id] if rule_config[:apply_server_side_encryption_by_default][:kms_master_key_id]
      end
      bucket_key_enabled rule_config[:bucket_key_enabled] if rule_config.key?(:bucket_key_enabled)
    end
  end
end
```

### Output Properties
- `id`: Encryption configuration ID
- `bucket`: Associated bucket name

## Computed Properties

### Configuration Analysis
- **encryption_rules_count**: Number of encryption rules
- **primary_encryption_algorithm**: Algorithm used in first rule
- **uses_kms_encryption**: Whether any rule uses KMS
- **uses_aes256_encryption**: Whether any rule uses AES256
- **bucket_key_enabled**: Whether S3 bucket keys are enabled
- **kms_key_ids**: Array of KMS key IDs used

### Usage Pattern
```ruby
encryption_ref = aws_s3_bucket_encryption(:bucket_encryption, {...})

puts "Encryption: #{encryption_ref.computed[:primary_encryption_algorithm]}"
puts "Uses KMS: #{encryption_ref.computed[:uses_kms_encryption]}"
puts "Bucket key enabled: #{encryption_ref.computed[:bucket_key_enabled]}"
```

## Implementation Patterns

### Basic AES-256 Encryption
```ruby
aes256_encryption = aws_s3_bucket_encryption(:aes256, {
  bucket: "standard-bucket",
  server_side_encryption_configuration: {
    rule: [{
      apply_server_side_encryption_by_default: {
        sse_algorithm: "AES256"
      }
    }]
  }
})
```

### KMS with Bucket Key
```ruby
kms_with_bucket_key = aws_s3_bucket_encryption(:kms_optimized, {
  bucket: "kms-bucket",
  server_side_encryption_configuration: {
    rule: [{
      apply_server_side_encryption_by_default: {
        sse_algorithm: "aws:kms",
        kms_master_key_id: "alias/s3-bucket-key"
      },
      bucket_key_enabled: true  # Reduces KMS costs
    }]
  }
})
```

### Dual-layer Security
```ruby
dsse_encryption = aws_s3_bucket_encryption(:ultra_secure, {
  bucket: "classified-bucket",
  server_side_encryption_configuration: {
    rule: [{
      apply_server_side_encryption_by_default: {
        sse_algorithm: "aws:kms:dsse",
        kms_master_key_id: "arn:aws:kms:us-east-1:123456789012:key/key-id"
      },
      bucket_key_enabled: true
    }]
  }
})
```

### Multiple Rules (Advanced)
```ruby
multi_rule_encryption = aws_s3_bucket_encryption(:multi_rule, {
  bucket: "mixed-content-bucket",
  server_side_encryption_configuration: {
    rule: [
      {
        apply_server_side_encryption_by_default: {
          sse_algorithm: "AES256"
        }
      },
      {
        apply_server_side_encryption_by_default: {
          sse_algorithm: "aws:kms",
          kms_master_key_id: "alias/high-security-key"
        },
        bucket_key_enabled: true
      }
    ]
  }
})
```

## Integration Points

### With KMS Keys
```ruby
# Create KMS key for S3 encryption
s3_key = aws_kms_key(:s3_encryption_key, {
  description: "S3 bucket encryption key",
  key_usage: "ENCRYPT_DECRYPT"
})

# Use key in bucket encryption
bucket_encryption = aws_s3_bucket_encryption(:bucket_encryption, {
  bucket: "encrypted-bucket",
  server_side_encryption_configuration: {
    rule: [{
      apply_server_side_encryption_by_default: {
        sse_algorithm: "aws:kms",
        kms_master_key_id: s3_key.arn
      },
      bucket_key_enabled: true
    }]
  }
})
```

### With Bucket Policies
```ruby
# Enforce encryption via bucket policy
aws_s3_bucket_policy(:enforce_encryption, {
  bucket: "encrypted-bucket",
  policy: JSON.generate({
    Version: "2012-10-17",
    Statement: [{
      Sid: "DenyUnencryptedObjectUploads",
      Effect: "Deny",
      Principal: "*",
      Action: "s3:PutObject",
      Resource: "arn:aws:s3:::encrypted-bucket/*",
      Condition: {
        StringNotEquals: {
          "s3:x-amz-server-side-encryption": "aws:kms"
        }
      }
    }]
  })
})
```

### With S3 Objects
```ruby
# Objects inherit bucket encryption by default
encrypted_object = aws_s3_object(:secure_file, {
  bucket: "encrypted-bucket",  # Uses bucket's encryption
  key: "secure-data.json",
  source: "/path/to/secure-data.json"
  # server_side_encryption inherited from bucket
})

# Override bucket encryption for specific objects
override_object = aws_s3_object(:override_encryption, {
  bucket: "encrypted-bucket",
  key: "special-file.txt",
  source: "/path/to/special-file.txt",
  server_side_encryption: "AES256",  # Override bucket KMS with AES256
})
```

## Best Practices Implementation

### Cost Optimization with Bucket Keys
```ruby
# Always enable bucket keys for KMS encryption to reduce costs
cost_optimized = aws_s3_bucket_encryption(:cost_optimized, {
  bucket: "high-volume-bucket",
  server_side_encryption_configuration: {
    rule: [{
      apply_server_side_encryption_by_default: {
        sse_algorithm: "aws:kms",
        kms_master_key_id: "alias/volume-key"
      },
      bucket_key_enabled: true  # Critical for cost management
    }]
  }
})
```

### Compliance-Ready Configuration
```ruby
compliance_encryption = aws_s3_bucket_encryption(:compliance, {
  bucket: "compliance-bucket",
  server_side_encryption_configuration: {
    rule: [{
      apply_server_side_encryption_by_default: {
        sse_algorithm: "aws:kms:dsse",  # Highest security
        kms_master_key_id: "arn:aws:kms:us-east-1:123456789012:key/compliance-key"
      },
      bucket_key_enabled: true
    }]
  }
})
```

### Environment-Specific Encryption
```ruby
template :multi_environment_encryption do
  environments = ["dev", "staging", "prod"]
  
  environments.each do |env|
    # Environment-specific algorithm choice
    algorithm = case env
                when "dev" then "AES256"      # Cost-effective for dev
                when "staging" then "aws:kms" # KMS for staging tests
                when "prod" then "aws:kms:dsse" # Maximum security for prod
                end

    aws_s3_bucket_encryption(:"#{env}_encryption", {
      bucket: "myapp-#{env}-data",
      server_side_encryption_configuration: {
        rule: [{
          apply_server_side_encryption_by_default: {
            sse_algorithm: algorithm,
            kms_master_key_id: algorithm.include?("kms") ? "alias/#{env}-key" : nil
          }.compact,
          bucket_key_enabled: algorithm.include?("kms")
        }]
      }
    })
  end
end
```

## Error Handling

### Validation Errors
```ruby
# Missing encryption rule
aws_s3_bucket_encryption(:invalid, {
  bucket: "my-bucket",
  server_side_encryption_configuration: {
    rule: []  # Empty rules array - raises error
  }
})

# Missing KMS key for KMS algorithm
aws_s3_bucket_encryption(:missing_key, {
  bucket: "my-bucket", 
  server_side_encryption_configuration: {
    rule: [{
      apply_server_side_encryption_by_default: {
        sse_algorithm: "aws:kms"
        # Missing kms_master_key_id - raises error
      }
    }]
  }
})

# KMS key with AES256
aws_s3_bucket_encryption(:invalid_combo, {
  bucket: "my-bucket",
  server_side_encryption_configuration: {
    rule: [{
      apply_server_side_encryption_by_default: {
        sse_algorithm: "AES256",
        kms_master_key_id: "some-key"  # Invalid for AES256 - raises error
      }
    }]
  }
})
```

## Performance Considerations

### Algorithm Performance
- **AES256**: Fastest, no KMS overhead
- **KMS**: Slight latency for key operations
- **KMS DSSE**: Additional encryption layer overhead

### Cost Optimization
- **Bucket Keys**: Reduce KMS costs by up to 99%
- **Algorithm Choice**: AES256 vs KMS cost trade-offs
- **Request Patterns**: High-volume buckets benefit most from bucket keys

### Monitoring Integration
```ruby
output :encryption_monitoring do
  value {
    bucket: encryption_ref.outputs[:bucket],
    algorithm: encryption_ref.computed[:primary_encryption_algorithm],
    kms_keys: encryption_ref.computed[:kms_key_ids],
    bucket_key_enabled: encryption_ref.computed[:bucket_key_enabled],
    estimated_kms_cost_reduction: encryption_ref.computed[:bucket_key_enabled] ? "up to 99%" : "none"
  }
  description "Encryption configuration and cost optimization status"
end
```

## Testing Considerations

### Validation Testing
- Test missing encryption rules
- Test invalid algorithm values
- Test KMS key requirements
- Test AES256 with KMS key (should fail)
- Test empty rule arrays

### Integration Testing
- Test with actual KMS keys
- Test bucket key functionality
- Test object inheritance of encryption
- Test policy enforcement integration

### Security Testing
- Verify encryption is applied to objects
- Test key rotation scenarios
- Verify dual-layer encryption (DSSE)
- Test cross-account key access