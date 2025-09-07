# AWS Athena Database - Technical Documentation

## Architecture Overview

AWS Athena Database is a metadata construct in the AWS Glue Data Catalog that defines a logical namespace for tables that Athena can query. It doesn't store data itself but points to data stored in S3.

### Key Concepts

1. **Serverless Analytics**: No infrastructure to manage, pay only for queries run
2. **Schema-on-Read**: Define structure when querying, not when storing
3. **S3 Integration**: Direct queries against data in S3 without loading
4. **Glue Catalog**: Centralized metadata repository shared across AWS services

## Implementation Details

### Type Safety with Dry::Struct

The `AthenaDatabaseAttributes` class provides comprehensive validation:

```ruby
# Database name validation
- Must start with letter or underscore
- Only alphanumeric and underscore characters
- Maximum 255 characters

# Bucket name validation
- Valid S3 bucket naming convention
- Lowercase letters, numbers, hyphens, dots

# Encryption validation
- KMS key required when using KMS encryption options
- Supports SSE_S3, SSE_KMS, CSE_KMS
```

### Resource Outputs

The resource returns these Terraform outputs:
- `id` - Database ID (catalog_id:name)
- `name` - Database name

### Computed Properties

1. **encrypted?** - Boolean indicating encryption status
2. **encryption_type** - Specific encryption method used
3. **uses_kms?** - Whether KMS encryption is enabled
4. **location_uri** - Full S3 URI for database location
5. **estimated_monthly_storage_gb** - Storage estimate for planning

## Advanced Features

### Partition Projection

Partition projection eliminates the need to manually add partitions:

```ruby
# Date-based partitioning
projection_props = AthenaDatabaseAttributes.partition_projection_properties(:date, {
  range: "2020-01-01,NOW",
  format: "yyyy-MM-dd",
  interval: "1",
  unit: "DAYS"
})

# Integer-based partitioning
projection_props = AthenaDatabaseAttributes.partition_projection_properties(:integer, {
  range: "1,1000000",
  digits: "6"
})

# Enum-based partitioning
projection_props = AthenaDatabaseAttributes.partition_projection_properties(:enum, {
  values: ["us-east-1", "us-west-2", "eu-west-1"]
})
```

### Database Properties

Common properties for optimization:

```ruby
{
  # Storage optimization
  "compression" => "snappy",
  "storage_format" => "parquet",
  
  # Query optimization
  "query_optimization" => "enabled",
  "result_compression" => "gzip",
  
  # Data organization
  "time_partitioning" => "daily",
  "partition_projection" => "enabled",
  
  # Classification
  "classification" => "data_lake",
  "table_type" => "EXTERNAL_TABLE"
}
```

## Best Practices

### 1. Database Organization

```ruby
# Separate databases by data lifecycle
aws_athena_database(:raw_data, { name: "raw_data_lake", bucket: "raw-bucket" })
aws_athena_database(:processed, { name: "processed_analytics", bucket: "processed-bucket" })
aws_athena_database(:aggregated, { name: "business_metrics", bucket: "metrics-bucket" })
```

### 2. Security Configuration

```ruby
# Always encrypt sensitive data
aws_athena_database(:sensitive, {
  name: "pii_data",
  bucket: "encrypted-bucket",
  encryption_configuration: {
    encryption_option: "SSE_KMS",
    kms_key: kms_key_ref.arn
  },
  expected_bucket_owner: "123456789012"
})
```

### 3. Performance Optimization

```ruby
# Use appropriate storage formats and compression
aws_athena_database(:optimized, {
  name: "analytics_optimized",
  bucket: "analytics-bucket",
  properties: {
    "storage_format" => "parquet",     # Columnar format
    "compression" => "snappy",         # Fast compression
    "projection.enabled" => "true",    # Automatic partitioning
    "skip.header.line.count" => "1"    # Skip CSV headers
  }
})
```

## Common Patterns

### 1. Multi-Region Data Lake

```ruby
["us-east-1", "us-west-2", "eu-west-1"].each do |region|
  aws_athena_database(:"data_lake_#{region.tr("-", "_")}", {
    name: "data_lake_#{region.tr("-", "_")}",
    bucket: "data-lake-#{region}",
    properties: {
      "region" => region,
      "replication" => "cross-region"
    }
  })
end
```

### 2. Time-Series Database

```ruby
aws_athena_database(:time_series, {
  name: "metrics_time_series",
  bucket: "metrics-bucket",
  properties: AthenaDatabaseAttributes.partition_projection_properties(:date, {
    range: "2020-01-01,NOW",
    format: "yyyy/MM/dd/HH",
    unit: "HOURS"
  }).merge({
    "time_zone" => "UTC",
    "retention_policy" => "13_months"
  })
})
```

### 3. Cost-Optimized Database

```ruby
aws_athena_database(:archived, {
  name: "archived_data",
  bucket: "glacier-bucket",
  properties: {
    "storage_class" => "GLACIER",
    "lifecycle_policy" => "archive_after_90_days",
    "query_frequency" => "rare"
  },
  force_destroy: false  # Protect archived data
})
```

## Integration Examples

### With Glue Crawlers

```ruby
db_ref = aws_athena_database(:crawled_data, {
  name: "auto_discovered",
  bucket: "data-discovery-bucket"
})

aws_glue_crawler(:data_crawler, {
  name: "discover_tables",
  database_name: db_ref.outputs[:name],
  s3_targets: [{
    path: "s3://data-discovery-bucket/raw/"
  }]
})
```

### With Kinesis Firehose

```ruby
db_ref = aws_athena_database(:streaming_data, {
  name: "kinesis_events",
  bucket: "streaming-bucket",
  properties: {
    "streaming.enabled" => "true",
    "format" => "json"
  }
})

aws_kinesis_firehose_delivery_stream(:event_stream, {
  name: "events",
  extended_s3_configuration: {
    bucket_arn: "arn:aws:s3:::streaming-bucket",
    prefix: "events/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/",
    data_format_conversion_configuration: {
      output_format_configuration: {
        serializer: {
          parquet_ser_de: {}
        }
      }
    }
  }
})
```

## Troubleshooting

### Common Issues

1. **Query Failures**
   - Check S3 permissions
   - Verify data format matches table schema
   - Ensure proper IAM roles for Athena

2. **Performance Issues**
   - Use columnar formats (Parquet, ORC)
   - Implement partitioning strategy
   - Compress data appropriately

3. **Cost Optimization**
   - Partition data to reduce scan volume
   - Use projection to avoid manual partition management
   - Compress data to reduce storage and scan costs

## Cost Considerations

1. **Storage**: S3 standard pricing for data storage
2. **Queries**: $5 per TB of data scanned
3. **Catalog**: AWS Glue Data Catalog pricing for metadata

### Cost Optimization Strategies

```ruby
# Minimize scan costs with partitioning
aws_athena_database(:partitioned, {
  name: "cost_optimized",
  bucket: "partitioned-bucket",
  properties: {
    "partition_by" => "date,region,service",
    "compression" => "gzip",
    "format" => "parquet"
  }
})
```