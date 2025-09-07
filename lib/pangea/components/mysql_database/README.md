# MySQL Database Component

A production-ready RDS MySQL component with automated backups, monitoring, security features, and high availability options.

## Features

- **RDS MySQL**: Fully managed MySQL database service
- **High Availability**: Multi-AZ deployment support
- **Security**: Encryption at rest and in transit
- **Automated Backups**: Point-in-time recovery capabilities
- **Performance Monitoring**: Performance Insights and CloudWatch metrics
- **Parameter Groups**: Optimized database parameters
- **Read Replicas**: Horizontal read scaling
- **Compliance**: SOX, HIPAA, and GDPR ready configurations

## Usage

### Basic MySQL Database

```ruby
# Create VPC and subnets first
vpc = aws_vpc(:main, { cidr_block: "10.0.0.0/16" })
db_subnet_1 = aws_subnet(:db_1, { 
  vpc_id: vpc.id, 
  cidr_block: "10.0.10.0/24",
  availability_zone: "us-east-1a"
})
db_subnet_2 = aws_subnet(:db_2, { 
  vpc_id: vpc.id, 
  cidr_block: "10.0.11.0/24",
  availability_zone: "us-east-1b"
})

# Create security group
db_sg = aws_security_group(:db, {
  name: "mysql-db-sg",
  description: "Security group for MySQL database",
  vpc_id: vpc.id,
  ingress: [
    { from_port: 3306, to_port: 3306, protocol: "tcp", cidr_blocks: ["10.0.0.0/16"] }
  ]
})

# Create MySQL Database
mysql_db = mysql_database(:app_database, {
  vpc_ref: vpc,
  subnet_refs: [db_subnet_1, db_subnet_2],
  security_group_refs: [db_sg],
  
  # Database configuration
  engine_version: "8.0.35",
  db_instance_class: "db.t3.small",
  allocated_storage: 100,
  max_allocated_storage: 1000,
  storage_type: "gp3",
  
  # Database identification
  db_name: "appdb",
  username: "admin",
  manage_master_user_password: true,
  
  # Security
  storage_encrypted: true,
  publicly_accessible: false,
  
  # Backups
  backup: {
    backup_retention_period: 7,
    backup_window: "03:00-04:00",
    skip_final_snapshot: false
  },
  
  tags: {
    Environment: "production",
    Application: "web-app"
  }
})
```

### High Availability Production Database

```ruby
production_db = mysql_database(:production_db, {
  vpc_ref: vpc,
  subnet_refs: [db_subnet_1, db_subnet_2, db_subnet_3],
  security_group_refs: [db_sg],
  
  # High-performance configuration
  engine_version: "8.0.35",
  db_instance_class: "db.r5.xlarge",
  allocated_storage: 500,
  max_allocated_storage: 2000,
  storage_type: "gp3",
  iops: 3000,
  storage_throughput: 500,
  
  # High availability
  multi_az: true,
  
  # Database configuration
  db_name: "production",
  username: "admin",
  manage_master_user_password: true,
  kms_key_id: "alias/rds-encryption-key",
  
  # Enhanced security
  storage_encrypted: true,
  publicly_accessible: false,
  deletion_protection: true,
  
  # Comprehensive backups
  backup: {
    backup_retention_period: 30,
    backup_window: "02:00-03:00",
    copy_tags_to_snapshot: true,
    skip_final_snapshot: false,
    final_snapshot_identifier: "production-final-snapshot"
  },
  
  # Maintenance configuration
  maintenance: {
    maintenance_window: "Sun:03:30-Sun:04:30",
    auto_minor_version_upgrade: true,
    allow_major_version_upgrade: false
  },
  
  # Performance monitoring
  monitoring: {
    monitoring_interval: 60,
    performance_insights_enabled: true,
    performance_insights_retention_period: 731,
    performance_insights_kms_key_id: "alias/performance-insights-key"
  },
  
  # CloudWatch logs
  enabled_cloudwatch_logs_exports: ["error", "general", "slow_query"],
  
  # Optimized parameters
  parameter_config: {
    create_parameter_group: true,
    parameter_group_family: "mysql8.0",
    parameters: {
      "innodb_buffer_pool_size" => "{DBInstanceClassMemory*3/4}",
      "max_connections" => "2000",
      "innodb_log_file_size" => "536870912",
      "slow_query_log" => "1",
      "long_query_time" => "1",
      "log_queries_not_using_indexes" => "1",
      "innodb_flush_log_at_trx_commit" => "1",
      "sync_binlog" => "1"
    }
  },
  
  # Read replicas for scaling
  create_read_replica: true,
  read_replica_count: 2,
  read_replica_instance_class: "db.r5.large",
  
  tags: {
    Environment: "production",
    Backup: "required",
    Monitoring: "enhanced"
  }
})
```

### Development Database with Cost Optimization

