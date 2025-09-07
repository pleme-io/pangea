# AWS Redshift Cluster - Technical Documentation

## Architecture Overview

AWS Redshift is a columnar data warehouse optimized for analytical workloads. It uses massively parallel processing (MPP) architecture to distribute data and query load across multiple nodes.

### Key Concepts

1. **Columnar Storage**: Data stored by column for efficient compression and scanning
2. **MPP Architecture**: Queries distributed across all nodes for parallel execution
3. **Result Caching**: Automatic caching of query results for performance
4. **Concurrency Scaling**: Automatic addition of cluster capacity for burst workloads

## Implementation Details

### Type Safety with Dry::Struct

The `RedshiftClusterAttributes` class provides comprehensive validation:

```ruby
# Cluster identifier validation
- Must start with lowercase letter
- Only lowercase letters, numbers, hyphens
- Maximum 63 characters

# Node configuration validation
- Single-node must have exactly 1 node
- Multi-node must have at least 2 nodes
- Node type must be valid DC2 or RA3

# Security validation
- KMS key required when encryption enabled
- Final snapshot identifier required when not skipping
- Bucket name required when logging enabled
```

### Resource Outputs

The resource returns these Terraform outputs:
- `id` - Cluster resource ID
- `arn` - Cluster ARN
- `endpoint` - Full endpoint with port
- `address` - Cluster address without port
- `port` - Cluster port number
- `database_name` - Database name
- `cluster_identifier` - Cluster identifier
- `cluster_nodes` - List of cluster nodes
- `cluster_parameter_group_name` - Parameter group name
- `cluster_subnet_group_name` - Subnet group name
- `vpc_security_group_ids` - Security group IDs
- `preferred_maintenance_window` - Maintenance window
- `node_type` - Node instance type
- `number_of_nodes` - Number of nodes

### Computed Properties

1. **Cluster Type**
   - `multi_node?` - Multi-node cluster check
   - `uses_ra3_nodes?` - RA3 node type check
   - `uses_dc2_nodes?` - DC2 node type check

2. **Capacity Metrics**
   - `total_storage_capacity_gb` - Total storage (DC2 only)
   - `total_vcpus` - Total compute capacity
   - `total_memory_gb` - Total memory capacity

3. **Cost and Features**
   - `estimated_monthly_cost_usd` - Monthly cost estimate
   - `high_availability?` - HA features enabled
   - `audit_logging_enabled?` - Audit logging status
   - `cross_region_backup?` - Cross-region backup status
   - `jdbc_connection_string` - Connection string template

## Advanced Features

### Node Type Selection

```ruby
# DC2 - Dense Compute (local SSD storage)
# Best for: Smaller datasets, high performance
"dc2.large"    # Dev/test: 160GB storage, $182/month
"dc2.8xlarge"  # Production: 2.56TB storage, $3,504/month

# RA3 - Managed storage (separate compute/storage)
# Best for: Large datasets, independent scaling
"ra3.xlplus"   # Entry: Managed storage, $793/month
"ra3.4xlarge"  # Standard: Managed storage, $2,380/month
"ra3.16xlarge" # Large: Managed storage, $9,519/month
```

### Workload-Optimized Parameters

```ruby
# ETL workload configuration
RedshiftClusterAttributes.default_parameters_for_workload(:etl)
# Returns:
# - Concurrency scaling enabled
# - Statement timeout disabled
# - 70% memory for ETL queries
# - Activity logging enabled

# Analytics workload configuration
RedshiftClusterAttributes.default_parameters_for_workload(:analytics)
# Returns:
# - 3 concurrency scaling clusters max
# - 10-minute statement timeout
# - 50% memory for analytics queries
# - Custom search path

# Mixed workload configuration
RedshiftClusterAttributes.default_parameters_for_workload(:mixed)
# Returns:
# - Balanced settings
# - Auto-analyze enabled
# - Standard date formatting
```

## Best Practices

### 1. Security Configuration

```ruby
# Production security setup
aws_redshift_cluster(:secure_warehouse, {
  cluster_identifier: "secure-warehouse",
  # Encryption at rest
  encrypted: true,
  kms_key_id: kms_key_ref.arn,
  
  # Network isolation
  cluster_subnet_group_name: private_subnet_group_ref.name,
  vpc_security_group_ids: [restricted_sg_ref.id],
  enhanced_vpc_routing: true,
  publicly_accessible: false,
  
  # Audit logging
  logging: {
    enable: true,
    bucket_name: "audit-logs",
    s3_key_prefix: "redshift/"
  },
  
  # IAM roles for S3 access
  iam_roles: [redshift_s3_role_ref.arn]
})
```

### 2. High Availability Setup

```ruby
# HA configuration
aws_redshift_cluster(:ha_warehouse, {
  cluster_identifier: "ha-warehouse",
  node_type: "ra3.4xlarge",
  cluster_type: "multi-node",
  number_of_nodes: 3,
  
  # Automated backups
  automated_snapshot_retention_period: 35,
  preferred_maintenance_window: "sun:05:00-sun:06:00",
  
  # Cross-region disaster recovery
  snapshot_copy: {
    destination_region: "us-west-2",
    retention_period: 7
  },
  
  # Prevent accidental deletion
  skip_final_snapshot: false,
  final_snapshot_identifier: "ha-warehouse-final"
})
```

### 3. Performance Optimization

