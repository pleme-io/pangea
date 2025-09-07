# AWS S3 Access Point Resource

## Overview

Amazon S3 access points simplify managing data access at scale for shared datasets. Each access point has distinct permissions and network controls that Amazon S3 applies for any request made through that access point.

## Features

- **Type-Safe Attributes**: Comprehensive validation using dry-struct
- **VPC Support**: Create VPC-restricted access points
- **Public Access Control**: Fine-grained public access block configuration
- **Cross-Account Access**: Support for cross-account bucket access
- **Computed Properties**: Helper methods for access point characteristics

## Basic Usage

### Internet Access Point

```ruby
template :s3_access_point_example do
  # Basic internet-accessible access point
  access_point = aws_s3_access_point(:my_access_point, {
    account_id: "123456789012",
    bucket: "my-shared-bucket",
    name: "my-access-point"
  })
  
  # Access point ARN and domain available as outputs
  output :access_point_arn do
    value access_point.arn
  end
end
```

### VPC Access Point

```ruby
template :vpc_access_point_example do
  # VPC-restricted access point
  vpc_access_point = aws_s3_access_point(:vpc_access_point, {
    account_id: "123456789012", 
    bucket: "internal-data-bucket",
    name: "internal-access-point",
    vpc_configuration: {
      vpc_id: "vpc-12345678"
    },
    public_access_block_configuration: {
      block_public_acls: true,
      block_public_policy: true,
      ignore_public_acls: true,
      restrict_public_buckets: true
    }
  })
end
```

### Cross-Account Access Point

```ruby
template :cross_account_access_point do
  # Access point for bucket in different account
  cross_account_ap = aws_s3_access_point(:cross_account_ap, {
    account_id: "123456789012",          # Your account
    bucket_account_id: "210987654321",   # Bucket owner account
    bucket: "shared-data-bucket",
    name: "shared-access-point"
  })
end
```

## Advanced Configuration

### Public Access Controls

```ruby
template :secured_access_point do
  secure_ap = aws_s3_access_point(:secure_access_point, {
    account_id: "123456789012",
    bucket: "sensitive-data-bucket", 
    name: "secure-ap",
    public_access_block_configuration: {
      block_public_acls: true,
      block_public_policy: true,
      ignore_public_acls: true,
      restrict_public_buckets: true
    }
  })
  
  # Computed properties available
  output :is_secured do
    value secure_ap.computed[:has_public_access_block]
  end
end
```

### Access Point with Policy

```ruby
template :policy_access_point do
  policy_ap = aws_s3_access_point(:policy_ap, {
    account_id: "123456789012",
    bucket: "policy-controlled-bucket",
    name: "policy-ap",
    policy: JSON.generate({
      Version: "2012-10-17",
      Statement: [
        {
          Sid: "AllowGetFromSpecificPrefix",
          Effect: "Allow",
          Principal: {
            AWS: "arn:aws:iam::123456789012:user/DataAnalyst"
          },
          Action: [
            "s3:GetObject"
          ],
          Resource: "arn:aws:s3:*:123456789012:accesspoint/policy-ap/object/reports/*"
        }
      ]
    })
  })
end
```

## Output Values

The `aws_s3_access_point` function returns a `ResourceReference` with these outputs:

| Output | Description |
|--------|-------------|
| `id` | Access point ID |
| `arn` | Access point ARN |
| `alias` | Access point alias |
| `domain_name` | Access point domain name |
| `has_public_access_policy` | Whether access point has public access policy |
| `network_origin` | Network origin (Internet or VPC) |
| `endpoints` | Access point endpoints by region |

## Computed Properties

Additional computed properties for infrastructure logic:

| Property | Description |
|----------|-------------|
| `vpc_access_point` | True if access point is VPC-restricted |
| `internet_access_point` | True if access point allows internet access |
| `has_public_access_block` | True if public access block is configured |
| `cross_account_access` | True if accessing bucket in different account |

## Validation Rules

### Required Attributes
- `account_id`: Must be valid 12-digit AWS account ID
- `bucket`: S3 bucket name to create access point for
- `name`: Access point name (3-63 chars, lowercase, alphanumeric and hyphens only)

### Optional Attributes
- `bucket_account_id`: Account ID of bucket owner (if different from access point owner)
- `network_origin`: 'Internet' (default) or 'VPC'
- `policy`: IAM policy document as JSON string
- `vpc_configuration`: VPC settings for VPC access points
- `public_access_block_configuration`: Public access controls

## Best Practices

1. **Use Descriptive Names**: Choose access point names that clearly indicate their purpose
2. **Apply Public Access Blocks**: Always configure public access blocks for sensitive data
3. **Least Privilege Policies**: Use IAM policies to restrict access to minimum required permissions
4. **VPC Restriction**: Use VPC access points for internal applications
5. **Monitor Access**: Use CloudTrail to monitor access point usage

## Integration Examples

### With S3 Bucket

```ruby
template :bucket_with_access_points do
  # Create bucket first
  data_bucket = aws_s3_bucket(:shared_data, {
    bucket: "company-shared-data-bucket",
    versioning: { enabled: true }
  })
  
  # Create access point for analytics team
  analytics_ap = aws_s3_access_point(:analytics_ap, {
    account_id: "123456789012",
    bucket: data_bucket.bucket,
    name: "analytics-access-point",
    policy: analytics_access_policy
  })
  
  # Create VPC access point for internal services
  internal_ap = aws_s3_access_point(:internal_ap, {
    account_id: "123456789012", 
    bucket: data_bucket.bucket,
    name: "internal-services-ap",
    vpc_configuration: {
      vpc_id: "vpc-12345678"
    }
  })
end
```

## Error Handling

The resource function validates all parameters and will raise descriptive errors for:

- Invalid AWS account ID format
- Access point name validation failures
- Missing required VPC configuration for VPC access points
- Invalid network origin values
- Malformed policy documents