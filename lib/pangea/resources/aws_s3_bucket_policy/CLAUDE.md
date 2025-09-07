# AWS S3 Bucket Policy Implementation

## Implementation Overview

The `aws_s3_bucket_policy` resource provides type-safe S3 bucket policy management with comprehensive JSON validation and security analysis capabilities.

## Architecture

```
S3BucketPolicyAttributes (dry-struct)
    ↓ validates
JSON Policy Document
    ↓ synthesizes  
aws_s3_bucket_policy (terraform)
    ↓ returns
ResourceReference with computed security properties
```

## Type Safety

### Attributes Structure
- **bucket**: Required string bucket name
- **policy**: Required JSON string with IAM policy validation

### JSON Validation
The implementation validates:
- Valid JSON syntax via `JSON.parse`
- Required IAM policy structure (Version, Statement)
- Statement array with Effect fields
- Policy document integrity

### Security Analysis
Computed properties analyze policy security implications:
- `allows_public_read?`: Detects public read permissions
- `allows_public_write?`: Detects public write permissions  
- `has_condition_restrictions?`: Identifies conditional access controls

## Validation Logic

```ruby
def self.new(attributes = {})
  # Parse and validate JSON structure
  policy_doc = JSON.parse(attrs.policy)
  
  # Validate IAM policy format
  unless policy_doc.key?('Version') && policy_doc.key?('Statement')
    raise Dry::Struct::Error, "Invalid IAM policy structure"
  end
  
  # Validate statements
  statements = policy_doc['Statement']
  unless statements.all? { |s| s.key?('Effect') }
    raise Dry::Struct::Error, "All statements must have Effect"
  end
end
```

## Security Helper Methods

### Public Access Detection
```ruby
def allows_public_read?
  policy_document['Statement'].any? do |stmt|
    stmt['Effect'] == 'Allow' && 
    public_principal?(stmt) &&
    read_action?(stmt)
  end
end
```

### Condition Analysis
```ruby
def has_condition_restrictions?
  policy_document['Statement'].any? { |stmt| stmt.key?('Condition') }
end
```

## Terraform Integration

### Resource Generation
The resource function generates a clean terraform block:
```ruby
resource(:aws_s3_bucket_policy, name) do
  bucket policy_attrs.bucket
  policy policy_attrs.policy
end
```

### Output Properties
Standard terraform outputs:
- `id`: Policy resource identifier
- `bucket`: Associated bucket name
- `policy`: Policy document

## Computed Properties

### Security Analysis
- **statement_count**: Policy complexity metric
- **allows_public_read**: Public read access detection
- **allows_public_write**: Public write access detection
- **has_condition_restrictions**: Conditional access controls

### Usage Pattern
```ruby
policy_ref = aws_s3_bucket_policy(:secure_policy, {...})

if policy_ref.computed[:allows_public_read]
  puts "Warning: Policy allows public read access"
end
```

## Best Practices Implementation

### JSON Generation Pattern
```ruby
# Generate policy JSON with Ruby structures
policy_json = JSON.generate({
  Version: "2012-10-17",
  Statement: [
    {
      Effect: "Allow",
      Principal: { AWS: "arn:aws:iam::123456789012:root" },
      Action: ["s3:GetObject"],
      Resource: ["arn:aws:s3:::bucket/*"]
    }
  ]
})

aws_s3_bucket_policy(:policy, {
  bucket: "my-bucket",
  policy: policy_json
})
```

### Security-First Design
The implementation prioritizes security through:
- **Explicit validation** of policy structure
- **Public access detection** for security awareness
- **Condition analysis** for access control verification
- **Statement counting** for complexity monitoring

## Integration Points

### Bucket Policy + Public Access Block
```ruby
# Block public access at bucket level
aws_s3_bucket_public_access_block(:bucket_pab, {
  bucket: "secure-bucket",
  block_public_policy: true
})

# Apply restrictive policy
aws_s3_bucket_policy(:secure_policy, {
  bucket: "secure-bucket",
  policy: deny_public_access_policy
})
```

### Multi-Resource Security
The policy resource integrates with:
- `aws_s3_bucket_public_access_block` for public access control
- `aws_s3_bucket_encryption` for data protection
- `aws_s3_bucket_versioning` for data integrity
- `aws_s3_object` for object-level policies

## Error Handling

### JSON Validation Errors
```ruby
begin
  JSON.parse(policy_string)
rescue JSON::ParserError => e
  raise Dry::Struct::Error, "policy must be valid JSON: #{e.message}"
end
```

### Structure Validation
- Validates required IAM policy fields
- Ensures statements array structure
- Checks Effect field presence

## Performance Considerations

- **JSON parsing** occurs once during validation
- **Security analysis** computed on demand
- **Policy caching** via computed properties
- **Minimal terraform resource** generation

## Common Implementation Patterns

### Public Website Policy
```ruby
public_website_policy = JSON.generate({
  Version: "2012-10-17",
  Statement: [{
    Sid: "PublicReadGetObject",
    Effect: "Allow", 
    Principal: "*",
    Action: ["s3:GetObject"],
    Resource: ["arn:aws:s3:::website-bucket/*"]
  }]
})
```

### HTTPS Enforcement Policy
```ruby
https_only_policy = JSON.generate({
  Version: "2012-10-17",
  Statement: [{
    Sid: "DenyInsecureConnections",
    Effect: "Deny",
    Principal: "*", 
    Action: "s3:*",
    Resource: ["arn:aws:s3:::secure-bucket/*"],
    Condition: {
      Bool: { "aws:SecureTransport": "false" }
    }
  }]
})
```

## Testing Considerations

### Validation Testing
- Test invalid JSON handling
- Test missing required fields
- Test malformed statement arrays
- Test security analysis accuracy

### Integration Testing
- Test with actual S3 buckets
- Test policy application
- Test computed property accuracy
- Test terraform resource generation