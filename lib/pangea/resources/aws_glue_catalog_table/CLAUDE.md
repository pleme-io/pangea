# AWS Glue Catalog Table - Architecture Notes

## Resource Purpose

AWS Glue Catalog Table provides schema registry and metadata management for data lake architectures, enabling schema evolution, query optimization, and data governance across analytics engines like Athena, Spark, EMR, and Redshift Spectrum.

## Key Architectural Patterns

### Schema Registry Pattern
- **Centralized Schema Management**: Single source of truth for data structure definitions
- **Multi-Engine Compatibility**: Same schema accessible from Spark, Athena, Presto, Hive
- **Schema Evolution**: Support for backward/forward compatible schema changes
- **Type System Integration**: Rich type system supporting complex nested structures

### Data Lake Organization Pattern
- **Layered Table Structure**: Separate tables for raw, processed, and analytics-ready data
- **Partition Strategy**: Time-based and dimensional partitioning for query optimization
- **Format Optimization**: Different storage formats optimized for specific access patterns
- **Lifecycle Management**: Automated table lifecycle through retention policies

### Multi-Tenant Analytics Pattern
- **Tenant Isolation**: Separate table namespaces per tenant with controlled access
- **Shared Analytics**: Common analytical views across tenant data
- **Cost Attribution**: Per-tenant cost tracking through table-level tagging
- **Security Boundaries**: Fine-grained access control at table and column level

## Architecture Integration Points

### Data Pipeline Integration
```ruby
# Pipeline with schema evolution support
raw_table = aws_glue_catalog_table(:raw_events, {
  name: "raw_event_stream",
  database_name: "ingestion",
  table_type: "EXTERNAL_TABLE",
  storage_descriptor: {
    location: "s3://pipeline-raw/events/",
    **GlueCatalogTableAttributes.input_output_format_for_type("json"),
    serde_info: GlueCatalogTableAttributes.serde_info_for_format("json"),
    columns: [
      { name: "event_payload", type: "string" },
      { name: "schema_version", type: "string" },
      { name: "ingested_at", type: "timestamp" }
    ]
  },
  partition_keys: [
    { name: "date", type: "string" },
    { name: "hour", type: "string" }
  ]
})

processed_table = aws_glue_catalog_table(:processed_events, {
  name: "structured_events",
  database_name: "processed",
  table_type: "EXTERNAL_TABLE", 
  storage_descriptor: {
    location: "s3://pipeline-processed/events/",
    **GlueCatalogTableAttributes.input_output_format_for_type("parquet"),
    serde_info: GlueCatalogTableAttributes.serde_info_for_format("parquet"),
    columns: [
      { name: "user_id", type: "string" },
      { name: "event_type", type: "string" },
      { name: "properties", type: "map<string,string>" },
      { name: "timestamp", type: "timestamp" },
      { name: "processed_at", type: "timestamp" }
    ]
  },
  partition_keys: [{ name: "date", type: "string" }]
})

# ETL job references these table schemas
etl_job = aws_glue_job(:schema_aware_etl, {
  name: "raw_to_processed_etl",
  script_location: "s3://scripts/transform.py",
  default_arguments: {
    "--source_table" => raw_table.outputs[:name],
    "--target_table" => processed_table.outputs[:name],
    "--source_database" => raw_table.resource_attributes[:database_name],
    "--target_database" => processed_table.resource_attributes[:database_name]
  }
})
```