```ruby
# Performance-optimized cluster
aws_redshift_cluster(:fast_warehouse, {
  cluster_identifier: "performance-warehouse",
  node_type: "ra3.16xlarge",
  cluster_type: "multi-node",
  number_of_nodes: 4,
  
  # Concurrency scaling parameter group
  cluster_parameter_group_name: concurrency_pg_ref.name,
  
  # Enhanced routing for better network performance
  enhanced_vpc_routing: true,
  
  # Place in specific AZ for proximity to compute
  availability_zone: "us-east-1a"
})
```

## Common Patterns

### 1. Multi-Environment Setup

```ruby
environments = {
  dev: { nodes: 1, type: "dc2.large", retention: 0 },
  staging: { nodes: 2, type: "dc2.8xlarge", retention: 3 },
  prod: { nodes: 4, type: "ra3.4xlarge", retention: 35 }
}

environments.each do |env, config|
  aws_redshift_cluster(:"warehouse_#{env}", {
    cluster_identifier: "#{env}-warehouse",
    node_type: config[:type],
    cluster_type: config[:nodes] > 1 ? "multi-node" : "single-node",
    number_of_nodes: config[:nodes],
    automated_snapshot_retention_period: config[:retention],
    encrypted: env == :prod,
    publicly_accessible: env == :dev
  })
end
```

### 2. Data Lake Integration

```ruby
# Redshift Spectrum enabled cluster
spectrum_cluster = aws_redshift_cluster(:spectrum, {
  cluster_identifier: "spectrum-warehouse",
  node_type: "ra3.4xlarge",
  cluster_type: "multi-node",
  number_of_nodes: 2,
  iam_roles: [spectrum_role_ref.arn]
})

# External schema for S3 data
aws_redshift_external_schema(:data_lake, {
  cluster_identifier: spectrum_cluster.outputs[:cluster_identifier],
  schema_name: "data_lake",
  database_name: "analytics",
  iam_role_arn: spectrum_role_ref.arn,
  catalog_database: glue_database_ref.name
})
```

### 3. Cost Management

```ruby
# Pause/Resume scheduling
aws_redshift_scheduled_action(:pause_nights, {
  name: "pause-nights",
  schedule: "cron(0 20 ? * MON-FRI *)",
  target_action: {
    pause_cluster: {
      cluster_identifier: "dev-warehouse"
    }
  }
})

aws_redshift_scheduled_action(:resume_mornings, {
  name: "resume-mornings",
  schedule: "cron(0 8 ? * MON-FRI *)",
  target_action: {
    resume_cluster: {
      cluster_identifier: "dev-warehouse"
    }
  }
})
```

## Integration Examples

### With Kinesis Firehose

```ruby
# Cluster for streaming data
cluster_ref = aws_redshift_cluster(:streaming, {
  cluster_identifier: "streaming-warehouse",
  iam_roles: [firehose_role_ref.arn]
})

# Firehose delivery to Redshift
aws_kinesis_firehose_delivery_stream(:to_redshift, {
  name: "events-to-redshift",
  destination: "redshift",
  redshift_configuration: {
    cluster_jdbcurl: cluster_ref.computed_properties[:jdbc_connection_string],
    username: "firehose_user",
    password: secrets_ref.firehose_password,
    copy_command: {
      data_table_name: "events",
      copy_options: "FORMAT AS JSON 'auto'"
    }
  }
})
```

### With AWS Glue

```ruby
# Cluster with Glue catalog integration
cluster_ref = aws_redshift_cluster(:glue_integrated, {
  cluster_identifier: "glue-warehouse",
  iam_roles: [glue_role_ref.arn]
})

# Glue connection for ETL
aws_glue_connection(:redshift_conn, {
  name: "redshift-connection",
  connection_type: "JDBC",
  connection_properties: {
    JDBC_CONNECTION_URL: cluster_ref.computed_properties[:jdbc_connection_string],
    USERNAME: "etl_user",
    PASSWORD: secrets_ref.etl_password
  }
})
```

## Troubleshooting

### Common Issues

1. **Connection Failures**
   - Verify security group rules
   - Check VPC routing configuration
   - Ensure proper IAM permissions

2. **Performance Issues**
   - Review workload management settings
   - Check for missing statistics (ANALYZE)
   - Monitor disk space usage

3. **Cost Overruns**
   - Implement pause/resume schedules
   - Use reserved instances for production
   - Monitor concurrency scaling usage

## Cost Optimization

### Pricing Breakdown
```ruby
# On-Demand Hourly Rates (US East)
# DC2 Nodes
# dc2.large: $0.25/hour ($182/month)
# dc2.8xlarge: $4.80/hour ($3,504/month)

# RA3 Nodes
# ra3.xlplus: $1.086/hour ($793/month)
# ra3.4xlarge: $3.26/hour ($2,380/month)
# ra3.16xlarge: $13.04/hour ($9,519/month)

# RA3 Managed Storage: $0.024/GB/month
# Snapshot Storage: $0.023/GB/month
# Concurrency Scaling: Same as node pricing
```

### Cost Reduction Strategies

1. **Reserved Instances**: Up to 75% savings
2. **Pause/Resume**: Stop billing when not in use
3. **Right-sizing**: Choose appropriate node types
4. **Compression**: Reduce storage costs with encoding
5. **Distribution Keys**: Optimize query performance