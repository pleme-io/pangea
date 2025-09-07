# Secure S3 Bucket Component

A production-ready S3 bucket component with encryption, versioning, lifecycle management, and comprehensive security features for enterprise compliance.

## Features

- **Server-Side Encryption**: AES-256 or KMS encryption by default
- **Versioning**: Object versioning with lifecycle management
- **Public Access Block**: Comprehensive public access prevention
- **Lifecycle Management**: Automated storage class transitions
- **Access Logging**: Request logging for audit trails
- **Cross-Region Replication**: Multi-region data replication
- **Object Lock**: WORM compliance and legal hold capabilities
- **Cost Optimization**: Intelligent tiering and storage transitions

## Usage

### Basic Secure Bucket

```ruby
# Create a basic secure S3 bucket
secure_bucket = secure_s3_bucket(:app_storage, {
  bucket_name: "my-secure-app-bucket",
  
  # Basic security
  encryption: {
    sse_algorithm: "AES256",
    enforce_ssl: true
  },
  
  # Versioning enabled
  versioning: {
    status: "Enabled"
  },
  
  # Block all public access
  public_access_block: {
    block_public_acls: true,
    block_public_policy: true,
    ignore_public_acls: true,
    restrict_public_buckets: true
  },
  
  # Intelligent tiering for cost optimization
  lifecycle_rules: [{
    id: "cost-optimization",
    status: "Enabled",
    transitions: [{
      days: 0,
      storage_class: "INTELLIGENT_TIERING"
    }, {
      days: 90,
      storage_class: "GLACIER"
    }, {
      days: 365,
      storage_class: "DEEP_ARCHIVE"
    }]
  }],
  
  tags: {
    Environment: "production",
    DataClassification: "confidential"
  }
})
```

### Enterprise Compliance Bucket

```ruby
compliance_bucket = secure_s3_bucket(:compliance_data, {
  bucket_name: "enterprise-compliance-bucket",
  
  # KMS encryption for enhanced security
  encryption: {
    sse_algorithm: "aws:kms",
    kms_key_id: "alias/s3-compliance-key",
    bucket_key_enabled: true,
    enforce_ssl: true
  },
  
  # Enable versioning for compliance
  versioning: {
    status: "Enabled",
    mfa_delete: "Enabled"  # Require MFA for deletion
  },
  
  # Complete public access block
  public_access_block: {
    block_public_acls: true,
    block_public_policy: true,
    ignore_public_acls: true,
    restrict_public_buckets: true
  },
  
  # Object Lock for WORM compliance
  object_lock_enabled: true,
  object_lock_configuration: {
    rule: {
      default_retention: {
        mode: "GOVERNANCE",
        days: 2555  # 7 years
      }
    }
  },
  
  # Comprehensive lifecycle management
  lifecycle_rules: [{
    id: "compliance-lifecycle",
    status: "Enabled",
    transitions: [{
      days: 30,
      storage_class: "STANDARD_IA"
    }, {
      days: 90,
      storage_class: "GLACIER"
    }, {
      days: 2555,  # 7 years
      storage_class: "DEEP_ARCHIVE"
    }],
    noncurrent_version_transitions: [{
      noncurrent_days: 30,
      storage_class: "STANDARD_IA"
    }, {
      noncurrent_days: 365,
      storage_class: "GLACIER"
    }],
    abort_incomplete_multipart_upload: {
      days_after_initiation: 7
    }
  }],
  
  # Access logging for audit
  logging: {
    enabled: true,
    target_bucket: "compliance-access-logs-bucket",
    target_prefix: "access-logs/",
    target_object_key_format: "PartitionedPrefix"
  },
  
  # Cross-region replication for DR
  replication: {
    enabled: true,
    role_arn: "arn:aws:iam::123456789012:role/S3ReplicationRole",
    rules: [{
      id: "disaster-recovery",
      status: "Enabled",
      destination: {
        bucket: "arn:aws:s3:::compliance-dr-bucket",
        storage_class: "STANDARD_IA",
        encryption_configuration: {
          replica_kms_key_id: "alias/s3-dr-key"
        }
      }
    }]
  },
  
  # Enhanced monitoring
  metrics: {
    enabled: true,
    enable_request_metrics: true,
    enable_data_events_logging: true
  },
  
  # Notifications for compliance events
  notifications: {
    enabled: true,
    lambda_configurations: [{
      events: ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"],
      lambda_function_arn: "arn:aws:lambda:us-east-1:123456789012:function:ComplianceAudit"
    }]
  },
  
  tags: {
    Environment: "production",
    Compliance: "SOX-HIPAA-GDPR",
    DataRetention: "7years",
    BackupRequired: "true"
  }
})
```