### Analytics Engine Integration
```ruby
# Analytics-optimized tables for different query patterns
fact_table = aws_glue_catalog_table(:sales_facts, {
  name: "sales_fact",
  database_name: "analytics",
  description: "Sales transaction facts",
  table_type: "EXTERNAL_TABLE",
  storage_descriptor: {
    location: "s3://analytics-warehouse/sales_fact/",
    **GlueCatalogTableAttributes.input_output_format_for_type("parquet"),
    serde_info: GlueCatalogTableAttributes.serde_info_for_format("parquet"),
    columns: [
      { name: "transaction_id", type: "string" },
      { name: "customer_key", type: "bigint" },
      { name: "product_key", type: "bigint" },
      { name: "time_key", type: "bigint" },
      { name: "amount", type: "decimal(18,2)" },
      { name: "quantity", type: "int" }
    ],
    sort_columns: [
      { column: "time_key", sort_order: 1 },
      { column: "customer_key", sort_order: 1 }
    ]
  },
  partition_keys: [
    { name: "year", type: "string" },
    { name: "quarter", type: "string" }
  ],
  parameters: {
    "optimization.target" => "analytics",
    "compression.codec" => "snappy",
    "projection.enabled" => "true",
    "projection.year.type" => "integer",
    "projection.year.range" => "2020,2030"
  }
})

# Customer dimension with SCD Type 2 support
dim_table = aws_glue_catalog_table(:customer_dim, {
  name: "customer_dimension", 
  database_name: "analytics",
  table_type: "EXTERNAL_TABLE",
  storage_descriptor: {
    location: "s3://analytics-warehouse/customer_dim/",
    **GlueCatalogTableAttributes.input_output_format_for_type("parquet"),
    serde_info: GlueCatalogTableAttributes.serde_info_for_format("parquet"),
    columns: [
      { name: "customer_key", type: "bigint" },
      { name: "customer_id", type: "string" },
      { name: "name", type: "string" },
      { name: "email", type: "string" },
      { name: "segment", type: "string" },
      { name: "effective_date", type: "date" },
      { name: "expiry_date", type: "date" },
      { name: "is_current", type: "boolean" }
    ]
  }
})

# Materialized view for complex analytics
analytics_view = aws_glue_catalog_table(:customer_metrics, {
  name: "customer_monthly_metrics",
  database_name: "analytics",
  table_type: "VIRTUAL_VIEW",
  view_original_text: %{
    SELECT 
      c.customer_id,
      c.segment,
      DATE_TRUNC('month', f.transaction_date) as month,
      SUM(f.amount) as total_revenue,
      COUNT(*) as transaction_count,
      AVG(f.amount) as avg_transaction_value
    FROM sales_fact f
    JOIN customer_dimension c ON f.customer_key = c.customer_key
    WHERE c.is_current = true
    GROUP BY c.customer_id, c.segment, DATE_TRUNC('month', f.transaction_date)
  },
  parameters: {
    "view_type" => "materialized",
    "refresh_schedule" => "daily",
    "dependencies" => "sales_fact,customer_dimension"
  }
})
```

## Performance Optimization Patterns

### Partition Strategy Design
```ruby
# Time-based partitioning for time-series data
time_series_table = aws_glue_catalog_table(:iot_sensors, {
  name: "iot_sensor_data",
  database_name: "telemetry",
  storage_descriptor: {
    location: "s3://iot-data/sensors/",
    columns: [
      { name: "device_id", type: "string" },
      { name: "sensor_type", type: "string" }, 
      { name: "value", type: "double" },
      { name: "timestamp", type: "timestamp" }
    ]
  },
  partition_keys: [
    { name: "year", type: "string" },
    { name: "month", type: "string" },
    { name: "day", type: "string" },
    { name: "hour", type: "string" }
  ],
  parameters: {
    "projection.enabled" => "true",
    "projection.year.type" => "integer", 
    "projection.year.range" => "2020,2030",
    "projection.month.type" => "integer",
    "projection.month.range" => "1,12", 
    "projection.day.type" => "integer",
    "projection.day.range" => "1,31",
    "projection.hour.type" => "integer",
    "projection.hour.range" => "0,23"
  }
})

# Multi-dimensional partitioning for business data
business_table = aws_glue_catalog_table(:orders, {
  name: "order_transactions",
  database_name: "business",
  storage_descriptor: {
    location: "s3://business-data/orders/",
    columns: [
      { name: "order_id", type: "string" },
      { name: "customer_id", type: "string" },
      { name: "amount", type: "decimal(12,2)" },
      { name: "status", type: "string" }
    ]
  },
  partition_keys: [
    { name: "region", type: "string", comment: "Geographic region" },
    { name: "order_date", type: "string", comment: "Date in YYYY-MM-DD format" }
  ]
})
```

