# AWS Key Pair Resource Implementation

## Overview

The `aws_key_pair` resource provides type-safe management of AWS EC2 Key Pairs, which are used for SSH access to EC2 instances. This implementation follows Pangea's resource abstraction patterns, providing comprehensive validation, computed properties, and full Terraform compatibility.

## Architecture

### Type System

**KeyPairAttributes (Dry::Struct)**
- `key_name` (String, optional) - Explicit key pair name
- `key_name_prefix` (String, optional) - Prefix for auto-generated unique name  
- `public_key` (String, required) - SSH public key material
- `tags` (AwsTags, default: {}) - Resource tags

### Validation Logic

**Mutual Exclusivity Validation**
- Enforces that exactly one of `key_name` or `key_name_prefix` is specified
- Prevents AWS API errors by catching configuration conflicts at compile time

**Key Name Format Validation**
- Validates AWS key pair naming requirements (1-255 characters)
- Allows alphanumeric characters, spaces, dashes, and underscores only
- Applies to both `key_name` and `key_name_prefix` values

**SSH Public Key Validation**
- Validates SSH public key format: `<key-type> <key-data> [comment]`
- Supports key types: ssh-rsa, ssh-dss, ecdsa-sha2-nistp*, ssh-ed25519
- Validates base64 encoding of key data portion
- Enforces minimum key data length for security

### Computed Properties

**Key Identification**
- `uses_prefix?` - Returns true if using key_name_prefix
- `uses_explicit_name?` - Returns true if using explicit key_name  
- `key_identifier` - Returns the effective identifier (name or prefix)

**Key Type Detection**
- `key_type` - Detects key algorithm from public key format (:rsa, :ecdsa, :ed25519, :dsa, :unknown)
- `rsa_key?`, `ecdsa_key?`, `ed25519_key?` - Boolean checks for specific key types
- `estimated_key_size` - Estimates RSA key size based on public key length

## Implementation Details

### Resource Function Signature

```ruby
def aws_key_pair(name, attributes = {})
```

**Parameters:**
- `name` (Symbol) - Terraform resource name
- `attributes` (Hash) - Key pair configuration

**Returns:** ResourceReference with outputs and computed properties

### Terraform Resource Mapping

The function generates standard Terraform `aws_key_pair` resources:

```hcl
resource "aws_key_pair" "example" {
  key_name   = "my-key"          # OR key_name_prefix
  public_key = "ssh-ed25519 ..." 
  tags = {
    Name = "Example Key"
  }
}
```

### AWS Provider Compatibility

**Supported AWS Key Pair Features:**
- Explicit key naming with `key_name`
- Auto-generated unique naming with `key_name_prefix`
- All supported SSH key types (RSA, DSA, ECDSA, Ed25519)
- Resource tagging
- Complete AWS provider output compatibility

**AWS Limitations Handled:**
- Key name uniqueness (enforced via validation)
- Key format requirements (validated before submission)
- Maximum key name length (255 characters)
- Allowed characters in key names

## Security Considerations

### Key Type Recommendations

**Ed25519 (Recommended)**
- Modern elliptic curve cryptography
- Smaller key size with equivalent security to RSA-2048
- Better performance than RSA
- Resistant to timing attacks

**RSA (Legacy Support)**
- Minimum 2048-bit keys recommended
- 4096-bit keys for high-security environments
- Older standard, still widely supported

**ECDSA (Alternative)**
- Elliptic curve variant with good security
- Multiple curve sizes supported (P-256, P-384, P-521)
- Good balance of security and performance

### Validation Security

**Public Key Validation Benefits:**
- Prevents malformed keys from being uploaded to AWS
- Early detection of copy/paste errors
- Ensures key compatibility with SSH clients
- Reduces runtime failures and debugging time

**Key Name Validation Benefits:**
- Prevents AWS API rejections due to invalid names
- Ensures consistent naming across environments
- Avoids character encoding issues

## Usage Patterns

### Development vs Production

**Development Environment**
```ruby
dev_key = aws_key_pair(:dev_key, {
  key_name_prefix: "dev-",  # Auto-generated unique names
  public_key: development_public_key,
  tags: { Environment: "development" }
})
```

**Production Environment**
```ruby
prod_key = aws_key_pair(:prod_key, {
  key_name: "production-admin-key",  # Explicit, predictable name
  public_key: production_public_key,
  tags: { 
    Environment: "production",
    SecurityLevel: "high"
  }
})
```

### Key Rotation Strategy