### Data Lake Storage Bucket

```ruby
data_lake_bucket = secure_s3_bucket(:data_lake, {
  bucket_name: "analytics-data-lake",
  
  # Standard encryption
  encryption: {
    sse_algorithm: "AES256",
    enforce_ssl: true
  },
  
  # Versioning for data integrity
  versioning: {
    status: "Enabled"
  },
  
  # Analytics-optimized lifecycle
  lifecycle_rules: [{
    id: "analytics-lifecycle",
    status: "Enabled",
    filter: {
      prefix: "raw-data/"
    },
    transitions: [{
      days: 0,
      storage_class: "INTELLIGENT_TIERING"
    }, {
      days: 180,
      storage_class: "GLACIER_IR"  # Instant retrieval for analytics
    }]
  }, {
    id: "processed-data-lifecycle",
    status: "Enabled",
    filter: {
      prefix: "processed-data/"
    },
    transitions: [{
      days: 90,
      storage_class: "STANDARD_IA"
    }, {
      days: 365,
      storage_class: "GLACIER"
    }]
  }],
  
  # Analytics configuration
  analytics: {
    enabled: true,
    configurations: [{
      name: "EntireDataLake",
      storage_class_analysis: {
        data_export: {
          output_schema_version: "V_1",
          destination: {
            s3_bucket_destination: {
              bucket_arn: "arn:aws:s3:::analytics-reports",
              prefix: "storage-analysis/",
              format: "CSV"
            }
          }
        }
      }
    }]
  },
  
  # Inventory reporting
  inventory: {
    enabled: true,
    configurations: [{
      name: "WeeklyInventory",
      included_object_versions: "Current",
      schedule: {
        frequency: "Weekly"
      },
      destination: {
        s3_bucket_destination: {
          bucket: "arn:aws:s3:::data-lake-inventory",
          prefix: "inventory/",
          format: "Parquet"
        }
      }
    }]
  },
  
  # Transfer acceleration for global access
  acceleration: {
    enabled: true,
    status: "Enabled"
  },
  
  tags: {
    Environment: "production",
    Purpose: "analytics",
    DataLake: "primary"
  }
})
```

### Static Website Hosting Bucket

```ruby
website_bucket = secure_s3_bucket(:static_website, {
  bucket_name: "my-static-website.com",
  
  # Basic encryption
  encryption: {
    sse_algorithm: "AES256",
    enforce_ssl: false  # Allow HTTP for website hosting
  },
  
  # Public access for website
  public_access_block: {
    block_public_acls: false,
    block_public_policy: false,
    ignore_public_acls: false,
    restrict_public_buckets: false
  },
  
  # Website configuration
  website_configuration: {
    index_document: {
      suffix: "index.html"
    },
    error_document: {
      key: "error.html"
    },
    routing_rules: [{
      condition: {
        key_prefix_equals: "docs/"
      },
      redirect: {
        replace_key_prefix_with: "documentation/"
      }
    }]
  },
  
  # CORS for web applications
  cors: {
    enabled: true,
    cors_rules: [{
      allowed_headers: ["*"],
      allowed_methods: ["GET", "HEAD"],
      allowed_origins: ["https://my-static-website.com"],
      expose_headers: ["ETag"],
      max_age_seconds: 3000
    }]
  },
  
  # Lifecycle for old content
  lifecycle_rules: [{
    id: "cleanup-old-versions",
    status: "Enabled",
    noncurrent_version_expiration: {
      noncurrent_days: 30
    }
  }],
  
  tags: {
    Environment: "production",
    Purpose: "static-website"
  }
})
```

## Component Outputs

The component returns a `ComponentReference` with the following outputs:

