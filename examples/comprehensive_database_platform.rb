# Comprehensive Database Platform Example
# Demonstrates all 50 database service resources working together

template :database_platform_foundation do
  provider :aws do
    region "us-east-1"
  end

  # === SHARED INFRASTRUCTURE ===
  
  # Resource sharing setup
  database_share = aws_ram_resource_share(:db_platform, {
    name: "database-platform-shared-resources",
    allow_external_principals: false
  })
  
  # Enable organization-wide sharing
  aws_ram_sharing_with_organization(:enable, {
    enable: true
  })

  # === DOCUMENT DATABASE (DocumentDB) ===
  
  # Subnet group for DocumentDB
  docdb_subnet_group = aws_docdb_subnet_group(:main, {
    name: "docdb-subnet-group",
    description: "Subnet group for DocumentDB clusters",
    subnet_ids: ["subnet-12345", "subnet-67890", "subnet-abcde"]
  })
  
  # Parameter group with custom settings
  docdb_params = aws_docdb_cluster_parameter_group(:main, {
    name: "docdb-params-prod",
    family: "docdb4.0",
    description: "Production DocumentDB parameters",
    parameter: [
      {
        name: "audit_logs",
        value: "enabled",
        apply_method: "pending-reboot"
      },
      {
        name: "ttl_monitor", 
        value: "enabled",
        apply_method: "immediate"
      }
    ]
  })
  
  # Global cluster for multi-region setup
  docdb_global = aws_docdb_global_cluster(:global, {
    global_cluster_identifier: "platform-docdb-global",
    engine: "docdb",
    engine_version: "4.0.0",
    storage_encrypted: true,
    deletion_protection: true
  })
  
  # Primary cluster in us-east-1
  docdb_cluster = aws_docdb_cluster(:primary, {
    cluster_identifier: "platform-docdb-primary",
    global_cluster_identifier: docdb_global.id,
    engine: "docdb",
    engine_version: "4.0.0",
    master_username: "docdbadmin",
    master_password: "SecureDocDBPassword123!",
    backup_retention_period: 14,
    preferred_backup_window: "03:00-04:00",
    preferred_maintenance_window: "sun:04:00-sun:05:00",
    db_subnet_group_name: docdb_subnet_group.name,
    db_cluster_parameter_group_name: docdb_params.name,
    storage_encrypted: true,
    enabled_cloudwatch_logs_exports: ["audit", "profiler"],
    deletion_protection: true,
    tags: {
      Environment: "production",
      Service: "document-database",
      Platform: "database-platform"
    }
  })
  
  # Primary instance
  aws_docdb_cluster_instance(:primary_instance, {
    identifier: "platform-docdb-primary-1",
    cluster_identifier: docdb_cluster.cluster_identifier,
    instance_class: "db.r5.xlarge",
    availability_zone: "us-east-1a",
    enable_performance_insights: true,
    performance_insights_retention_period: 7
  })
  
  # Read replica
  aws_docdb_cluster_instance(:replica_instance, {
    identifier: "platform-docdb-replica-1",
    cluster_identifier: docdb_cluster.cluster_identifier,
    instance_class: "db.r5.large", 
    availability_zone: "us-east-1b",
    promotion_tier: 1
  })
  
  # Custom endpoint for read-only workloads
  aws_docdb_cluster_endpoint(:analytics, {
    cluster_endpoint_identifier: "analytics-endpoint",
    cluster_identifier: docdb_cluster.cluster_identifier,
    endpoint_type: "READER"
  })
  
  # Event subscription for monitoring
  aws_docdb_event_subscription(:main_events, {
    name: "docdb-production-events",
    sns_topic_arn: "arn:aws:sns:us-east-1:123456789012:database-alerts",
    source_type: "db-cluster",
    event_categories: ["backup", "failure", "failover", "maintenance"],
    enabled: true
  })
end