### Format Optimization
```ruby
# High-frequency write table (streaming ingestion)
streaming_table = aws_glue_catalog_table(:stream_events, {
  name: "real_time_events",
  database_name: "streaming",
  storage_descriptor: {
    location: "s3://streaming-data/events/",
    **GlueCatalogTableAttributes.input_output_format_for_type("json"),
    serde_info: GlueCatalogTableAttributes.serde_info_for_format("json"),
    columns: [
      { name: "event_id", type: "string" },
      { name: "payload", type: "string" },
      { name: "timestamp", type: "timestamp" }
    ]
  },
  parameters: {
    "write_pattern" => "high_frequency",
    "compaction_schedule" => "hourly"
  }
})

# Analytics-optimized table (batch processing)
analytics_table = aws_glue_catalog_table(:analytics_events, {
  name: "analytics_events", 
  database_name: "analytics",
  storage_descriptor: {
    location: "s3://analytics-data/events/",
    **GlueCatalogTableAttributes.input_output_format_for_type("parquet"),
    serde_info: GlueCatalogTableAttributes.serde_info_for_format("parquet"),
    compressed: true,
    columns: [
      { name: "event_id", type: "string" },
      { name: "user_id", type: "string" },
      { name: "event_type", type: "string" },
      { name: "properties", type: "map<string,string>" },
      { name: "timestamp", type: "timestamp" }
    ],
    sort_columns: [
      { column: "timestamp", sort_order: 1 },
      { column: "user_id", sort_order: 1 }
    ]
  },
  parameters: {
    "parquet.compression" => "SNAPPY",
    "write.target-file-size-bytes" => "134217728" # 128MB
  }
})
```

## Schema Evolution Patterns

### Backward Compatible Changes
```ruby
# Version 1 schema
v1_table = aws_glue_catalog_table(:user_events_v1, {
  name: "user_events_v1",
  database_name: "events",
  storage_descriptor: {
    columns: [
      { name: "user_id", type: "string" },
      { name: "event_type", type: "string" },
      { name: "timestamp", type: "timestamp" }
    ]
  },
  parameters: {
    "schema_version" => "1.0",
    "compatibility_mode" => "backward"
  }
})

# Version 2 schema (backward compatible - adds optional fields)
v2_table = aws_glue_catalog_table(:user_events_v2, {
  name: "user_events_v2",
  database_name: "events",
  storage_descriptor: {
    columns: [
      { name: "user_id", type: "string" },
      { name: "event_type", type: "string" },
      { name: "timestamp", type: "timestamp" },
      # New optional fields
      { name: "session_id", type: "string", comment: "Added in v2" },
      { name: "properties", type: "map<string,string>", comment: "Added in v2" }
    ]
  },
  parameters: {
    "schema_version" => "2.0",
    "compatibility_mode" => "backward",
    "previous_version" => "1.0"
  }
})
```

### Complex Data Type Evolution
```ruby
# Evolving nested structures
evolved_table = aws_glue_catalog_table(:complex_events, {
  name: "complex_event_data",
  database_name: "events",
  storage_descriptor: {
    columns: [
      { name: "event_id", type: "string" },
      { name: "user_profile", type: "struct<id:string,email:string,preferences:map<string,string>>" },
      { name: "interaction_data", type: "array<struct<type:string,target:string,timestamp:timestamp,metadata:map<string,string>>>" },
      { name: "context", type: "struct<session_id:string,device:struct<type:string,os:string,browser:string>,location:struct<country:string,region:string,city:string>>" }
    ]
  },
  parameters: {
    "schema_registry" => "enabled",
    "type_evolution" => "additive_only"
  }
})
```

## Governance and Security Integration

### Data Classification
```ruby
sensitive_table = aws_glue_catalog_table(:customer_pii, {
  name: "customer_personal_data",
  database_name: "sensitive",
  description: "Customer PII data with classification",
  storage_descriptor: {
    columns: [
      { name: "customer_id", type: "string", comment: "Non-sensitive identifier" },
      { name: "ssn", type: "string", comment: "PII-SSN" },
      { name: "email", type: "string", comment: "PII-EMAIL" },
      { name: "phone", type: "string", comment: "PII-PHONE" },
      { name: "address", type: "struct<street:string,city:string,state:string,zip:string>", comment: "PII-ADDRESS" }
    ]
  },
  parameters: {
    "classification" => "pii",
    "encryption_required" => "true",
    "retention_policy" => "7_years",
    "access_control" => "restricted"
  }
})

# Anonymized view for analytics
anonymized_view = aws_glue_catalog_table(:customer_anonymous, {
  name: "customer_analytics_view",
  database_name: "analytics",
  table_type: "VIRTUAL_VIEW",
  view_original_text: %{
    SELECT 
      customer_id,
      HASH(email) as email_hash,
      SUBSTR(phone, 1, 3) as area_code,
      address.city,
      address.state,
      address.zip
    FROM customer_personal_data
  },
  parameters: {
    "privacy_level" => "anonymized",
    "source_classification" => "pii"
  }
})
```

This table resource provides the schema foundation that enables sophisticated data lake architectures with proper governance, performance optimization, and multi-engine analytics capabilities.