```ruby
bucket.outputs[:bucket_name]                    # S3 bucket name
bucket.outputs[:bucket_arn]                     # S3 bucket ARN
bucket.outputs[:bucket_domain_name]             # Bucket domain name
bucket.outputs[:bucket_regional_domain_name]    # Regional domain name
bucket.outputs[:versioning_enabled]             # Versioning status
bucket.outputs[:encryption_enabled]             # Encryption status
bucket.outputs[:encryption_algorithm]           # Encryption algorithm
bucket.outputs[:public_access_blocked]          # Public access status
bucket.outputs[:object_lock_enabled]            # Object lock status
bucket.outputs[:security_features]              # Array of security features
bucket.outputs[:compliance_features]            # Compliance capabilities
bucket.outputs[:cost_optimization_features]     # Cost optimization features
bucket.outputs[:estimated_monthly_cost]         # Estimated monthly cost
```

## Security Features

### Encryption
- **Server-Side Encryption**: AES-256 or KMS encryption
- **Bucket Key**: Reduce KMS costs with bucket keys
- **SSL Enforcement**: Require HTTPS for all requests
- **In-Transit Encryption**: All data encrypted in transit

### Access Control
- **Public Access Block**: Comprehensive public access prevention
- **Bucket Policies**: Fine-grained access control
- **IAM Integration**: Role-based access management
- **VPC Endpoints**: Private access from VPC

### Compliance Features
- **Object Lock**: WORM compliance and legal hold
- **Versioning**: Immutable object history
- **Access Logging**: Comprehensive audit trails
- **Cross-Region Replication**: Data residency and backup

## Lifecycle Management

### Storage Classes
- **Standard**: Frequently accessed data
- **Standard-IA**: Infrequently accessed data
- **One Zone-IA**: Cost-optimized infrequent access
- **Intelligent Tiering**: Automated cost optimization
- **Glacier Instant Retrieval**: Archive with millisecond access
- **Glacier Flexible Retrieval**: Archive with minute-to-hour access
- **Deep Archive**: Long-term archive with 12-hour retrieval

### Lifecycle Policies
- **Automated Transitions**: Move objects between storage classes
- **Version Management**: Clean up old object versions
- **Incomplete Multipart**: Clean up failed uploads
- **Expiration**: Automatically delete objects after specified time

## Monitoring and Analytics

### CloudWatch Metrics
- **Storage Metrics**: Object count and bucket size
- **Request Metrics**: API request patterns and errors
- **Data Retrieval**: Archive retrieval metrics
- **Custom Alarms**: Automated alerting on thresholds

### S3 Analytics
- **Storage Class Analysis**: Optimize storage class transitions
- **CloudWatch Integration**: Detailed metrics and dashboards
- **Cost Analysis**: Storage cost optimization recommendations

### S3 Inventory
- **Object Listings**: Scheduled bucket inventories
- **Metadata Reporting**: Object metadata and storage classes
- **Compliance Reporting**: Encryption and compliance status

## Best Practices

1. **Security**: Always enable encryption and public access block
2. **Versioning**: Enable versioning for important data
3. **Lifecycle**: Use lifecycle policies for cost optimization
4. **Monitoring**: Enable CloudWatch metrics and alarms
5. **Backup**: Implement cross-region replication for critical data
6. **Access**: Use least-privilege IAM policies
7. **Naming**: Use consistent, meaningful bucket names

## Integration with Other Components

The S3 bucket component works seamlessly with:

- **CloudFront**: Global content delivery
- **Lambda**: Event-driven processing
- **Athena**: SQL queries on S3 data
- **Glue**: ETL data processing
- **EMR**: Big data analytics
- **Backup**: Automated backup solutions

## Compliance Standards

- **SOX**: Financial data retention and audit trails
- **HIPAA**: Healthcare data encryption and access controls
- **GDPR**: Data residency and right to be forgotten
- **PCI DSS**: Payment data security requirements
- **FISMA**: Federal information system security
- **ISO 27001**: Information security management

## Cost Optimization

- **Intelligent Tiering**: Automatic cost optimization
- **Lifecycle Transitions**: Move data to cheaper storage classes
- **Incomplete Multipart Cleanup**: Remove failed upload fragments
- **Version Management**: Clean up old object versions
- **Transfer Acceleration**: Reduce data transfer costs
- **Requester Pays**: Transfer costs to data consumers