template :graph_database_services do
  provider :aws do
    region "us-east-1" 
  end

  # === GRAPH DATABASE (Neptune) ===
  
  # Neptune subnet group
  neptune_subnet_group = aws_neptune_subnet_group(:main, {
    name: "neptune-subnet-group",
    description: "Subnet group for Neptune clusters",
    subnet_ids: ["subnet-12345", "subnet-67890", "subnet-abcde"]
  })
  
  # Neptune cluster parameter group
  neptune_cluster_params = aws_neptune_cluster_parameter_group(:main, {
    name: "neptune-cluster-params-prod",
    family: "neptune1.2",
    description: "Production Neptune cluster parameters",
    parameter: [
      {
        name: "neptune_enable_audit_log",
        value: "1",
        apply_method: "pending-reboot"
      }
    ]
  })
  
  # Neptune instance parameter group  
  neptune_params = aws_neptune_parameter_group(:main, {
    name: "neptune-params-prod",
    family: "neptune1.2", 
    description: "Production Neptune instance parameters"
  })
  
  # Neptune cluster
  neptune_cluster = aws_neptune_cluster(:main, {
    cluster_identifier: "platform-neptune-main",
    engine: "neptune",
    backup_retention_period: 7,
    preferred_backup_window: "04:00-05:00",
    preferred_maintenance_window: "sun:05:00-sun:06:00",
    neptune_subnet_group_name: neptune_subnet_group.name,
    neptune_cluster_parameter_group_name: neptune_cluster_params.name,
    storage_encrypted: true,
    iam_database_authentication_enabled: true,
    enable_cloudwatch_logs_exports: ["audit"],
    tags: {
      Environment: "production",
      Service: "graph-database"
    }
  })
  
  # Primary Neptune instance
  aws_neptune_cluster_instance(:primary, {
    identifier: "platform-neptune-primary",
    cluster_identifier: neptune_cluster.cluster_identifier,
    instance_class: "db.r5.2xlarge",
    engine: "neptune",
    neptune_parameter_group_name: neptune_params.name
  })
  
  # Analytics replica
  aws_neptune_cluster_instance(:analytics, {
    identifier: "platform-neptune-analytics",
    cluster_identifier: neptune_cluster.cluster_identifier,
    instance_class: "db.r5.4xlarge",
    promotion_tier: 2
  })
  
  # Neptune event subscription
  aws_neptune_event_subscription(:events, {
    name: "neptune-production-events",
    sns_topic_arn: "arn:aws:sns:us-east-1:123456789012:database-alerts",
    source_type: "db-cluster",
    enabled: true
  })
end

template :time_series_analytics do
  provider :aws do
    region "us-east-1"
  end

  # === TIME SERIES DATABASE (Timestream) ===
  
  # Main metrics database
  metrics_db = aws_timestream_database(:metrics, {
    database_name: "platform-metrics",
    kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  })
  
  # Application performance table
  app_metrics_table = aws_timestream_table(:app_performance, {
    database_name: metrics_db.database_name,
    table_name: "application-performance",
    retention_properties: {
      memory_store_retention_period_in_hours: 24,
      magnetic_store_retention_period_in_days: 365
    },
    magnetic_store_write_properties: {
      enable_magnetic_store_writes: true,
      magnetic_store_rejected_data_location: {
        s3_configuration: {
          bucket_name: "timestream-rejected-data",
          object_key_prefix: "app-metrics/"
        }
      }
    }
  })
  
  # Infrastructure metrics table
  infra_metrics_table = aws_timestream_table(:infrastructure, {
    database_name: metrics_db.database_name,
    table_name: "infrastructure-metrics",
    retention_properties: {
      memory_store_retention_period_in_hours: 12,
      magnetic_store_retention_period_in_days: 90
    }
  })
  
  # Scheduled query for hourly aggregations
  aws_timestream_scheduled_query(:hourly_rollups, {
    name: "hourly-performance-aggregations",
    query_string: <<~SQL,
      SELECT 
        BIN(time, 1h) as hour,
        measure_name,
        AVG(measure_value::double) as avg_value,
        MAX(measure_value::double) as max_value,
        MIN(measure_value::double) as min_value,
        COUNT(*) as sample_count
      FROM "#{metrics_db.database_name}"."#{app_metrics_table.table_name}"
      WHERE time > ago(2h)
      GROUP BY BIN(time, 1h), measure_name
    SQL
    schedule_configuration: {
      schedule_expression: "rate(1 hour)"
    },
    notification_configuration: {
      sns_configuration: {
        topic_arn: "arn:aws:sns:us-east-1:123456789012:timestream-alerts"
      }
    },
    target_configuration: {
      timestream_configuration: {
        database_name: metrics_db.database_name,
        table_name: "hourly-aggregates"
      }
    },
    scheduled_query_execution_role_arn: "arn:aws:iam::123456789012:role/TimestreamQueryRole"
  })
  
  # Access policy for read-only analytics
  aws_timestream_access_policy(:analytics_read, {
    database_name: metrics_db.database_name,
    policy_document: JSON.generate({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Principal: {
            AWS: "arn:aws:iam::123456789012:role/AnalyticsRole"
          },
          Action: [
            "timestream:Select",
            "timestream:DescribeTable",
            "timestream:ListTables"
          ],
          Resource: "*"
        }
      ]
    })
  })
