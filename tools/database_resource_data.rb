#!/usr/bin/env ruby
# frozen_string_literal: true

# Enhanced resource data for database services batch
ENHANCED_RESOURCE_DATA = {
  # Document Database Services
  'aws_docdb_cluster' => {
    description: 'Manages a DocumentDB cluster, providing a MongoDB-compatible database service.',
    arguments: {
      'cluster_identifier' => { type: 'String', required: true, description: 'The cluster identifier. Must be lowercase.' },
      'engine' => { type: 'String', required: false, description: 'The name of the database engine. Must be docdb.' },
      'engine_version' => { type: 'String', required: false, description: 'The engine version for DocumentDB.' },
      'master_username' => { type: 'String', required: false, description: 'Username for the master DB user.' },
      'master_password' => { type: 'String', required: false, description: 'Password for the master DB user.' },
      'backup_retention_period' => { type: 'Integer', required: false, description: 'Days to retain backups. Default is 1.' },
      'preferred_backup_window' => { type: 'String', required: false, description: 'Daily time range for backups.' },
      'preferred_maintenance_window' => { type: 'String', required: false, description: 'Weekly time range for maintenance.' },
      'port' => { type: 'Integer', required: false, description: 'The port for the DB cluster. Default is 27017.' },
      'vpc_security_group_ids' => { type: 'Array[String]', required: false, description: 'List of VPC security group IDs.' },
      'db_subnet_group_name' => { type: 'String', required: false, description: 'DB subnet group name.' },
      'db_cluster_parameter_group_name' => { type: 'String', required: false, description: 'DB cluster parameter group name.' },
      'storage_encrypted' => { type: 'Boolean', required: false, description: 'Whether storage is encrypted.' },
      'kms_key_id' => { type: 'String', required: false, description: 'KMS key ID for encryption.' },
      'enabled_cloudwatch_logs_exports' => { type: 'Array[String]', required: false, description: 'Log types to export to CloudWatch.' },
      'deletion_protection' => { type: 'Boolean', required: false, description: 'If true, cluster cant be deleted.' },
      'skip_final_snapshot' => { type: 'Boolean', required: false, description: 'Skip final snapshot on deletion.' },
      'final_snapshot_identifier' => { type: 'String', required: false, description: 'Name for final snapshot.' },
      'apply_immediately' => { type: 'Boolean', required: false, description: 'Apply changes immediately.' },
      'availability_zones' => { type: 'Array[String]', required: false, description: 'List of availability zones.' },
      'enable_global_write_forwarding' => { type: 'Boolean', required: false, description: 'Enable global write forwarding.' }
    },
    attributes: {
      'id' => 'The DocumentDB cluster ID',
      'arn' => 'The ARN of the DocumentDB cluster',
      'cluster_members' => 'List of cluster instance identifiers',
      'cluster_resource_id' => 'The cluster resource ID',
      'endpoint' => 'The primary endpoint for the cluster',
      'reader_endpoint' => 'The reader endpoint for the cluster',
      'hosted_zone_id' => 'The hosted zone ID of the cluster',
      'port' => 'The database port',
      'status' => 'The cluster status',
      'storage_encrypted' => 'Whether storage is encrypted'
    },
    validations: [
      'cluster_identifier must be lowercase and start with a letter',
      'master_username and master_password required for new clusters',
      'backup_retention_period must be between 0 and 35 days'
    ]
  },

  'aws_docdb_cluster_instance' => {
    description: 'Provides a DocumentDB Cluster Instance resource. A Cluster Instance is an isolated database instance within a DocumentDB Cluster.',
    arguments: {
      'identifier' => { type: 'String', required: true, description: 'The instance identifier.' },
      'cluster_identifier' => { type: 'String', required: true, description: 'The cluster this instance belongs to.' },
      'instance_class' => { type: 'String', required: true, description: 'The instance class (e.g., db.r5.large).' },
      'engine' => { type: 'String', required: false, description: 'The database engine. Must be docdb.' },
      'availability_zone' => { type: 'String', required: false, description: 'The AZ for the instance.' },
      'preferred_maintenance_window' => { type: 'String', required: false, description: 'Weekly maintenance window.' },
      'apply_immediately' => { type: 'Boolean', required: false, description: 'Apply changes immediately.' },
      'auto_minor_version_upgrade' => { type: 'Boolean', required: false, description: 'Enable auto minor version upgrade.' },
      'promotion_tier' => { type: 'Integer', required: false, description: 'Failover priority (0-15).' },
      'enable_performance_insights' => { type: 'Boolean', required: false, description: 'Enable Performance Insights.' },
      'performance_insights_kms_key_id' => { type: 'String', required: false, description: 'KMS key for Performance Insights.' },
      'performance_insights_retention_period' => { type: 'Integer', required: false, description: 'Days to retain Performance Insights data.' },
      'copy_tags_to_snapshot' => { type: 'Boolean', required: false, description: 'Copy tags to snapshots.' },
      'ca_cert_identifier' => { type: 'String', required: false, description: 'CA certificate identifier.' }
    },
    attributes: {
      'id' => 'The instance identifier',
      'arn' => 'The ARN of the instance',
      'dbi_resource_id' => 'The resource ID of the instance',
      'endpoint' => 'The instance endpoint',
      'port' => 'The database port',
      'status' => 'The instance status',
      'storage_encrypted' => 'Whether storage is encrypted',
      'kms_key_id' => 'The KMS key ID',
      'publicly_accessible' => 'Whether the instance is publicly accessible',
      'writer' => 'Whether this instance is the primary'
    }
  },

  'aws_docdb_cluster_parameter_group' => {
    description: 'Provides a DocumentDB Cluster Parameter Group resource.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The parameter group name.' },
      'family' => { type: 'String', required: true, description: 'The DB family (e.g., docdb3.6, docdb4.0).' },
      'description' => { type: 'String', required: false, description: 'The parameter group description.' },
      'parameter' => { type: 'Array[Hash]', required: false, description: 'Parameters to apply.' }
    },
    attributes: {
      'id' => 'The parameter group name',
      'arn' => 'The ARN of the parameter group'
    },
    parameter_schema: {
      'name' => 'Parameter name',
      'value' => 'Parameter value',
      'apply_method' => 'immediate or pending-reboot'
    }
  },

  'aws_docdb_cluster_snapshot' => {
    description: 'Manages a DocumentDB cluster snapshot.',
    arguments: {
      'db_cluster_identifier' => { type: 'String', required: true, description: 'The cluster to snapshot.' },
      'db_cluster_snapshot_identifier' => { type: 'String', required: true, description: 'The snapshot identifier.' }
    },
    attributes: {
      'id' => 'The snapshot identifier',
      'db_cluster_snapshot_arn' => 'The ARN of the snapshot',
      'engine' => 'The database engine',
      'engine_version' => 'The engine version',
      'port' => 'The database port',
      'source_db_cluster_snapshot_arn' => 'Source snapshot ARN if copied',
      'storage_encrypted' => 'Whether storage is encrypted',
      'kms_key_id' => 'The KMS key ID',
      'status' => 'The snapshot status',
      'vpc_id' => 'The VPC ID',
      'snapshot_create_time' => 'When the snapshot was created',
      'master_username' => 'The master username',
      'availability_zones' => 'List of AZs for the snapshot'
    }
  },

  'aws_docdb_subnet_group' => {
    description: 'Provides a DocumentDB subnet group resource.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The subnet group name.' },
      'description' => { type: 'String', required: false, description: 'The subnet group description.' },
      'subnet_ids' => { type: 'Array[String]', required: true, description: 'List of subnet IDs.' }
    },
    attributes: {
      'id' => 'The subnet group name',
      'arn' => 'The ARN of the subnet group'
    }
  },

  # Neptune (Graph Database) Resources
  'aws_neptune_cluster' => {
    description: 'Provides a Neptune Cluster resource for graph database workloads.',
    arguments: {
      'cluster_identifier' => { type: 'String', required: true, description: 'The cluster identifier.' },
      'engine' => { type: 'String', required: false, description: 'The database engine. Must be neptune.' },
      'engine_version' => { type: 'String', required: false, description: 'The engine version.' },
      'backup_retention_period' => { type: 'Integer', required: false, description: 'Days to retain backups.' },
      'preferred_backup_window' => { type: 'String', required: false, description: 'Daily backup window.' },
      'preferred_maintenance_window' => { type: 'String', required: false, description: 'Weekly maintenance window.' },
      'port' => { type: 'Integer', required: false, description: 'The database port. Default is 8182.' },
      'vpc_security_group_ids' => { type: 'Array[String]', required: false, description: 'VPC security group IDs.' },
      'neptune_subnet_group_name' => { type: 'String', required: false, description: 'Neptune subnet group name.' },
      'neptune_cluster_parameter_group_name' => { type: 'String', required: false, description: 'Parameter group name.' },
      'storage_encrypted' => { type: 'Boolean', required: false, description: 'Enable storage encryption.' },
      'kms_key_id' => { type: 'String', required: false, description: 'KMS key for encryption.' },
      'iam_database_authentication_enabled' => { type: 'Boolean', required: false, description: 'Enable IAM authentication.' },
      'iam_roles' => { type: 'Array[String]', required: false, description: 'IAM roles for the cluster.' },
      'enable_cloudwatch_logs_exports' => { type: 'Array[String]', required: false, description: 'Log types to export.' },
      'deletion_protection' => { type: 'Boolean', required: false, description: 'Enable deletion protection.' },
      'skip_final_snapshot' => { type: 'Boolean', required: false, description: 'Skip final snapshot.' },
      'final_snapshot_identifier' => { type: 'String', required: false, description: 'Final snapshot name.' },
      'apply_immediately' => { type: 'Boolean', required: false, description: 'Apply changes immediately.' },
      'availability_zones' => { type: 'Array[String]', required: false, description: 'List of AZs.' },
      'copy_tags_to_snapshot' => { type: 'Boolean', required: false, description: 'Copy tags to snapshots.' },
      'enable_global_write_forwarding' => { type: 'Boolean', required: false, description: 'Enable global write forwarding.' },
      'serverless_v2_scaling_configuration' => { type: 'Hash', required: false, description: 'Serverless v2 scaling config.' }
    },
    attributes: {
      'id' => 'The Neptune cluster identifier',
      'arn' => 'The ARN of the Neptune cluster',
      'cluster_resource_id' => 'The cluster resource ID',
      'cluster_members' => 'List of cluster instances',
      'endpoint' => 'The primary endpoint',
      'reader_endpoint' => 'The reader endpoint',
      'hosted_zone_id' => 'The hosted zone ID',
      'port' => 'The database port',
      'status' => 'The cluster status',
      'storage_encrypted' => 'Whether storage is encrypted'
    }
  },

  'aws_neptune_cluster_instance' => {
    description: 'Provides a Neptune Cluster Instance resource.',
    arguments: {
      'identifier' => { type: 'String', required: true, description: 'The instance identifier.' },
      'cluster_identifier' => { type: 'String', required: true, description: 'The cluster identifier.' },
      'instance_class' => { type: 'String', required: true, description: 'The instance class.' },
      'engine' => { type: 'String', required: false, description: 'The database engine.' },
      'engine_version' => { type: 'String', required: false, description: 'The engine version.' },
      'availability_zone' => { type: 'String', required: false, description: 'The AZ for the instance.' },
      'preferred_maintenance_window' => { type: 'String', required: false, description: 'Maintenance window.' },
      'apply_immediately' => { type: 'Boolean', required: false, description: 'Apply changes immediately.' },
      'auto_minor_version_upgrade' => { type: 'Boolean', required: false, description: 'Auto upgrade minor versions.' },
      'promotion_tier' => { type: 'Integer', required: false, description: 'Failover priority.' },
      'neptune_parameter_group_name' => { type: 'String', required: false, description: 'Parameter group name.' }
    },
    attributes: {
      'id' => 'The instance identifier',
      'arn' => 'The instance ARN',
      'dbi_resource_id' => 'The instance resource ID',
      'endpoint' => 'The instance endpoint',
      'port' => 'The database port',
      'status' => 'The instance status',
      'storage_encrypted' => 'Whether storage is encrypted',
      'kms_key_id' => 'The KMS key ID',
      'writer' => 'Whether this is the primary instance'
    }
  },

  # Timestream Resources
  'aws_timestream_database' => {
    description: 'Provides a Timestream database resource for time series data.',
    arguments: {
      'database_name' => { type: 'String', required: true, description: 'The database name.' },
      'kms_key_id' => { type: 'String', required: false, description: 'KMS key for encryption.' }
    },
    attributes: {
      'id' => 'The database name',
      'arn' => 'The database ARN',
      'kms_key_id' => 'The KMS key ID',
      'table_count' => 'Number of tables in the database'
    }
  },

  'aws_timestream_table' => {
    description: 'Provides a Timestream table resource for storing time series data.',
    arguments: {
      'database_name' => { type: 'String', required: true, description: 'The database name.' },
      'table_name' => { type: 'String', required: true, description: 'The table name.' },
      'retention_properties' => { type: 'Hash', required: false, description: 'Data retention settings.' },
      'magnetic_store_write_properties' => { type: 'Hash', required: false, description: 'Magnetic store settings.' },
      'schema' => { type: 'Hash', required: false, description: 'Table schema definition.' }
    },
    attributes: {
      'id' => 'The table identifier',
      'arn' => 'The table ARN',
      'status' => 'The table status'
    },
    retention_schema: {
      'memory_store_retention_period_in_hours' => 'Hours to retain in memory',
      'magnetic_store_retention_period_in_days' => 'Days to retain in magnetic store'
    }
  },

  # MemoryDB Resources
  'aws_memorydb_cluster' => {
    description: 'Provides a MemoryDB Cluster resource for Redis-compatible in-memory database.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The cluster name.' },
      'node_type' => { type: 'String', required: true, description: 'The node type.' },
      'num_shards' => { type: 'Integer', required: false, description: 'Number of shards.' },
      'num_replicas_per_shard' => { type: 'Integer', required: false, description: 'Replicas per shard.' },
      'subnet_group_name' => { type: 'String', required: false, description: 'Subnet group name.' },
      'security_group_ids' => { type: 'Array[String]', required: false, description: 'Security group IDs.' },
      'maintenance_window' => { type: 'String', required: false, description: 'Maintenance window.' },
      'port' => { type: 'Integer', required: false, description: 'The port number.' },
      'parameter_group_name' => { type: 'String', required: false, description: 'Parameter group name.' },
      'snapshot_retention_limit' => { type: 'Integer', required: false, description: 'Days to retain snapshots.' },
      'snapshot_window' => { type: 'String', required: false, description: 'Daily snapshot window.' },
      'acl_name' => { type: 'String', required: true, description: 'The ACL to use.' },
      'engine_version' => { type: 'String', required: false, description: 'Redis engine version.' },
      'tls_enabled' => { type: 'Boolean', required: false, description: 'Enable TLS.' },
      'kms_key_id' => { type: 'String', required: false, description: 'KMS key for encryption.' },
      'snapshot_arns' => { type: 'Array[String]', required: false, description: 'Snapshots to restore from.' },
      'snapshot_name' => { type: 'String', required: false, description: 'Snapshot name to restore.' },
      'final_snapshot_name' => { type: 'String', required: false, description: 'Final snapshot name.' },
      'description' => { type: 'String', required: false, description: 'Cluster description.' },
      'sns_topic_arn' => { type: 'String', required: false, description: 'SNS topic for notifications.' },
      'auto_minor_version_upgrade' => { type: 'Boolean', required: false, description: 'Auto upgrade minor versions.' },
      'data_tiering' => { type: 'Boolean', required: false, description: 'Enable data tiering.' }
    },
    attributes: {
      'id' => 'The cluster name',
      'arn' => 'The cluster ARN',
      'cluster_endpoint' => 'The cluster configuration endpoint',
      'shards' => 'Information about shards',
      'status' => 'The cluster status',
      'engine_patch_version' => 'The engine patch version'
    }
  },

  'aws_memorydb_parameter_group' => {
    description: 'Provides a MemoryDB Parameter Group resource.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The parameter group name.' },
      'family' => { type: 'String', required: true, description: 'The MemoryDB family.' },
      'description' => { type: 'String', required: false, description: 'Parameter group description.' },
      'parameter' => { type: 'Array[Hash]', required: false, description: 'Parameters to set.' }
    },
    attributes: {
      'id' => 'The parameter group name',
      'arn' => 'The parameter group ARN'
    }
  },

  'aws_memorydb_subnet_group' => {
    description: 'Provides a MemoryDB Subnet Group resource.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The subnet group name.' },
      'subnet_ids' => { type: 'Array[String]', required: true, description: 'List of subnet IDs.' },
      'description' => { type: 'String', required: false, description: 'Subnet group description.' }
    },
    attributes: {
      'id' => 'The subnet group name',
      'arn' => 'The subnet group ARN',
      'vpc_id' => 'The VPC ID'
    }
  },

  'aws_memorydb_user' => {
    description: 'Provides a MemoryDB User resource.',
    arguments: {
      'user_name' => { type: 'String', required: true, description: 'The username.' },
      'access_string' => { type: 'String', required: true, description: 'Access permissions string.' },
      'authentication_mode' => { type: 'Hash', required: true, description: 'Authentication settings.' }
    },
    attributes: {
      'id' => 'The username',
      'arn' => 'The user ARN',
      'minimum_engine_version' => 'Minimum engine version required'
    },
    auth_schema: {
      'type' => 'password or iam',
      'passwords' => 'Array of passwords (for password type)'
    }
  },

  'aws_memorydb_acl' => {
    description: 'Provides a MemoryDB ACL resource.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The ACL name.' },
      'user_names' => { type: 'Array[String]', required: false, description: 'List of user names.' }
    },
    attributes: {
      'id' => 'The ACL name',
      'arn' => 'The ACL ARN',
      'minimum_engine_version' => 'Minimum engine version'
    }
  },

  # License Manager Resources
  'aws_licensemanager_license_configuration' => {
    description: 'Provides a License Manager license configuration resource.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The license configuration name.' },
      'license_counting_type' => { type: 'String', required: true, description: 'Counting type: vCPU, Instance, Core, or Socket.' },
      'description' => { type: 'String', required: false, description: 'Configuration description.' },
      'license_count' => { type: 'Integer', required: false, description: 'Number of licenses.' },
      'license_count_hard_limit' => { type: 'Boolean', required: false, description: 'Hard limit enforcement.' },
      'license_rules' => { type: 'Array[String]', required: false, description: 'License rules.' }
    },
    attributes: {
      'id' => 'The license configuration ID',
      'arn' => 'The license configuration ARN',
      'owner_account_id' => 'The account ID of the owner'
    }
  },

  'aws_licensemanager_association' => {
    description: 'Provides a License Manager association between a license configuration and a resource.',
    arguments: {
      'license_configuration_arn' => { type: 'String', required: true, description: 'License configuration ARN.' },
      'resource_arn' => { type: 'String', required: true, description: 'Resource ARN to associate.' }
    },
    attributes: {
      'id' => 'The association ID'
    }
  },

  'aws_licensemanager_grant' => {
    description: 'Provides a License Manager grant resource.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The grant name.' },
      'allowed_operations' => { type: 'Array[String]', required: true, description: 'Allowed operations.' },
      'license_arn' => { type: 'String', required: true, description: 'The license ARN.' },
      'principal' => { type: 'String', required: true, description: 'The grantee principal ARN.' },
      'home_region' => { type: 'String', required: true, description: 'The home region.' }
    },
    attributes: {
      'id' => 'The grant ID',
      'arn' => 'The grant ARN',
      'status' => 'The grant status',
      'version' => 'The grant version'
    }
  },

  # Resource Access Manager Resources
  'aws_ram_resource_share' => {
    description: 'Provides a Resource Access Manager (RAM) Resource Share.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The resource share name.' },
      'allow_external_principals' => { type: 'Boolean', required: false, description: 'Allow external principals.' },
      'permission_arns' => { type: 'Array[String]', required: false, description: 'List of permission ARNs.' }
    },
    attributes: {
      'id' => 'The resource share ID',
      'arn' => 'The resource share ARN',
      'status' => 'The resource share status'
    }
  },

  'aws_ram_resource_association' => {
    description: 'Associates a resource with a RAM Resource Share.',
    arguments: {
      'resource_arn' => { type: 'String', required: true, description: 'The resource ARN.' },
      'resource_share_arn' => { type: 'String', required: true, description: 'The resource share ARN.' }
    },
    attributes: {
      'id' => 'The association ID'
    }
  },

  'aws_ram_principal_association' => {
    description: 'Associates a principal with a RAM Resource Share.',
    arguments: {
      'principal' => { type: 'String', required: true, description: 'The principal ARN.' },
      'resource_share_arn' => { type: 'String', required: true, description: 'The resource share ARN.' }
    },
    attributes: {
      'id' => 'The association ID'
    }
  },

  'aws_ram_resource_share_accepter' => {
    description: 'Accepts a Resource Access Manager (RAM) Resource Share invitation.',
    arguments: {
      'share_arn' => { type: 'String', required: true, description: 'The resource share ARN.' }
    },
    attributes: {
      'id' => 'The resource share ARN',
      'invitation_arn' => 'The invitation ARN',
      'share_id' => 'The resource share ID',
      'status' => 'The invitation status',
      'share_name' => 'The resource share name'
    }
  }
}

# Export the data if this file is required
if __FILE__ != $0
  RESOURCE_DATA = ENHANCED_RESOURCE_DATA
end