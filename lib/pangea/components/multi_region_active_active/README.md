# Multi-Region Active-Active Component

## Overview

The `multi_region_active_active` component creates a sophisticated active-active infrastructure deployment across multiple AWS regions with automatic failover, data consistency management, and global traffic distribution. This component is designed for applications requiring high availability, low latency globally, and resilience to regional failures.

## Features

- **Active-Active Architecture**: All regions actively serve traffic with automatic failover
- **Global Database Support**: DynamoDB Global Tables or Aurora Global Database
- **Intelligent Traffic Routing**: Route 53 with latency, weighted, or failover policies
- **AWS Global Accelerator**: Optional anycast IP addresses for ultra-low latency
- **Data Consistency Management**: Configurable consistency models with conflict resolution
- **Cross-Region Networking**: Transit Gateway with automatic peering
- **Comprehensive Monitoring**: Cross-region dashboards and synthetic monitoring
- **Chaos Engineering**: Built-in fault injection experiments
- **Cost Optimization**: Regional service usage and intelligent resource placement

## Usage

```ruby
multi_region = multi_region_active_active(:global_app, {
  deployment_name: "global-application",
  domain_name: "app.example.com",
  
  regions: [
    {
      region: "us-east-1",
      vpc_cidr: "10.0.0.0/16",
      availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
      is_primary: true,
      write_weight: 100
    },
    {
      region: "eu-west-1",
      vpc_cidr: "10.1.0.0/16",
      availability_zones: ["eu-west-1a", "eu-west-1b", "eu-west-1c"],
      is_primary: false,
      write_weight: 80
    },
    {
      region: "ap-southeast-1",
      vpc_cidr: "10.2.0.0/16",
      availability_zones: ["ap-southeast-1a", "ap-southeast-1b"],
      is_primary: false,
      write_weight: 60
    }
  ],
  
  consistency: {
    consistency_model: "eventual",
    conflict_resolution: "timestamp",
    replication_lag_threshold_ms: 100
  },
  
  global_database: {
    engine: "aurora-postgresql",
    engine_version: "14.6",
    instance_class: "db.r6g.xlarge",
    storage_encrypted: true
  },
  
  application: {
    name: "global-app",
    port: 443,
    protocol: "HTTPS",
    container_image: "myapp:latest",
    task_cpu: 1024,
    task_memory: 2048,
    desired_count: 3
  },
  
  traffic_routing: {
    routing_policy: "latency",
    health_check_enabled: true,
    sticky_sessions: true
  },
  
  monitoring: {
    enabled: true,
    cross_region_dashboard: true,
    synthetic_monitoring: true,
    anomaly_detection: true
  },
  
  enable_global_accelerator: true,
  enable_circuit_breaker: true,
  enable_chaos_engineering: true
})
```

## Configuration Options

### Core Configuration

- `deployment_name` (required): Name for the multi-region deployment
- `domain_name` (required): Domain name for global traffic routing
- `regions` (required): Array of region configurations (minimum 2)

### Region Configuration

Each region in the `regions` array supports:

- `region`: AWS region identifier
- `vpc_cidr`: CIDR block for the VPC (must not overlap)
- `availability_zones`: List of AZs to use (2-6)
- `vpc_ref`: Optional reference to existing VPC
- `is_primary`: Whether this is a primary region
- `database_priority`: Priority for database operations (default: 100)
- `write_weight`: Weight for write distribution (default: 100)

### Consistency Configuration

- `consistency_model`: "eventual", "strong", or "bounded" (default: "eventual")
- `conflict_resolution`: "timestamp", "region_priority", or "custom" (default: "timestamp")
- `replication_lag_threshold_ms`: Maximum acceptable lag (default: 100)
- `stale_read_acceptable`: Allow stale reads (default: false)
- `write_quorum_size`: Number of regions for write quorum (default: 2)
- `read_quorum_size`: Number of regions for read quorum (default: 1)

### Global Database Configuration

- `engine`: "aurora-mysql", "aurora-postgresql", or "dynamodb"
- `engine_version`: Database engine version
- `instance_class`: RDS instance class (not used for DynamoDB)
- `backup_retention_days`: Backup retention period (1-35)
- `enable_global_write_forwarding`: Enable write forwarding
- `storage_encrypted`: Enable encryption at rest
- `kms_key_ref`: Reference to KMS key for encryption