**Multi-Key Deployment**
```ruby
# Current active key
current_key = aws_key_pair(:current, {
  key_name: "web-current",
  public_key: current_public_key,
  tags: { Status: "active" }
})

# Next rotation key (prepared in advance)
next_key = aws_key_pair(:next, {
  key_name: "web-next", 
  public_key: next_public_key,
  tags: { Status: "prepared" }
})

# Emergency backup key
emergency_key = aws_key_pair(:emergency, {
  key_name: "web-emergency",
  public_key: emergency_public_key,
  tags: { Status: "emergency-only" }
})
```

## Integration Patterns

### EC2 Instance Integration

```ruby
# Key pair creation
web_key = aws_key_pair(:web_key, {
  key_name: "web-servers",
  public_key: web_team_public_key
})

# Instance using the key pair
aws_instance(:web_server, {
  ami: "ami-12345678",
  instance_type: "t3.micro",
  key_name: web_key.key_name,  # Reference output
  tags: { Name: "Web Server" }
})
```

### Auto Scaling Group Integration

```ruby
# Key for ASG instances
asg_key = aws_key_pair(:asg_key, {
  key_name_prefix: "asg-",
  public_key: operations_public_key
})

# Launch template with key
aws_launch_template(:web_template, {
  name_prefix: "web-",
  image_id: "ami-12345678", 
  instance_type: "t3.micro",
  key_name: asg_key.key_name  # Reference output
})
```

## Testing Considerations

### Unit Testing Key Attributes

```ruby
# Test key type detection
attrs = KeyPairAttributes.new({
  key_name: "test",
  public_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG..."
})

assert attrs.ed25519_key?
assert_equal :ed25519, attrs.key_type
```

### Integration Testing

```ruby
template :key_test do  
  test_key = aws_key_pair(:test_key, {
    key_name_prefix: "test-",
    public_key: test_public_key
  })

  # Verify reference outputs work
  aws_instance(:test_instance, {
    ami: "ami-12345678",
    instance_type: "t3.nano",
    key_name: test_key.key_name
  })
end
```

## Error Handling

### Validation Errors

**Configuration Conflicts**
```ruby
# Raises: "Cannot specify both 'key_name' and 'key_name_prefix'"
aws_key_pair(:error, {
  key_name: "explicit",
  key_name_prefix: "prefix",
  public_key: valid_key
})
```

**Missing Required Parameters**
```ruby  
# Raises: "Must specify either 'key_name' or 'key_name_prefix'"
aws_key_pair(:error, {
  public_key: valid_key
})
```

**Invalid Key Format**
```ruby
# Raises: "Invalid public key format. Must be a valid SSH public key"
aws_key_pair(:error, {
  key_name: "test",
  public_key: "invalid-key-data"
})
```

### Runtime Errors

**AWS API Errors Prevented**
- Key name conflicts (prevented by validation)
- Invalid key format (prevented by validation)  
- Unsupported key types (prevented by validation)

## Performance Characteristics

### Key Size Impact

**Ed25519 Keys**
- Small public key size (~68 characters base64)
- Fast validation and processing
- Minimal network overhead

**RSA Keys**  
- Larger public key size (varies by key length)
- 2048-bit: ~372 characters base64
- 4096-bit: ~736 characters base64

### Validation Performance

**Public Key Parsing**
- Regex-based format validation (fast)
- Base64 validation (fast)
- No cryptographic operations during validation

## Extensibility

### Adding New Key Types

To support new SSH key types, extend the validation:

```ruby
def self.valid_public_key_format?(public_key)
  # Add new key types to supported_types array
  supported_types = %w[ssh-rsa ssh-dss ecdsa-sha2-nistp256 ssh-new-type]
  # ... rest of validation
end
```

### Custom Computed Properties

Add application-specific computed properties:

```ruby
def compliance_level
  case key_type
  when :ed25519
    :high
  when :rsa
    estimated_key_size >= 2048 ? :medium : :low
  else
    :unknown
  end
end
```

## Future Enhancements

### Planned Features

1. **Key Strength Analysis**
   - Actual key size parsing (requires OpenSSL integration)
   - Security strength scoring
   - Compliance checking against security standards

2. **Key Lifecycle Management**  
   - Expiration date tracking
   - Automatic rotation scheduling
   - Usage analytics and recommendations

3. **Enhanced Integration**
   - Direct integration with AWS Systems Manager Parameter Store
   - Automated key backup and recovery
   - Cross-region key pair replication

### Compatibility Roadmap

- Support for new AWS key pair features as released
- Integration with AWS Certificate Manager for certificate-based authentication
- Support for hardware security modules (HSM) backed keys