```ruby
dev_db = mysql_database(:dev_database, {
  vpc_ref: vpc,
  subnet_refs: [db_subnet_1, db_subnet_2],
  security_group_refs: [db_sg],
  
  # Cost-optimized configuration
  engine_version: "8.0.35",
  db_instance_class: "db.t3.micro",
  allocated_storage: 20,
  storage_type: "gp2",
  
  # Development settings
  db_name: "devdb",
  username: "devuser",
  manage_master_user_password: true,
  
  # Minimal security for development
  storage_encrypted: true,
  publicly_accessible: false,
  deletion_protection: false,
  
  # Minimal backup for development
  backup: {
    backup_retention_period: 1,
    skip_final_snapshot: true
  },
  
  # Basic monitoring
  monitoring: {
    monitoring_interval: 0,  # Disable enhanced monitoring
    performance_insights_enabled: false
  },
  
  # Maintenance during off-hours
  maintenance: {
    maintenance_window: "Sun:02:00-Sun:03:00",
    auto_minor_version_upgrade: true
  },
  
  tags: {
    Environment: "development",
    CostOptimized: "true"
  }
})
```

### Database with Point-in-Time Recovery

```ruby
# Restore from point in time
restored_db = mysql_database(:restored_db, {
  vpc_ref: vpc,
  subnet_refs: [db_subnet_1, db_subnet_2],
  security_group_refs: [db_sg],
  
  # Restore configuration
  restore_to_point_in_time: {
    source_db_instance_identifier: "production-db",
    restore_time: "2024-01-15T10:30:00Z"
  },
  
  # New instance configuration
  db_instance_class: "db.r5.large",
  
  # Enable backups immediately
  backup: {
    backup_retention_period: 7,
    backup_window: "04:00-05:00"
  }
})
```

## Component Outputs

The component returns a `ComponentReference` with the following outputs:

```ruby
db.outputs[:db_instance_identifier]      # Database instance identifier
db.outputs[:db_instance_arn]             # Database instance ARN
db.outputs[:db_instance_endpoint]        # Database connection endpoint
db.outputs[:db_instance_port]            # Database port (usually 3306)
db.outputs[:db_subnet_group_name]        # DB subnet group name
db.outputs[:parameter_group_name]        # Parameter group name
db.outputs[:read_replica_identifiers]    # Read replica identifiers
db.outputs[:security_features]           # Array of security features
db.outputs[:backup_retention_days]       # Backup retention period
db.outputs[:multi_az_enabled]           # Multi-AZ deployment status
db.outputs[:storage_encrypted]          # Encryption status
db.outputs[:estimated_monthly_cost]     # Estimated monthly cost
```

## Security Features

- **Encryption at Rest**: AES-256 encryption with AWS KMS
- **Encryption in Transit**: SSL/TLS connections
- **Network Isolation**: VPC and security group protection
- **IAM Database Authentication**: Optional IAM-based access
- **Parameter Group Security**: Secure database parameters
- **Automated Passwords**: AWS Secrets Manager integration
- **Deletion Protection**: Prevent accidental database deletion

## Backup and Recovery

### Automated Backups
- **Point-in-Time Recovery**: Restore to any second within retention period
- **Continuous Backups**: Transaction log backups every 5 minutes
- **Cross-Region Backup**: Optional cross-region backup copying

### Manual Snapshots
- **On-Demand Snapshots**: Create manual snapshots anytime
- **Encrypted Snapshots**: Snapshots inherit encryption settings
- **Snapshot Sharing**: Share snapshots across accounts

## Performance Monitoring

### Performance Insights
- **Query Analysis**: Identify top SQL statements and wait events
- **Historical Performance**: Up to 2 years of performance history
- **Resource Utilization**: CPU, memory, and I/O metrics

### CloudWatch Metrics
- **Database Metrics**: Connections, CPU, memory, storage
- **Custom Alarms**: Automated alerting on threshold breaches
- **Log Analysis**: Error, general, and slow query log analysis

## Parameter Groups

The component creates optimized parameter groups with:

- **Buffer Pool Sizing**: Optimized InnoDB buffer pool
- **Connection Limits**: Appropriate max_connections setting
- **Logging Configuration**: Error and slow query logging
- **Performance Tuning**: Optimized for typical web applications

## High Availability Options

### Multi-AZ Deployment
- **Automatic Failover**: Sub-minute failover to standby
- **Synchronous Replication**: Zero data loss failover
- **Maintenance**: Maintenance performed on standby first

### Read Replicas
- **Read Scaling**: Distribute read traffic across replicas
- **Cross-Region Replicas**: Disaster recovery and global access
- **Automatic Failover**: Promote replica to master if needed

## Best Practices

1. **Security**: Always enable encryption and use VPC security groups
2. **Backups**: Set appropriate backup retention periods
3. **Multi-AZ**: Use Multi-AZ for production workloads
4. **Monitoring**: Enable Performance Insights and CloudWatch logs
5. **Parameter Groups**: Use optimized parameter groups
6. **Instance Sizing**: Right-size instances based on workload
7. **Storage**: Use GP3 storage with appropriate IOPS provisioning

## Integration with Other Components

The MySQL Database component works seamlessly with:

- **Auto Scaling Groups**: Dynamic application scaling
- **Application Load Balancers**: Web application architecture
- **Lambda Functions**: Serverless application backends
- **ECS/EKS**: Containerized application data persistence
- **Secrets Manager**: Secure credential management

## Compliance and Governance

- **SOX Compliance**: Automated backups and audit logging
- **HIPAA Ready**: Encryption and access controls
- **GDPR Support**: Data encryption and retention policies
- **PCI DSS**: Network isolation and encryption
- **AWS Config**: Configuration compliance monitoring