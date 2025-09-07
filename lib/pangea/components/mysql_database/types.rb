# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Components
    module MySqlDatabase
      # Backup configuration
      class BackupConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :backup_retention_period, Types::Integer.default(7).constrained(gteq: 0, lteq: 35)
        attribute :backup_window, Types::String.default("03:00-04:00").constrained(
          format: /\A\d{2}:\d{2}-\d{2}:\d{2}\z/
        )
        attribute :copy_tags_to_snapshot, Types::Bool.default(true)
        attribute :delete_automated_backups, Types::Bool.default(true)
        attribute :skip_final_snapshot, Types::Bool.default(false)
        attribute :final_snapshot_identifier, Types::String.optional
      end
      
      # Maintenance configuration
      class MaintenanceConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :maintenance_window, Types::String.default("Sun:04:00-Sun:05:00").constrained(
          format: /\A(Mon|Tue|Wed|Thu|Fri|Sat|Sun):\d{2}:\d{2}-(Mon|Tue|Wed|Thu|Fri|Sat|Sun):\d{2}:\d{2}\z/
        )
        attribute :auto_minor_version_upgrade, Types::Bool.default(true)
        attribute :allow_major_version_upgrade, Types::Bool.default(false)
      end
      
      # Performance monitoring configuration
      class MonitoringConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :monitoring_interval, Types::Integer.default(60).enum(0, 1, 5, 10, 15, 30, 60)
        attribute :monitoring_role_arn, Types::String.optional.constrained(format: /\Aarn:aws:iam::\d{12}:role\//)
        attribute :performance_insights_enabled, Types::Bool.default(true)
        attribute :performance_insights_retention_period, Types::Integer.default(7).enum(7, 731)
        attribute :performance_insights_kms_key_id, Types::String.optional
      end
      
      # Parameter group settings
      class ParameterConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :create_parameter_group, Types::Bool.default(true)
        attribute :parameter_group_name, Types::String.optional
        attribute :parameter_group_family, Types::String.default("mysql8.0")
        attribute :parameters, Types::Hash.default({
          "innodb_buffer_pool_size" => "{DBInstanceClassMemory*3/4}",
          "max_connections" => "1000",
          "innodb_log_file_size" => "268435456",
          "log_bin_trust_function_creators" => "1",
          "slow_query_log" => "1",
          "long_query_time" => "2"
        }.freeze)
      end
      
      # Main MySQL Database component attributes
      class MySqlDatabaseAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Network configuration
        attribute :vpc_ref, Types.Instance(Object)  # ResourceReference to VPC
        attribute :subnet_refs, Types::Array.of(Types.Instance(Object)).constrained(min_size: 2)  # ResourceReferences to subnets
        attribute :security_group_refs, Types::Array.of(Types.Instance(Object)).default([].freeze)  # ResourceReferences to security groups
        
        # Database engine configuration
        attribute :engine, Types::String.default("mysql").enum('mysql')
        attribute :engine_version, Types::String.default("8.0.35")
        attribute :db_instance_class, Types::RdsInstanceClass.default("db.t3.micro")
        attribute :allocated_storage, Types::Integer.default(20).constrained(gteq: 20, lteq: 65536)
        attribute :max_allocated_storage, Types::Integer.optional.constrained(gteq: 20, lteq: 65536)
        attribute :storage_type, Types::String.default("gp3").enum('gp2', 'gp3', 'io1', 'io2')
        attribute :iops, Types::Integer.optional.constrained(gteq: 1000, lteq: 80000)
        attribute :storage_throughput, Types::Integer.optional.constrained(gteq: 125, lteq: 4000)
        
        # Database identification and access
        attribute :db_name, Types::String.optional.constrained(
          format: /\A[a-zA-Z][a-zA-Z0-9_]*\z/,
          max_size: 64
        )
        attribute :identifier, Types::String.optional.constrained(
          format: /\A[a-z][a-z0-9-]*[a-z0-9]\z/,
          max_size: 63
        )
        attribute :username, Types::String.default("admin").constrained(
          format: /\A[a-zA-Z][a-zA-Z0-9_]*\z/,
          max_size: 16
        )
        attribute :manage_master_user_password, Types::Bool.default(true)
        attribute :password, Types::String.optional.constrained(min_size: 8, max_size: 41)
        attribute :kms_key_id, Types::String.optional
        
        # High availability and Multi-AZ
        attribute :multi_az, Types::Bool.default(false)
        attribute :availability_zone, Types::String.optional
        
        # Security configuration
        attribute :storage_encrypted, Types::Bool.default(true)
        attribute :publicly_accessible, Types::Bool.default(false)
        attribute :port, Types::Port.default(3306)
        
        # Backup and maintenance
        attribute :backup, BackupConfig.default({})
        attribute :maintenance, MaintenanceConfig.default({})
        
        # Monitoring and logging
        attribute :monitoring, MonitoringConfig.default({})
        attribute :enabled_cloudwatch_logs_exports, Types::Array.of(Types::String).default([
          "error", "general", "slow_query"
        ].freeze)
        
        # Parameter group
        attribute :parameter_config, ParameterConfig.default({})
        
        # Deletion protection
        attribute :deletion_protection, Types::Bool.default(true)
        
        # Read replicas
        attribute :create_read_replica, Types::Bool.default(false)
        attribute :read_replica_count, Types::Integer.default(1).constrained(gteq: 1, lteq: 15)
        attribute :read_replica_instance_class, Types::RdsInstanceClass.optional
        
        # Blue/Green deployment
        attribute :blue_green_update, Types::Hash.optional
        
        # Common tags
        attribute :tags, Types::AwsTags.default({}.freeze)
        
        # Network and security
        attribute :db_subnet_group_name, Types::String.optional
        attribute :vpc_security_group_ids, Types::Array.of(Types::String).optional
        
        # Character set and collation
        attribute :character_set_name, Types::String.optional.enum('utf8', 'utf8mb4', 'latin1', 'ascii')
        
        # Options group
        attribute :option_group_name, Types::String.optional
        
        # Restore configuration
        attribute :restore_from_snapshot, Types::Bool.default(false)
        attribute :snapshot_identifier, Types::String.optional
        attribute :restore_to_point_in_time, Types::Hash.optional
        
        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate max_allocated_storage is greater than allocated_storage
          if attrs.max_allocated_storage && attrs.max_allocated_storage <= attrs.allocated_storage
            raise Dry::Types::ConstraintError, "max_allocated_storage must be greater than allocated_storage"
          end
          
          # Validate IOPS requirements for io1/io2 storage types
          if ['io1', 'io2'].include?(attrs.storage_type) && !attrs.iops
            raise Dry::Types::ConstraintError, "IOPS must be specified for #{attrs.storage_type} storage type"
          end
          
          # Validate gp3 throughput
          if attrs.storage_type == 'gp3' && attrs.storage_throughput
            min_throughput = [125, attrs.iops&./(4) || 125].max
            max_throughput = [4000, attrs.iops&.*(4) || 4000].min
            unless (min_throughput..max_throughput).include?(attrs.storage_throughput)
              raise Dry::Types::ConstraintError, "gp3 throughput must be between #{min_throughput} and #{max_throughput} MB/s"
            end
          end
          
          # Validate backup retention for point-in-time recovery
          if attrs.backup.backup_retention_period == 0 && attrs.restore_to_point_in_time
            raise Dry::Types::ConstraintError, "Point-in-time recovery requires backup_retention_period > 0"
          end
          
          # Validate Multi-AZ requirements
          if attrs.multi_az && attrs.availability_zone
            raise Dry::Types::ConstraintError, "Cannot specify availability_zone with multi_az enabled"
          end
          
          attrs
        end
      end
    end
  end
end