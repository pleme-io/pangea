# AWS S3 Object Implementation

## Implementation Overview

The `aws_s3_object` resource provides comprehensive S3 object management with type-safe attributes, content handling, security features, and extensive metadata support.

## Architecture

```
S3ObjectAttributes (dry-struct)
    ↓ validates
Content Source & Configuration
    ↓ synthesizes  
aws_s3_object (terraform)
    ↓ returns
ResourceReference with content analysis
```

## Type Safety

### Attributes Structure
- **bucket**: Required string bucket name
- **key**: Required string object key/path
- **source** OR **content**: Mutually exclusive content sources
- **Content properties**: Type, encoding, caching, etc.
- **Security**: Encryption, ACLs, object lock
- **Metadata**: Custom key-value pairs and tags

### Content Source Validation
```ruby
def self.new(attributes = {})
  # Mutually exclusive content sources
  if attrs.source && attrs.content
    raise Dry::Struct::Error, "source and content are mutually exclusive"
  end

  # At least one content source required
  unless attrs.source || attrs.content
    raise Dry::Struct::Error, "either source or content must be specified"
  end

  # Validate source file exists
  if attrs.source && !File.exist?(attrs.source)
    raise Dry::Struct::Error, "source file '#{attrs.source}' does not exist"
  end
end
```

## Content Source Management

### File Upload Source
```ruby
attribute? :source, Resources::Types::String.optional

def has_source_file?
  !source.nil?
end

def source_file_extension
  return nil unless source
  File.extname(source).downcase
end
```

### Inline Content
```ruby
attribute? :content, Resources::Types::String.optional

def has_inline_content?
  !content.nil?
end

def content_source_type
  return 'file' if source
  return 'inline' if content
  'unknown'
end
```

### Size Estimation
```ruby
def estimated_size
  return content.bytesize if content
  return File.size(source) if source && File.exist?(source)
  nil
end
```

## Content Type Detection

### Automatic MIME Type Inference
```ruby
def inferred_content_type
  return content_type if content_type
  return nil unless source

  case source_file_extension
  when '.html', '.htm' then 'text/html'
  when '.css' then 'text/css'
  when '.js' then 'application/javascript'
  when '.json' then 'application/json'
  when '.xml' then 'application/xml'
  when '.pdf' then 'application/pdf'
  when '.jpg', '.jpeg' then 'image/jpeg'
  when '.png' then 'image/png'
  when '.gif' then 'image/gif'
  when '.svg' then 'image/svg+xml'
  when '.txt' then 'text/plain'
  when '.md' then 'text/markdown'
  when '.zip' then 'application/zip'
  else 'application/octet-stream'
  end
end
```

This automatic detection provides sensible defaults while allowing manual override.

## Storage Class Support

### Complete Storage Class Enum
```ruby
attribute? :storage_class, Resources::Types::String.enum(
  'STANDARD', 'REDUCED_REDUNDANCY', 'STANDARD_IA', 'ONEZONE_IA',
  'INTELLIGENT_TIERING', 'GLACIER', 'DEEP_ARCHIVE', 'GLACIER_IR'
).optional
```

### Storage Strategy Helper
```ruby
def storage_strategy_for_access_pattern(pattern)
  case pattern
  when :frequent then 'STANDARD'
  when :infrequent then 'STANDARD_IA'
  when :archive then 'GLACIER'
  when :deep_archive then 'DEEP_ARCHIVE'
  when :intelligent then 'INTELLIGENT_TIERING'
  else 'STANDARD'
  end
end
```

## Security Implementation

### Encryption Support
```ruby
attribute? :server_side_encryption, Resources::Types::String.enum('AES256', 'aws:kms').optional
attribute? :kms_key_id, Resources::Types::String.optional

def encrypted?
  !server_side_encryption.nil?
end

def kms_encrypted?
  server_side_encryption == 'aws:kms'
end
```

### Encryption Validation
```ruby
# Validate KMS encryption configuration
if attrs.server_side_encryption == 'aws:kms' && attrs.kms_key_id.nil?
  raise Dry::Struct::Error, "kms_key_id is required when using aws:kms encryption"
end
```

### Object Lock Support
```ruby
attribute? :object_lock_mode, Resources::Types::String.enum('GOVERNANCE', 'COMPLIANCE').optional
attribute? :object_lock_retain_until_date, Resources::Types::String.optional
attribute? :object_lock_legal_hold_status, Resources::Types::String.enum('ON', 'OFF').optional

def object_lock_enabled?
  !object_lock_mode.nil?
end

def legal_hold_enabled?
  object_lock_legal_hold_status == 'ON'
end
```