end

template :memory_cache_layer do
  provider :aws do
    region "us-east-1"
  end

  # === MEMORY DATABASE (MemoryDB for Redis) ===
  
  # Subnet group for MemoryDB
  memorydb_subnet_group = aws_memorydb_subnet_group(:main, {
    name: "memorydb-subnet-group",
    description: "Subnet group for MemoryDB clusters",
    subnet_ids: ["subnet-12345", "subnet-67890", "subnet-abcde"]
  })
  
  # Parameter group with Redis optimizations
  memorydb_params = aws_memorydb_parameter_group(:main, {
    name: "memorydb-params-prod",
    family: "memorydb_redis6",
    description: "Production MemoryDB parameters",
    parameter: [
      {
        name: "maxmemory-policy",
        value: "allkeys-lru"
      },
      {
        name: "timeout",
        value: "300"
      }
    ]
  })
  
  # User for application access
  cache_user = aws_memorydb_user(:app_user, {
    user_name: "app-cache-user",
    access_string: "on ~* &* +@all -dangerous",
    authentication_mode: {
      type: "password",
      passwords: ["AppCachePassword123!"]
    }
  })
  
  # ACL for user management
  cache_acl = aws_memorydb_acl(:main, {
    name: "app-cache-acl",
    user_names: [cache_user.user_name]
  })
  
  # Main cache cluster
  cache_cluster = aws_memorydb_cluster(:main, {
    name: "platform-cache-cluster",
    node_type: "db.r6g.xlarge",
    num_shards: 3,
    num_replicas_per_shard: 2,
    subnet_group_name: memorydb_subnet_group.name,
    parameter_group_name: memorydb_params.name,
    acl_name: cache_acl.name,
    maintenance_window: "sun:06:00-sun:07:00",
    port: 6379,
    snapshot_retention_limit: 5,
    snapshot_window: "05:00-06:00",
    engine_version: "6.2",
    tls_enabled: true,
    auto_minor_version_upgrade: true,
    data_tiering: false,
    description: "Main application cache cluster",
    tags: {
      Environment: "production",
      Service: "cache-layer"
    }
  })
  
  # Snapshot for backup
  aws_memorydb_snapshot(:backup, {
    cluster_name: cache_cluster.name,
    name: "platform-cache-snapshot-#{Time.now.strftime('%Y%m%d')}"
  })
end

template :license_compliance do
  provider :aws do
    region "us-east-1"
  end

  # === LICENSE MANAGER ===
  
  # Oracle database licenses
  oracle_licenses = aws_licensemanager_license_configuration(:oracle_db, {
    name: "Oracle Database Enterprise Edition",
    license_counting_type: "vCPU",
    description: "Oracle DB EE licenses for production workloads",
    license_count: 200,
    license_count_hard_limit: true,
    license_rules: [
      "ALLOW_OUTBOUND_MOBILITY",
      "ALLOW_HYPERVISOR_AFFINITY"
    ],
    tags: {
      Vendor: "Oracle",
      LicenseType: "Enterprise"
    }
  })
  
  # Microsoft SQL Server licenses
  sqlserver_licenses = aws_licensemanager_license_configuration(:sqlserver, {
    name: "Microsoft SQL Server Standard",
    license_counting_type: "vCPU", 
    description: "SQL Server Standard licenses",
    license_count: 100,
    license_count_hard_limit: false,
    tags: {
      Vendor: "Microsoft",
      LicenseType: "Standard"
    }
  })
  
  # Associate licenses with DocumentDB (as example)
  aws_licensemanager_association(:docdb_oracle, {
    license_configuration_arn: oracle_licenses.arn,
    resource_arn: "arn:aws:rds:us-east-1:123456789012:db:docdb-cluster"
  })
  
  # License grant for sharing with dev account
  oracle_grant = aws_licensemanager_grant(:dev_oracle, {
    name: "oracle-dev-grant",
    allowed_operations: ["CreateGrant", "CheckoutLicense"],
    license_arn: oracle_licenses.arn,
    principal: "123456789013", # Dev account
    home_region: "us-east-1"
  })
  
  # Automated compliance reporting
  aws_licensemanager_report_generator(:compliance, {
    license_manager_report_generator_name: "monthly-license-compliance",
    type: [
      "LicenseConfigurationSummaryReport",
      "LicenseConfigurationUsageReport"
    ],
    report_context: {
      license_configuration_arns: [
        oracle_licenses.arn,
        sqlserver_licenses.arn
      ]
    },
    report_frequency: "MONTH",
    s3_bucket_name: "license-compliance-reports",
    description: "Monthly license usage and compliance report",
    tags: {
      Purpose: "compliance",
      Frequency: "monthly"
    }
  })