### Application Configuration (Optional)

- `name`: Application name
- `port`: Application port (default: 443)
- `protocol`: "HTTP", "HTTPS", or "TCP" (default: "HTTPS")
- `health_check_path`: Health check endpoint (default: "/health")
- `container_image`: Docker image for the application
- `task_cpu`: Fargate task CPU units (256-16384)
- `task_memory`: Fargate task memory (512-32768)
- `desired_count`: Number of tasks per region

### Traffic Routing Configuration

- `routing_policy`: "latency", "weighted", "geolocation", or "failover"
- `health_check_enabled`: Enable Route 53 health checks
- `cross_region_latency_threshold_ms`: Latency threshold
- `sticky_sessions`: Enable session affinity
- `session_affinity_ttl`: Session TTL in seconds

### Monitoring Configuration

- `enabled`: Enable monitoring features
- `detailed_metrics`: Enable detailed CloudWatch metrics
- `cross_region_dashboard`: Create global dashboard
- `synthetic_monitoring`: Enable CloudWatch Synthetics
- `distributed_tracing`: Enable X-Ray tracing
- `log_aggregation`: Aggregate logs across regions
- `anomaly_detection`: Enable anomaly detection

### Advanced Features

- `enable_global_accelerator`: Use AWS Global Accelerator
- `enable_circuit_breaker`: Enable circuit breaker pattern
- `enable_bulkhead_pattern`: Enable bulkhead isolation
- `enable_chaos_engineering`: Create chaos experiments
- `data_residency_enabled`: Enforce data residency
- `enable_data_localization`: Prevent cross-region data movement

## Outputs

The component returns:

- `deployment_name`: Name of the deployment
- `domain_name`: Configured domain name
- `hosted_zone_id`: Route 53 hosted zone ID
- `regions`: List of configured regions
- `primary_regions`: List of primary regions
- `consistency_model`: Active consistency model
- `global_accelerator_dns`: Global Accelerator DNS name
- `global_accelerator_ips`: Anycast IP addresses
- `regional_endpoints`: Endpoints for each region
- `database_endpoints`: Database connection endpoints
- `features_enabled`: List of enabled features
- `estimated_monthly_cost`: Estimated AWS costs
- `health_status`: Current health status

## Architecture Patterns

### Write-Local Pattern

For eventual consistency with local writes:

```ruby
consistency: {
  consistency_model: "eventual",
  conflict_resolution: "timestamp",
  stale_read_acceptable: true
}
```

### Strong Consistency Pattern

For applications requiring strong consistency:

```ruby
consistency: {
  consistency_model: "strong",
  write_quorum_size: 2,
  read_quorum_size: 2,
  stale_read_acceptable: false
}
```

### Disaster Recovery Pattern

With primary/secondary regions:

```ruby
traffic_routing: {
  routing_policy: "failover",
  health_check_enabled: true
},
failover: {
  auto_failback: true,
  failover_timeout: 60
}
```

## Best Practices

1. **Region Selection**: Choose regions close to your users
2. **CIDR Planning**: Use non-overlapping CIDR blocks
3. **Database Selection**: DynamoDB for NoSQL, Aurora for SQL workloads
4. **Health Checks**: Configure appropriate thresholds
5. **Cost Optimization**: Use reserved capacity for predictable workloads
6. **Testing**: Regularly test failover scenarios
7. **Monitoring**: Set up alerts for replication lag
8. **Security**: Enable encryption for data in transit and at rest

## Cost Considerations

Major cost factors:

- **Global Accelerator**: ~$0.025/hour + data processing
- **Aurora Global Database**: Instance costs per region
- **DynamoDB Global Tables**: Replicated write units
- **Cross-Region Data Transfer**: ~$0.02/GB
- **Transit Gateway**: Per attachment hour charges
- **Monitoring**: CloudWatch logs, metrics, and synthetics

## Troubleshooting

Common issues and solutions:

1. **High Replication Lag**: Check network connectivity, increase instance size
2. **Failover Not Working**: Verify health check configuration
3. **Write Conflicts**: Review conflict resolution strategy
4. **Cost Overruns**: Analyze cross-region transfer patterns
5. **Performance Issues**: Check routing policy and endpoint health

## Compliance Notes

- Supports data residency requirements
- Configurable data localization
- Audit trails for all operations
- Encryption in transit and at rest
- Compliance region restrictions