### Object Lock Validation
```ruby
# Validate object lock configuration consistency
if attrs.object_lock_mode && attrs.object_lock_retain_until_date.nil?
  raise Dry::Struct::Error, "object_lock_retain_until_date is required when object_lock_mode is specified"
end
```

## ACL Support

### Object ACL Enum
```ruby
attribute? :acl, Resources::Types::String.enum(
  'private', 'public-read', 'public-read-write', 'authenticated-read',
  'aws-exec-read', 'bucket-owner-read', 'bucket-owner-full-control'
).optional
```

This provides comprehensive ACL control while maintaining type safety.

## Metadata and Tagging

### Custom Metadata
```ruby
attribute :metadata, Resources::Types::Hash.map(
  Resources::Types::String, 
  Resources::Types::String
).default({})

def has_metadata?
  metadata.any?
end
```

### AWS Tags
```ruby
attribute :tags, Resources::Types::AwsTags.default({})

def has_tags?
  tags.any?
end
```

### Metadata Integration in Terraform
```ruby
# Set metadata
if object_attrs.metadata.any?
  object_attrs.metadata.each do |key, value|
    metadata do
      public_send(key, value)
    end
  end
end

# Set tags
if object_attrs.tags.any?
  tags do
    object_attrs.tags.each do |key, value|
      public_send(key, value)
    end
  end
end
```

## Web Content Optimization

### Caching Headers
```ruby
attribute? :cache_control, Resources::Types::String.optional
attribute? :expires, Resources::Types::String.optional
attribute? :content_encoding, Resources::Types::String.optional
attribute? :content_disposition, Resources::Types::String.optional
```

### Website Redirects
```ruby
attribute? :website_redirect, Resources::Types::String.optional

def is_website_redirect?
  !website_redirect.nil?
end
```

## Terraform Integration

### Resource Generation
```ruby
resource(:aws_s3_object, name) do
  # Core attributes
  bucket object_attrs.bucket
  key object_attrs.key
  
  # Content source
  source object_attrs.source if object_attrs.source
  content object_attrs.content if object_attrs.content
  
  # Content properties with automatic detection
  content_type object_attrs.inferred_content_type if object_attrs.inferred_content_type
  content_encoding object_attrs.content_encoding if object_attrs.content_encoding
  # ... other content properties
  
  # Security configuration
  server_side_encryption object_attrs.server_side_encryption if object_attrs.server_side_encryption
  kms_key_id object_attrs.kms_key_id if object_attrs.kms_key_id
  
  # Object lock
  object_lock_mode object_attrs.object_lock_mode if object_attrs.object_lock_mode
  # ... other object lock properties
  
  # Metadata and tags (complex nested structures)
  # ... metadata and tag blocks
end
```

### Output Properties
Standard terraform outputs:
- `id`: Object resource ID
- `bucket`, `key`: Object location
- `etag`: Content hash
- `version_id`: Version (if versioning enabled)
- Content and security properties

## Computed Properties

### Content Analysis
- **has_source_file**: Upload source type
- **has_inline_content**: Content source type
- **content_source_type**: "file" or "inline"
- **source_file_extension**: File extension for source files
- **inferred_content_type**: Auto-detected MIME type
- **estimated_size**: Size in bytes

### Security Analysis
- **encrypted**: Whether encryption is applied
- **kms_encrypted**: Whether KMS encryption is used
- **object_lock_enabled**: Whether object lock is configured
- **legal_hold_enabled**: Whether legal hold is active

### Configuration Analysis
- **has_metadata**: Whether custom metadata is set
- **has_tags**: Whether tags are applied
- **is_website_redirect**: Whether object is a redirect

## Implementation Patterns

### Static Website Assets
```ruby
css_asset = aws_s3_object(:main_css, {
  bucket: "website-assets",
  key: "css/main.css",
  source: "/build/main.min.css",
  content_type: "text/css",
  content_encoding: "gzip",
  cache_control: "public, max-age=31536000, immutable",
  metadata: {
    build_version: "v1.2.3",
    build_timestamp: "2024-01-01T12:00:00Z"
  }
})
```

### Secure Document Upload
```ruby
secure_document = aws_s3_object(:confidential_report, {
  bucket: "secure-documents",
  key: "reports/q4-2024.pdf",
  source: "/reports/q4-2024.pdf",
  server_side_encryption: "aws:kms",
  kms_key_id: "alias/document-encryption-key",
  object_lock_mode: "COMPLIANCE",
  object_lock_retain_until_date: "2030-01-01T00:00:00Z",
  acl: "bucket-owner-full-control",
  metadata: {
    document_type: "financial_report",
    confidentiality: "restricted",
    retention_period: "7_years"
  },
  tags: {
    Classification: "confidential",
    Department: "finance",
    Quarter: "Q4-2024"
  }
})
```