end

template :resource_sharing do
  provider :aws do
    region "us-east-1"
  end

  # === RESOURCE ACCESS MANAGER (RAM) ===
  
  # Main resource share for database platform
  platform_share = aws_ram_resource_share(:database_platform, {
    name: "database-platform-resources",
    allow_external_principals: false,
    tags: {
      Purpose: "database-platform-sharing",
      Environment: "production"
    }
  })
  
  # Associate subnet groups with resource share
  aws_ram_resource_association(:docdb_subnets, {
    resource_arn: "arn:aws:docdb:us-east-1:123456789012:subnet-group:docdb-subnet-group",
    resource_share_arn: platform_share.arn
  })
  
  aws_ram_resource_association(:neptune_subnets, {
    resource_arn: "arn:aws:neptune:us-east-1:123456789012:subnet-group:neptune-subnet-group", 
    resource_share_arn: platform_share.arn
  })
  
  # Share with development account
  aws_ram_principal_association(:dev_account, {
    principal: "123456789013",
    resource_share_arn: platform_share.arn
  })
  
  # Share with staging account
  aws_ram_principal_association(:staging_account, {
    principal: "123456789014", 
    resource_share_arn: platform_share.arn
  })
  
  # Custom permission for database access
  db_permission = aws_ram_permission(:database_access, {
    name: "DatabaseSubnetGroupAccess",
    resource_type: "docdb:SubnetGroup",
    policy_template: JSON.generate({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Action: [
            "docdb:DescribeDBSubnetGroups",
            "neptune:DescribeDBSubnetGroups"
          ],
          Resource: "*"
        }
      ]
    })
  })
  
  # Associate permission with resource share
  aws_ram_permission_association(:db_permission, {
    permission_arn: db_permission.arn,
    resource_share_arn: platform_share.arn
  })
end

# === TEMPLATE OUTPUTS ===

template :platform_outputs do
  # Document Database outputs
  output :docdb_cluster_endpoint do
    value "${aws_docdb_cluster.primary.endpoint}"
    description "DocumentDB cluster primary endpoint"
  end
  
  output :docdb_reader_endpoint do
    value "${aws_docdb_cluster.primary.reader_endpoint}"
    description "DocumentDB cluster reader endpoint"
  end
  
  # Graph Database outputs
  output :neptune_cluster_endpoint do
    value "${aws_neptune_cluster.main.endpoint}" 
    description "Neptune cluster endpoint"
  end
  
  output :neptune_reader_endpoint do
    value "${aws_neptune_cluster.main.reader_endpoint}"
    description "Neptune cluster reader endpoint"
  end
  
  # Time Series Database outputs
  output :timestream_database_name do
    value "${aws_timestream_database.metrics.database_name}"
    description "Timestream database name for metrics"
  end
  
  # Memory Database outputs
  output :memorydb_cluster_endpoint do
    value "${aws_memorydb_cluster.main.cluster_endpoint}"
    description "MemoryDB cluster configuration endpoint"
  end
  
  # Resource sharing outputs
  output :resource_share_arn do
    value "${aws_ram_resource_share.database_platform.arn}"
    description "ARN of the database platform resource share"
  end
  
  # Cost estimation output
  output :estimated_monthly_cost do
    value "Estimated: $8,500-12,000/month for complete platform"
    description "Estimated monthly cost for all database services"
  end
end