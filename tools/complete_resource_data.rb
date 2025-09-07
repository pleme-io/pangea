#!/usr/bin/env ruby
# frozen_string_literal: true

# Complete resource data for ALL remaining database batch resources
COMPLETE_RESOURCE_DATA = {
  # Document Database Services - Complete batch
  'aws_docdb_cluster_endpoint' => {
    description: 'Provides a DocumentDB cluster endpoint resource.',
    arguments: {
      'cluster_endpoint_identifier' => { type: 'String', required: true, description: 'The cluster endpoint identifier.' },
      'cluster_identifier' => { type: 'String', required: true, description: 'The cluster identifier.' },
      'endpoint_type' => { type: 'String', required: true, description: 'The type of endpoint. Valid values: READER, WRITER, ANY.' },
      'static_members' => { type: 'Array[String]', required: false, description: 'List of DB instance identifiers.' },
      'excluded_members' => { type: 'Array[String]', required: false, description: 'List of DB instances to exclude.' }
    },
    attributes: {
      'id' => 'The cluster endpoint identifier',
      'arn' => 'The ARN of the cluster endpoint', 
      'endpoint' => 'The endpoint URL',
      'cluster_identifier' => 'The cluster identifier'
    }
  },

  'aws_docdb_global_cluster' => {
    description: 'Provides a DocumentDB Global Cluster resource.',
    arguments: {
      'global_cluster_identifier' => { type: 'String', required: true, description: 'The global cluster identifier.' },
      'source_db_cluster_identifier' => { type: 'String', required: false, description: 'Source cluster to create global cluster from.' },
      'engine' => { type: 'String', required: false, description: 'The database engine. Must be docdb.' },
      'engine_version' => { type: 'String', required: false, description: 'The engine version.' },
      'database_name' => { type: 'String', required: false, description: 'Name of the database.' },
      'deletion_protection' => { type: 'Boolean', required: false, description: 'Enable deletion protection.' },
      'storage_encrypted' => { type: 'Boolean', required: false, description: 'Enable storage encryption.' }
    },
    attributes: {
      'id' => 'The global cluster identifier',
      'arn' => 'The ARN of the global cluster',
      'global_cluster_resource_id' => 'The resource ID of the global cluster',
      'global_cluster_members' => 'Set of objects containing Global Cluster members'
    }
  },

  'aws_docdb_event_subscription' => {
    description: 'Provides a DocumentDB event subscription resource.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The event subscription name.' },
      'sns_topic_arn' => { type: 'String', required: true, description: 'SNS topic ARN for notifications.' },
      'source_type' => { type: 'String', required: false, description: 'Type of source: db-instance, db-cluster, db-parameter-group, db-security-group, db-snapshot, db-cluster-snapshot.' },
      'source_ids' => { type: 'Array[String]', required: false, description: 'List of source IDs.' },
      'event_categories' => { type: 'Array[String]', required: false, description: 'List of event categories.' },
      'enabled' => { type: 'Boolean', required: false, description: 'Whether the subscription is enabled.' }
    },
    attributes: {
      'id' => 'The event subscription name',
      'arn' => 'The ARN of the event subscription',
      'customer_aws_id' => 'The AWS customer account ID'
    }
  },

  'aws_docdb_certificate' => {
    description: 'Provides information about a DocumentDB certificate.',
    arguments: {
      'certificate_identifier' => { type: 'String', required: true, description: 'The certificate identifier.' }
    },
    attributes: {
      'id' => 'The certificate identifier',
      'arn' => 'The ARN of the certificate',
      'certificate_type' => 'The type of the certificate',
      'customer_override' => 'Whether the certificate was overridden',
      'customer_override_valid_till' => 'Valid until timestamp for override',
      'thumbprint' => 'The certificate thumbprint',
      'valid_from' => 'The certificate valid from date',
      'valid_till' => 'The certificate valid until date'
    }
  },

  'aws_docdb_cluster_backup' => {
    description: 'Provides a DocumentDB cluster backup resource (Note: This is typically managed through cluster configuration).',
    arguments: {
      'cluster_identifier' => { type: 'String', required: true, description: 'The cluster identifier.' },
      'backup_retention_period' => { type: 'Integer', required: false, description: 'Days to retain backups.' },
      'preferred_backup_window' => { type: 'String', required: false, description: 'Daily backup window.' }
    },
    attributes: {
      'id' => 'The backup identifier',
      'cluster_identifier' => 'The cluster identifier'
    }
  },

  # Neptune (Graph Database) - Complete remaining
  'aws_neptune_cluster_parameter_group' => {
    description: 'Provides a Neptune Cluster Parameter Group resource.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The parameter group name.' },
      'family' => { type: 'String', required: true, description: 'The Neptune family (e.g., neptune1, neptune1.2).' },
      'description' => { type: 'String', required: false, description: 'The parameter group description.' },
      'parameter' => { type: 'Array[Hash]', required: false, description: 'Parameters to set.' }
    },
    attributes: {
      'id' => 'The parameter group name',
      'arn' => 'The ARN of the parameter group'
    }
  },

  'aws_neptune_cluster_snapshot' => {
    description: 'Manages a Neptune cluster snapshot.',
    arguments: {
      'db_cluster_identifier' => { type: 'String', required: true, description: 'The cluster identifier.' },
      'db_cluster_snapshot_identifier' => { type: 'String', required: true, description: 'The snapshot identifier.' }
    },
    attributes: {
      'id' => 'The snapshot identifier',
      'db_cluster_snapshot_arn' => 'The ARN of the snapshot',
      'engine' => 'The database engine',
      'engine_version' => 'The engine version',
      'port' => 'The database port',
      'status' => 'The snapshot status',
      'storage_encrypted' => 'Whether storage is encrypted',
      'kms_key_id' => 'The KMS key ID',
      'vpc_id' => 'The VPC ID',
      'snapshot_create_time' => 'When the snapshot was created',
      'availability_zones' => 'List of availability zones'
    }
  },

  'aws_neptune_subnet_group' => {
    description: 'Provides a Neptune subnet group resource.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The subnet group name.' },
      'subnet_ids' => { type: 'Array[String]', required: true, description: 'List of subnet IDs.' },
      'description' => { type: 'String', required: false, description: 'The subnet group description.' }
    },
    attributes: {
      'id' => 'The subnet group name',
      'arn' => 'The ARN of the subnet group'
    }
  },

  'aws_neptune_event_subscription' => {
    description: 'Provides a Neptune event subscription resource.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The event subscription name.' },
      'sns_topic_arn' => { type: 'String', required: true, description: 'SNS topic ARN for notifications.' },
      'source_type' => { type: 'String', required: false, description: 'Type of source.' },
      'source_ids' => { type: 'Array[String]', required: false, description: 'List of source IDs.' },
      'event_categories' => { type: 'Array[String]', required: false, description: 'List of event categories.' },
      'enabled' => { type: 'Boolean', required: false, description: 'Whether the subscription is enabled.' }
    },
    attributes: {
      'id' => 'The event subscription name',
      'arn' => 'The ARN of the event subscription',
      'customer_aws_id' => 'The AWS customer account ID'
    }
  },

  'aws_neptune_parameter_group' => {
    description: 'Provides a Neptune Parameter Group resource.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The parameter group name.' },
      'family' => { type: 'String', required: true, description: 'The Neptune family.' },
      'description' => { type: 'String', required: false, description: 'The parameter group description.' },
      'parameter' => { type: 'Array[Hash]', required: false, description: 'Parameters to set.' }
    },
    attributes: {
      'id' => 'The parameter group name',
      'arn' => 'The ARN of the parameter group'
    }
  },

  'aws_neptune_cluster_endpoint' => {
    description: 'Provides a Neptune cluster endpoint resource.',
    arguments: {
      'cluster_endpoint_identifier' => { type: 'String', required: true, description: 'The cluster endpoint identifier.' },
      'cluster_identifier' => { type: 'String', required: true, description: 'The cluster identifier.' },
      'endpoint_type' => { type: 'String', required: true, description: 'The type of endpoint.' }
    },
    attributes: {
      'id' => 'The cluster endpoint identifier',
      'arn' => 'The ARN of the cluster endpoint',
      'endpoint' => 'The endpoint URL'
    }
  },

  # Timestream - Complete remaining
  'aws_timestream_scheduled_query' => {
    description: 'Provides a Timestream scheduled query resource.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The scheduled query name.' },
      'query_string' => { type: 'String', required: true, description: 'The query string.' },
      'schedule_configuration' => { type: 'Hash', required: true, description: 'Schedule configuration.' },
      'notification_configuration' => { type: 'Hash', required: true, description: 'Notification configuration.' },
      'target_configuration' => { type: 'Hash', required: false, description: 'Target configuration for query results.' },
      'client_token' => { type: 'String', required: false, description: 'Client request token.' },
      'scheduled_query_execution_role_arn' => { type: 'String', required: true, description: 'Execution role ARN.' },
      'error_report_configuration' => { type: 'Hash', required: false, description: 'Error reporting configuration.' },
      'kms_key_id' => { type: 'String', required: false, description: 'KMS key for encryption.' }
    },
    attributes: {
      'id' => 'The scheduled query name',
      'arn' => 'The ARN of the scheduled query',
      'state' => 'The state of the scheduled query'
    }
  },

  'aws_timestream_batch_load_task' => {
    description: 'Provides a Timestream batch load task resource.',
    arguments: {
      'database_name' => { type: 'String', required: true, description: 'The database name.' },
      'table_name' => { type: 'String', required: true, description: 'The table name.' },
      'data_source_configuration' => { type: 'Hash', required: true, description: 'Data source configuration.' },
      'data_model_configuration' => { type: 'Hash', required: false, description: 'Data model configuration.' },
      'report_configuration' => { type: 'Hash', required: false, description: 'Report configuration.' },
      'target_database_name' => { type: 'String', required: false, description: 'Target database name.' },
      'target_table_name' => { type: 'String', required: false, description: 'Target table name.' }
    },
    attributes: {
      'id' => 'The batch load task ID',
      'creation_time' => 'When the task was created',
      'last_updated_time' => 'When the task was last updated',
      'resumable_until' => 'Until when the task can be resumed',
      'task_status' => 'The task status'
    }
  },

  'aws_timestream_influx_db_instance' => {
    description: 'Provides a Timestream for InfluxDB instance resource.',
    arguments: {
      'allocated_storage' => { type: 'Integer', required: true, description: 'Storage allocated to the instance in GB.' },
      'bucket' => { type: 'String', required: false, description: 'The name of the initial InfluxDB bucket.' },
      'db_instance_type' => { type: 'String', required: true, description: 'The instance type.' },
      'db_name' => { type: 'String', required: true, description: 'The name of the initial InfluxDB database.' },
      'db_parameter_group_identifier' => { type: 'String', required: false, description: 'The parameter group identifier.' },
      'deployment_type' => { type: 'String', required: false, description: 'Deployment type: WITH_MULTIAZ_STANDBY or SINGLE_AZ.' },
      'log_delivery_configuration' => { type: 'Array[Hash]', required: false, description: 'Log delivery configuration.' },
      'name' => { type: 'String', required: true, description: 'The name of the instance.' },
      'organization' => { type: 'String', required: false, description: 'The name of the initial organization.' },
      'password' => { type: 'String', required: true, description: 'The password of the initial admin user.' },
      'publicly_accessible' => { type: 'Boolean', required: false, description: 'Whether the instance is publicly accessible.' },
      'username' => { type: 'String', required: true, description: 'The username of the initial admin user.' },
      'vpc_security_group_ids' => { type: 'Array[String]', required: false, description: 'VPC security group IDs.' },
      'vpc_subnet_ids' => { type: 'Array[String]', required: false, description: 'VPC subnet IDs.' }
    },
    attributes: {
      'id' => 'The instance identifier',
      'arn' => 'The ARN of the instance',
      'availability_zone' => 'The availability zone',
      'endpoint' => 'The connection endpoint',
      'influx_auth_parameters_secret_arn' => 'The ARN of the AWS Secrets Manager secret',
      'secondary_availability_zone' => 'The secondary availability zone'
    }
  },

  'aws_timestream_table_retention_properties' => {
    description: 'Provides a Timestream table retention properties resource.',
    arguments: {
      'database_name' => { type: 'String', required: true, description: 'The database name.' },
      'table_name' => { type: 'String', required: true, description: 'The table name.' },
      'magnetic_store_retention_period_in_days' => { type: 'Integer', required: false, description: 'Days to retain in magnetic store.' },
      'memory_store_retention_period_in_hours' => { type: 'Integer', required: false, description: 'Hours to retain in memory store.' }
    },
    attributes: {
      'id' => 'The table identifier'
    }
  },

  'aws_timestream_access_policy' => {
    description: 'Provides a Timestream access policy resource.',
    arguments: {
      'database_name' => { type: 'String', required: true, description: 'The database name.' },
      'table_name' => { type: 'String', required: false, description: 'The table name (optional for database-level policies).' },
      'policy_document' => { type: 'String', required: true, description: 'The JSON policy document.' }
    },
    attributes: {
      'id' => 'The policy identifier'
    }
  },

  # MemoryDB - Complete remaining
  'aws_memorydb_snapshot' => {
    description: 'Provides a MemoryDB Snapshot resource.',
    arguments: {
      'cluster_name' => { type: 'String', required: true, description: 'The cluster name to snapshot.' },
      'name' => { type: 'String', required: true, description: 'The snapshot name.' },
      'name_prefix' => { type: 'String', required: false, description: 'The snapshot name prefix.' },
      'kms_key_id' => { type: 'String', required: false, description: 'KMS key for encryption.' }
    },
    attributes: {
      'id' => 'The snapshot name',
      'arn' => 'The snapshot ARN',
      'cluster_configuration' => 'Configuration of the cluster from which the snapshot was taken',
      'source' => 'Indicates whether the snapshot is from an automatic backup or manual snapshot'
    }
  },

  'aws_memorydb_multi_region_cluster' => {
    description: 'Provides a MemoryDB Multi-Region Cluster resource.',
    arguments: {
      'cluster_name_suffix' => { type: 'String', required: true, description: 'The cluster name suffix.' },
      'node_type' => { type: 'String', required: true, description: 'The node type.' },
      'num_shards' => { type: 'Integer', required: false, description: 'Number of shards.' },
      'description' => { type: 'String', required: false, description: 'Description of the multi-region cluster.' },
      'engine' => { type: 'String', required: false, description: 'The Redis engine.' },
      'engine_version' => { type: 'String', required: false, description: 'The Redis engine version.' }
    },
    attributes: {
      'id' => 'The multi-region cluster name',
      'arn' => 'The ARN of the multi-region cluster',
      'multi_region_cluster_name' => 'The multi-region cluster name',
      'status' => 'The status of the multi-region cluster'
    }
  },

  'aws_memorydb_cluster_endpoint' => {
    description: 'Provides a MemoryDB Cluster Endpoint resource.',
    arguments: {
      'cluster_name' => { type: 'String', required: true, description: 'The cluster name.' }
    },
    attributes: {
      'id' => 'The cluster name',
      'address' => 'The DNS address of the configuration endpoint',
      'port' => 'The port number on which the configuration endpoint will accept connections'
    }
  },

  # License Manager - Complete remaining
  'aws_licensemanager_grant_accepter' => {
    description: 'Provides a License Manager grant accepter resource.',
    arguments: {
      'grant_arn' => { type: 'String', required: true, description: 'The grant ARN to accept.' }
    },
    attributes: {
      'id' => 'The grant ARN',
      'name' => 'The name of the grant',
      'allowed_operations' => 'The allowed operations for the grant',
      'license_arn' => 'The license ARN',
      'principal' => 'The principal ARN that is granted access',
      'home_region' => 'The home region for the grant',
      'status' => 'The status of the grant',
      'version' => 'The version of the grant'
    }
  },

  'aws_licensemanager_license_grant_accepter' => {
    description: 'Provides a License Manager license grant accepter resource.',
    arguments: {
      'grant_arn' => { type: 'String', required: true, description: 'The grant ARN to accept.' }
    },
    attributes: {
      'id' => 'The grant ARN',
      'parent_arn' => 'The parent license ARN for the grant'
    }
  },

  'aws_licensemanager_token' => {
    description: 'Provides a License Manager token resource.',
    arguments: {
      'license_arn' => { type: 'String', required: true, description: 'The license ARN.' },
      'role_arns' => { type: 'Array[String]', required: false, description: 'List of role ARNs.' },
      'token_properties' => { type: 'Hash', required: false, description: 'Token properties.' }
    },
    attributes: {
      'id' => 'The token ID',
      'token' => 'The generated token',
      'token_type' => 'The type of token'
    }
  },

  'aws_licensemanager_report_generator' => {
    description: 'Provides a License Manager report generator resource.',
    arguments: {
      'license_manager_report_generator_name' => { type: 'String', required: true, description: 'The report generator name.' },
      'type' => { type: 'Array[String]', required: true, description: 'List of report types to generate.' },
      'report_context' => { type: 'Hash', required: true, description: 'The report context.' },
      'report_frequency' => { type: 'String', required: true, description: 'The report frequency.' },
      's3_bucket_name' => { type: 'String', required: true, description: 'The S3 bucket name for reports.' },
      'description' => { type: 'String', required: false, description: 'The report generator description.' }
    },
    attributes: {
      'id' => 'The report generator name',
      'arn' => 'The ARN of the report generator'
    }
  },

  # RAM - Complete remaining
  'aws_ram_invitation_accepter' => {
    description: 'Accepts a Resource Access Manager (RAM) resource share invitation.',
    arguments: {
      'share_arn' => { type: 'String', required: true, description: 'The resource share ARN from the invitation.' }
    },
    attributes: {
      'id' => 'The resource share ARN',
      'invitation_arn' => 'The invitation ARN',
      'share_id' => 'The resource share ID',
      'status' => 'The invitation status',
      'share_name' => 'The resource share name',
      'receiver_account_id' => 'The account ID of the receiver'
    }
  },

  'aws_ram_sharing_with_organization' => {
    description: 'Manages Resource Access Manager (RAM) resource sharing with AWS Organizations.',
    arguments: {
      'enable' => { type: 'Boolean', required: true, description: 'Enable or disable sharing with organization.' }
    },
    attributes: {
      'id' => 'The account ID'
    }
  },

  'aws_ram_permission' => {
    description: 'Provides a Resource Access Manager (RAM) permission resource.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The permission name.' },
      'policy_template' => { type: 'String', required: true, description: 'The policy template.' },
      'resource_type' => { type: 'String', required: true, description: 'The resource type.' }
    },
    attributes: {
      'id' => 'The permission ARN',
      'arn' => 'The permission ARN',
      'version' => 'The permission version',
      'type' => 'The permission type',
      'status' => 'The permission status',
      'creation_time' => 'When the permission was created',
      'last_updated_time' => 'When the permission was last updated'
    }
  },

  'aws_ram_permission_association' => {
    description: 'Associates a permission with a Resource Access Manager (RAM) resource share.',
    arguments: {
      'permission_arn' => { type: 'String', required: true, description: 'The permission ARN.' },
      'resource_share_arn' => { type: 'String', required: true, description: 'The resource share ARN.' },
      'replace' => { type: 'Boolean', required: false, description: 'Replace existing permissions.' }
    },
    attributes: {
      'id' => 'The association ID'
    }
  },

  'aws_ram_resource_share_invitation' => {
    description: 'Manages a Resource Access Manager (RAM) resource share invitation.',
    arguments: {
      'resource_share_arn' => { type: 'String', required: true, description: 'The resource share ARN.' },
      'receiver_account_id' => { type: 'String', required: true, description: 'The receiver account ID.' }
    },
    attributes: {
      'id' => 'The invitation ARN',
      'invitation_arn' => 'The invitation ARN',
      'sender_account_id' => 'The sender account ID',
      'resource_share_name' => 'The resource share name',
      'status' => 'The invitation status',
      'invitation_timestamp' => 'When the invitation was sent'
    }
  },

  'aws_ram_managed_permission' => {
    description: 'Retrieves information about a Resource Access Manager (RAM) managed permission.',
    arguments: {
      'name' => { type: 'String', required: true, description: 'The managed permission name.' },
      'resource_type' => { type: 'String', required: false, description: 'The resource type.' }
    },
    attributes: {
      'id' => 'The permission ARN',
      'arn' => 'The permission ARN',
      'version' => 'The permission version',
      'default_version' => 'Whether this is the default version',
      'type' => 'The permission type',
      'status' => 'The permission status',
      'creation_time' => 'When the permission was created',
      'last_updated_time' => 'When the permission was last updated'
    }
  }
}

# Export the data if this file is required
if __FILE__ != $0
  RESOURCE_DATA = COMPLETE_RESOURCE_DATA
end