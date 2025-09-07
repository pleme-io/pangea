# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Serverless v2 scaling configuration for Aurora clusters
      class ServerlessV2Scaling < Dry::Struct
        # Minimum Aurora capacity units (0.5 - 128)
        attribute :min_capacity, Resources::Types::Float.constrained(gteq: 0.5, lteq: 128)

        # Maximum Aurora capacity units (0.5 - 128)  
        attribute :max_capacity, Resources::Types::Float.constrained(gteq: 0.5, lteq: 128)

        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate min <= max
          if attrs.min_capacity > attrs.max_capacity
            raise Dry::Struct::Error, "min_capacity (#{attrs.min_capacity}) cannot be greater than max_capacity (#{attrs.max_capacity})"
          end

          attrs
        end

        # Check if this is a minimal scaling configuration
        def is_minimal?
          min_capacity <= 1.0 && max_capacity <= 2.0
        end

        # Check if this is a high-performance scaling configuration  
        def is_high_performance?
          max_capacity >= 16.0
        end

        # Calculate scaling range
        def scaling_range
          max_capacity - min_capacity
        end

        # Estimate hourly cost range (rough AWS pricing)
        def estimated_hourly_cost_range
          min_cost = min_capacity * 0.12  # ~$0.12 per ACU hour
          max_cost = max_capacity * 0.12
          "$#{min_cost.round(2)}-#{max_cost.round(2)}/hour"
        end
      end

      # Restore configuration for point-in-time recovery
      class RestoreToPointInTime < Dry::Struct
        # Source cluster identifier to restore from
        attribute :source_cluster_identifier, Resources::Types::String.optional

        # Point in time to restore to (ISO 8601 format)
        attribute :restore_to_time, Resources::Types::String.optional

        # Use latest restorable time
        attribute :use_latest_restorable_time, Resources::Types::Bool.default(false)

        # Restore type (full-copy, copy-on-write)
        attribute :restore_type, Resources::Types::String.optional.constrained(included_in: ["full-copy", "copy-on-write"])

        def self.new(attributes = {})
          attrs = super(attributes)

          # Must specify either restore_to_time or use_latest_restorable_time
          if !attrs.use_latest_restorable_time && !attrs.restore_to_time
            raise Dry::Struct::Error, "Must specify either 'restore_to_time' or set 'use_latest_restorable_time' to true"
          end

          # Cannot specify both
          if attrs.use_latest_restorable_time && attrs.restore_to_time
            raise Dry::Struct::Error, "Cannot specify both 'restore_to_time' and 'use_latest_restorable_time'"
          end

          # Source cluster required
          unless attrs.source_cluster_identifier
            raise Dry::Struct::Error, "source_cluster_identifier is required for point-in-time restore"
          end

          attrs
        end

        # Check if using latest restorable time
        def uses_latest_time?
          use_latest_restorable_time
        end

        # Check if using specific time
        def uses_specific_time?
          !restore_to_time.nil?
        end
      end

      # Type-safe attributes for AWS RDS Cluster resources
      class RdsClusterAttributes < Dry::Struct
        # Cluster identifier (optional, AWS will generate if not provided)
        attribute :cluster_identifier, Resources::Types::String.optional

        # Cluster identifier prefix (alternative to cluster_identifier)
        attribute :cluster_identifier_prefix, Resources::Types::String.optional

        # Database engine (Aurora only)
        attribute :engine, Resources::Types::String.constrained(included_in: [
          "aurora", "aurora-mysql", "aurora-postgresql"
        ])

        # Engine version (optional, uses default for engine if not specified)
        attribute :engine_version, Resources::Types::String.optional

        # Engine mode (provisioned, serverless, parallelquery, global)
        attribute :engine_mode, Resources::Types::String.default("provisioned").constrained(included_in: [
          "provisioned", "serverless", "parallelquery", "global"
        ])

        # Database name (optional)
        attribute :database_name, Resources::Types::String.optional

        # Master username (optional when using snapshots or point-in-time restore)
        attribute :master_username, Resources::Types::String.optional

        # Master password (use manage_master_user_password instead for security)
        attribute :master_password, Resources::Types::String.optional

        # Let AWS manage the master password
        attribute :manage_master_user_password, Resources::Types::Bool.default(true)

        # Master user secret KMS key
        attribute :master_user_secret_kms_key_id, Resources::Types::String.optional

        # Network configuration
        attribute :db_subnet_group_name, Resources::Types::String.optional
        attribute :vpc_security_group_ids, Resources::Types::Array.of(Types::String).default([].freeze)
        attribute :availability_zones, Resources::Types::Array.of(Types::String).optional
        attribute :db_cluster_parameter_group_name, Resources::Types::String.optional

        # Port (optional, uses engine default)
        attribute :port, Resources::Types::Integer.optional

        # Backup configuration
        attribute :backup_retention_period, Resources::Types::Integer.default(7).constrained(gteq: 1, lteq: 35)
        attribute :preferred_backup_window, Resources::Types::String.optional  # Format: "hh24:mi-hh24:mi"
        attribute :preferred_maintenance_window, Resources::Types::String.optional  # Format: "ddd:hh24:mi-ddd:hh24:mi"

        # Copy tags to snapshots
        attribute :copy_tags_to_snapshot, Resources::Types::Bool.default(true)

        # Storage configuration
        attribute :storage_encrypted, Resources::Types::Bool.default(true)
        attribute :kms_key_id, Resources::Types::String.optional
        attribute :storage_type, Resources::Types::String.optional
        attribute :allocated_storage, Resources::Types::Integer.optional
        attribute :iops, Resources::Types::Integer.optional

        # Global cluster configuration
        attribute :global_cluster_identifier, Resources::Types::String.optional

        # Serverless v1 scaling (deprecated, use serverless_v2_scaling_configuration)
        attribute :scaling_configuration, Resources::Types::Hash.optional

        # Serverless v2 scaling configuration
        attribute? :serverless_v2_scaling_configuration, ServerlessV2Scaling.optional

        # Point-in-time restore configuration
        attribute? :restore_to_point_in_time, RestoreToPointInTime.optional

        # Snapshot restore
        attribute :snapshot_identifier, Resources::Types::String.optional
        attribute :source_region, Resources::Types::String.optional

        # Monitoring and logging
        attribute :enabled_cloudwatch_logs_exports, Resources::Types::Array.of(Types::String).default([].freeze)
        attribute :monitoring_interval, Resources::Types::Integer.default(0).constrained(gteq: 0, lteq: 60)
        attribute :monitoring_role_arn, Resources::Types::String.optional
        attribute :performance_insights_enabled, Resources::Types::Bool.default(false)
        attribute :performance_insights_kms_key_id, Resources::Types::String.optional
        attribute :performance_insights_retention_period, Resources::Types::Integer.default(7).constrained(gteq: 7, lteq: 731)

        # Backtrack configuration (Aurora MySQL only)
        attribute :backtrack_window, Resources::Types::Integer.optional.constrained(gteq: 0, lteq: 259200)

        # Additional options
        attribute :apply_immediately, Resources::Types::Bool.default(false)
        attribute :auto_minor_version_upgrade, Resources::Types::Bool.default(true)
        attribute :deletion_protection, Resources::Types::Bool.default(false)
        attribute :skip_final_snapshot, Resources::Types::Bool.default(false)
        attribute :final_snapshot_identifier, Resources::Types::String.optional

        # Enable HTTP endpoint (for Aurora Serverless)
        attribute :enable_http_endpoint, Resources::Types::Bool.default(false)

        # Tags to apply to the cluster
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Cannot specify both cluster_identifier and cluster_identifier_prefix
          if attrs.cluster_identifier && attrs.cluster_identifier_prefix
            raise Dry::Struct::Error, "Cannot specify both 'cluster_identifier' and 'cluster_identifier_prefix'"
          end

          # Password security validation
          if attrs.master_password && attrs.manage_master_user_password
            raise Dry::Struct::Error, "Cannot specify both 'master_password' and 'manage_master_user_password'"
          end

          # Serverless v1 and v2 cannot be used together
          if attrs.scaling_configuration && attrs.serverless_v2_scaling_configuration
            raise Dry::Struct::Error, "Cannot specify both 'scaling_configuration' and 'serverless_v2_scaling_configuration'"
          end

          # Serverless configurations only valid for serverless engine mode
          if attrs.engine_mode != "serverless" && (attrs.scaling_configuration || attrs.enable_http_endpoint)
            raise Dry::Struct::Error, "Serverless configurations only valid when engine_mode is 'serverless'"
          end

          # Backtrack only supported by Aurora MySQL
          if attrs.backtrack_window && !attrs.engine.include?("mysql")
            raise Dry::Struct::Error, "Backtrack is only supported by Aurora MySQL clusters"
          end

          # Global cluster validations
          if attrs.global_cluster_identifier && attrs.engine_mode != "global"
            raise Dry::Struct::Error, "global_cluster_identifier can only be used with engine_mode 'global'"
          end

          # Monitoring role required for enhanced monitoring
          if attrs.monitoring_interval > 0 && !attrs.monitoring_role_arn
            raise Dry::Struct::Error, "monitoring_role_arn is required when monitoring_interval > 0"
          end

          # Performance insights retention validation
          if attrs.performance_insights_enabled && attrs.performance_insights_retention_period < 7
            raise Dry::Struct::Error, "performance_insights_retention_period must be at least 7 days when Performance Insights is enabled"
          end

          # Final snapshot validation
          if !attrs.skip_final_snapshot && !attrs.final_snapshot_identifier
            raise Dry::Struct::Error, "final_snapshot_identifier is required when skip_final_snapshot is false"
          end

          # Storage configuration validation for provisioned clusters
          if attrs.engine_mode == "provisioned" && attrs.storage_type == "io1" && !attrs.iops
            raise Dry::Struct::Error, "iops must be specified when storage_type is 'io1'"
          end

          attrs
        end

        # Get the database engine family
        def engine_family
          case engine
          when "aurora-mysql", "aurora"
            "mysql"
          when "aurora-postgresql"
            "postgresql"
          else
            engine
          end
        end

        # Check if this is a MySQL-based Aurora cluster
        def is_mysql?
          engine.include?("mysql") || engine == "aurora"
        end

        # Check if this is a PostgreSQL-based Aurora cluster
        def is_postgresql?
          engine.include?("postgresql")
        end

        # Check if this is a serverless cluster
        def is_serverless?
          engine_mode == "serverless"
        end

        # Check if this is a global cluster
        def is_global?
          engine_mode == "global" || !global_cluster_identifier.nil?
        end

        # Check if enhanced monitoring is enabled
        def has_enhanced_monitoring?
          monitoring_interval > 0
        end

        # Check if Performance Insights is enabled
        def has_performance_insights?
          performance_insights_enabled
        end

        # Check if backtrack is enabled
        def has_backtrack?
          backtrack_window && backtrack_window > 0
        end

        # Check if HTTP endpoint is enabled
        def has_http_endpoint?
          enable_http_endpoint
        end

        # Get the effective port based on engine
        def effective_port
          return port if port

          case engine
          when "aurora-mysql", "aurora"
            3306
          when "aurora-postgresql"
            5432
          else
            3306  # Default
          end
        end

        # Get default CloudWatch logs exports for engine
        def default_cloudwatch_logs_exports
          case engine
          when "aurora-mysql", "aurora"
            ["audit", "error", "general", "slowquery"]
          when "aurora-postgresql"
            ["postgresql"]
          else
            []
          end
        end

        # Check if cluster supports backtrack
        def supports_backtrack?
          is_mysql? && engine_mode == "provisioned"
        end

        # Check if cluster supports global databases
        def supports_global?
          engine_mode == "provisioned"
        end

        # Check if cluster supports serverless v2
        def supports_serverless_v2?
          engine_mode == "provisioned"
        end

        # Estimate monthly cost (very rough estimate)
        def estimated_monthly_cost
          if is_serverless?
            if serverless_v2_scaling_configuration
              cost_range = serverless_v2_scaling_configuration.estimated_hourly_cost_range
              "#{cost_range} (730 hours/month)"
            else
              "~$20-200/month (Aurora Serverless v1)"
            end
          else
            # Provisioned clusters depend on instance configuration
            "Depends on cluster instances (see aws_rds_cluster_instance costs)"
          end
        end
      end

      # Common Aurora cluster configurations
      module AuroraClusterConfigs
        # Development Aurora MySQL cluster
        def self.mysql_development
          {
            engine: "aurora-mysql",
            engine_mode: "provisioned",
            backup_retention_period: 1,
            skip_final_snapshot: true,
            deletion_protection: false,
            enabled_cloudwatch_logs_exports: ["slowquery"],
            tags: { Environment: "development", Engine: "aurora-mysql" }
          }
        end

        # Production Aurora MySQL cluster
        def self.mysql_production
          {
            engine: "aurora-mysql",
            engine_mode: "provisioned",
            backup_retention_period: 14,
            skip_final_snapshot: false,
            deletion_protection: true,
            enabled_cloudwatch_logs_exports: ["audit", "error", "general", "slowquery"],
            performance_insights_enabled: true,
            monitoring_interval: 60,
            backtrack_window: 259200,  # 72 hours
            tags: { Environment: "production", Engine: "aurora-mysql" }
          }
        end

        # Aurora PostgreSQL development
        def self.postgresql_development
          {
            engine: "aurora-postgresql",
            engine_mode: "provisioned",
            backup_retention_period: 1,
            skip_final_snapshot: true,
            deletion_protection: false,
            enabled_cloudwatch_logs_exports: ["postgresql"],
            tags: { Environment: "development", Engine: "aurora-postgresql" }
          }
        end

        # Aurora PostgreSQL production
        def self.postgresql_production
          {
            engine: "aurora-postgresql",
            engine_mode: "provisioned",
            backup_retention_period: 14,
            skip_final_snapshot: false,
            deletion_protection: true,
            enabled_cloudwatch_logs_exports: ["postgresql"],
            performance_insights_enabled: true,
            monitoring_interval: 60,
            tags: { Environment: "production", Engine: "aurora-postgresql" }
          }
        end

        # Aurora Serverless v2 configuration
        def self.serverless_v2(min_capacity: 0.5, max_capacity: 16.0)
          {
            engine: "aurora-mysql",
            engine_mode: "provisioned",
            serverless_v2_scaling_configuration: {
              min_capacity: min_capacity,
              max_capacity: max_capacity
            },
            tags: { ServerlessVersion: "v2" }
          }
        end

        # Global Aurora cluster configuration
        def self.global_mysql
          {
            engine: "aurora-mysql",
            engine_mode: "global",
            backup_retention_period: 14,
            deletion_protection: true,
            tags: { ClusterType: "global", Engine: "aurora-mysql" }
          }
        end
      end
    end
      end
    end
  end
end