### API Response Caching
```ruby
api_response = aws_s3_object(:api_cache, {
  bucket: "api-cache-bucket",
  key: "v1/users/123/profile.json",
  content: JSON.generate({user_id: 123, name: "John Doe"}),
  content_type: "application/json; charset=utf-8",
  cache_control: "public, max-age=300",
  metadata: {
    api_version: "v1",
    cache_generated: Time.now.iso8601,
    ttl_seconds: "300"
  }
})
```

### Data Pipeline Artifacts
```ruby
processed_data = aws_s3_object(:etl_output, {
  bucket: "data-pipeline-results",
  key: "processed/2024/01/01/customer-insights.parquet",
  source: "/tmp/customer-insights.parquet",
  storage_class: "STANDARD_IA",
  server_side_encryption: "aws:kms",
  kms_key_id: "alias/data-pipeline-key",
  metadata: {
    processing_job: "customer-insights-etl",
    input_records: "50000",
    output_records: "48500",
    processing_time: "45_minutes",
    data_quality_score: "0.97"
  },
  tags: {
    Pipeline: "customer_insights",
    Environment: "production",
    DataDate: "2024-01-01"
  }
})
```

## Integration with Bucket Resources

### Inheritance and Overrides
```ruby
template :bucket_with_objects do
  # Create encrypted bucket
  bucket = aws_s3_bucket(:app_bucket, {...})
  
  aws_s3_bucket_encryption(:bucket_encryption, {
    bucket: bucket.bucket,
    server_side_encryption_configuration: {
      rule: [{
        apply_server_side_encryption_by_default: {
          sse_algorithm: "aws:kms",
          kms_master_key_id: "alias/app-key"
        }
      }]
    }
  })

  # Object inherits bucket encryption
  standard_object = aws_s3_object(:app_config, {
    bucket: bucket.bucket,
    key: "config/app.json",
    source: "/config/app.json"
    # Inherits KMS encryption from bucket
  })

  # Object overrides bucket encryption
  public_object = aws_s3_object(:public_readme, {
    bucket: bucket.bucket,
    key: "public/README.txt",
    content: "Public readme content",
    server_side_encryption: "AES256"  # Override bucket KMS with AES256
  })
end
```

## Error Handling

### Content Source Errors
```ruby
# File not found
aws_s3_object(:missing_file, {
  bucket: "my-bucket",
  key: "missing.txt",
  source: "/nonexistent/file.txt"  # Raises validation error
})

# Conflicting content sources
aws_s3_object(:conflicting_content, {
  bucket: "my-bucket", 
  key: "conflict.txt",
  source: "/file.txt",
  content: "inline content"  # Raises validation error
})

# Missing content source
aws_s3_object(:no_content, {
  bucket: "my-bucket",
  key: "empty.txt"
  # No source or content - raises validation error
})
```

### Security Configuration Errors
```ruby
# KMS without key ID
aws_s3_object(:missing_kms_key, {
  bucket: "my-bucket",
  key: "encrypted.txt",
  content: "secret",
  server_side_encryption: "aws:kms"
  # Missing kms_key_id - raises validation error
})

# Object lock without retention date
aws_s3_object(:incomplete_lock, {
  bucket: "my-bucket",
  key: "locked.txt", 
  content: "locked content",
  object_lock_mode: "COMPLIANCE"
  # Missing object_lock_retain_until_date - raises validation error
})
```

## Performance Considerations

### Large File Handling
- **Multipart Upload**: Automatically handled by Terraform for large files
- **Transfer Acceleration**: Configure at bucket level
- **Storage Class**: Choose appropriate class for access patterns

### Content Type Detection
- **Automatic Detection**: Occurs once during validation
- **Manual Override**: Use explicit content_type for performance-critical scenarios
- **Caching**: Computed properties cached in resource reference

### Metadata Optimization
- **Selective Metadata**: Only add metadata that provides value
- **Tag Strategy**: Use tags for billing and management, metadata for application data
- **Size Limits**: AWS limits metadata size to 2KB

## Testing Considerations

### Content Source Testing
- Test file upload scenarios
- Test inline content scenarios
- Test content type detection accuracy
- Test file existence validation

### Security Testing
- Test encryption configuration validation
- Test object lock functionality
- Test ACL application
- Test KMS key requirements

### Integration Testing
- Test bucket encryption inheritance
- Test lifecycle rule interactions
- Test versioning behavior
- Test cross-account access scenarios

### Performance Testing
- Test large file uploads
- Test metadata and tag handling
- Test storage class transitions
- Test concurrent object operations

The implementation provides comprehensive S3 object management while maintaining type safety, security best practices, and extensive configuration options for real-world use cases.