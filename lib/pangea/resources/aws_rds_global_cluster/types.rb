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
      # Global cluster configuration for automated backups
      class GlobalClusterBackupConfiguration < Dry::Struct
        # Backup retention period in days (7-35 for global clusters)
        attribute :backup_retention_period, Resources::Types::Integer.default(7).constrained(gteq: 7, lteq: 35)

        # Preferred backup window (UTC format: "hh24:mi-hh24:mi")
        attribute :preferred_backup_window, Resources::Types::String.optional

        # Whether to copy tags to snapshots
        attribute :copy_tags_to_snapshot, Resources::Types::Bool.default(true)

        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate backup window format if provided
          if attrs.preferred_backup_window && !valid_backup_window?(attrs.preferred_backup_window)
            raise Dry::Struct::Error, "preferred_backup_window must be in format 'hh24:mi-hh24:mi' (UTC)"
          end

          attrs
        end

        private

        def self.valid_backup_window?(window)
          return false unless window.match?(/^\d{2}:\d{2}-\d{2}:\d{2}$/)
          
          start_time, end_time = window.split('-')
          start_hour, start_min = start_time.split(':').map(&:to_i)
          end_hour, end_min = end_time.split(':').map(&:to_i)

          # Validate time components
          return false if start_hour > 23 || start_min > 59 || end_hour > 23 || end_min > 59
          
          # Window must be at least 30 minutes
          start_minutes = start_hour * 60 + start_min
          end_minutes = end_hour * 60 + end_min
          end_minutes += 24 * 60 if end_minutes <= start_minutes # Handle overnight window
          
          (end_minutes - start_minutes) >= 30
        end

        # Check if backup window spans midnight
        def spans_midnight?
          return false unless preferred_backup_window
          
          start_time, end_time = preferred_backup_window.split('-')
          start_hour = start_time.split(':').first.to_i
          end_hour = end_time.split(':').first.to_i
          
          end_hour <= start_hour
        end

        # Get backup window duration in minutes
        def window_duration_minutes
          return nil unless preferred_backup_window
          
          start_time, end_time = preferred_backup_window.split('-')
          start_hour, start_min = start_time.split(':').map(&:to_i)
          end_hour, end_min = end_time.split(':').map(&:to_i)

          start_minutes = start_hour * 60 + start_min
          end_minutes = end_hour * 60 + end_min
          end_minutes += 24 * 60 if end_minutes <= start_minutes
          
          end_minutes - start_minutes
        end
      end

      # Type-safe attributes for AWS RDS Global Cluster resources
      class RdsGlobalClusterAttributes < Dry::Struct
        # Global cluster identifier (optional, AWS will generate if not provided)
        attribute :global_cluster_identifier, Resources::Types::String.optional

        # Database engine (Aurora only)
        attribute :engine, Resources::Types::String.enum("aurora", "aurora-mysql", "aurora-postgresql")

        # Engine version (optional, uses latest if not specified)
        attribute :engine_version, Resources::Types::String.optional

        # Database name (created in primary cluster)
        attribute :database_name, Resources::Types::String.optional

        # Master username for the global cluster
        attribute :master_username, Resources::Types::String.optional

        # Master password (use manage_master_user_password for security)
        attribute :master_password, Resources::Types::String.optional

        # Let AWS manage the master password
        attribute :manage_master_user_password, Resources::Types::Bool.default(true)

        # Master user secret KMS key ID
        attribute :master_user_secret_kms_key_id, Resources::Types::String.optional

        # Storage encryption configuration
        attribute :storage_encrypted, Resources::Types::Bool.default(true)

        # KMS key ID for storage encryption
        attribute :kms_key_id, Resources::Types::String.optional

        # Force destroy the global cluster (delete protection override)
        attribute :force_destroy, Resources::Types::Bool.default(false)

        # Source DB cluster identifier (for creating from existing cluster)
        attribute :source_db_cluster_identifier, Resources::Types::String.optional

        # Engine lifecycle support setting
        attribute :engine_lifecycle_support, Resources::Types::String.enum("open-source-rds-extended-support", "open-source-rds-extended-support-disabled").optional

        # Global cluster backup configuration
        attribute? :backup_configuration, GlobalClusterBackupConfiguration.optional

        # Tags to apply to the global cluster
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Password management validation
          if attrs.master_password && attrs.manage_master_user_password
            raise Dry::Struct::Error, "Cannot specify both 'master_password' and 'manage_master_user_password'"
          end

          # Source cluster validation
          if attrs.source_db_cluster_identifier
            # When using source cluster, some parameters are inherited
            if attrs.database_name || attrs.master_username || attrs.master_password
              raise Dry::Struct::Error, "database_name, master_username, and master_password are inherited from source cluster"
            end
          else
            # When not using source cluster, require username
            unless attrs.master_username
              raise Dry::Struct::Error, "master_username is required when not using source_db_cluster_identifier"
            end
          end

          # Engine version validation
          if attrs.engine_version && !valid_engine_version?(attrs.engine, attrs.engine_version)
            raise Dry::Struct::Error, "Invalid engine version '#{attrs.engine_version}' for engine '#{attrs.engine}'"
          end

          attrs
        end

        # Validate engine version compatibility
        def self.valid_engine_version?(engine, version)
          case engine
          when "aurora", "aurora-mysql"
            # Aurora MySQL versions
            version.match?(/^(5\.7|8\.0)\.mysql_aurora\.\d+\.\d+\.\d+$/)
          when "aurora-postgresql"
            # Aurora PostgreSQL versions
            version.match?(/^\d{1,2}\.\d+$/)
          else
            false
          end
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

        # Check if this is a MySQL-based global cluster
        def is_mysql?
          engine.include?("mysql") || engine == "aurora"
        end

        # Check if this is a PostgreSQL-based global cluster
        def is_postgresql?
          engine.include?("postgresql")
        end

        # Check if using managed password
        def uses_managed_password?
          manage_master_user_password
        end

        # Check if created from source cluster
        def created_from_source?
          !source_db_cluster_identifier.nil?
        end

        # Check if storage is encrypted
        def is_encrypted?
          storage_encrypted
        end

        # Check if force destroy is enabled
        def allows_force_destroy?
          force_destroy
        end

        # Check if backup configuration is specified
        def has_backup_configuration?
          !backup_configuration.nil?
        end

        # Get effective backup retention period
        def effective_backup_retention_period
          backup_configuration&.backup_retention_period || 7
        end

        # Get effective backup window
        def effective_backup_window
          backup_configuration&.preferred_backup_window || "03:00-04:00" # Default UTC window
        end

        # Get engine major version
        def engine_major_version
          case engine
          when "aurora", "aurora-mysql"
            engine_version&.match(/^(\d+\.\d+)/)&.[](1) || "8.0"
          when "aurora-postgresql"
            engine_version&.match(/^(\d{1,2})/)&.[](1) || "14"
          else
            "unknown"
          end
        end

        # Get supported regions for global cluster
        def supported_regions
          # Global clusters support most commercial AWS regions
          %w[
            us-east-1 us-east-2 us-west-1 us-west-2
            ca-central-1
            eu-west-1 eu-west-2 eu-west-3 eu-central-1 eu-north-1
            ap-northeast-1 ap-northeast-2 ap-southeast-1 ap-southeast-2
            ap-south-1 sa-east-1
          ]
        end

        # Check if region supports global clusters
        def supports_region?(region)
          supported_regions.include?(region)
        end

        # Estimate monthly cost (global clusters have additional charges)
        def estimated_monthly_cost
          base_cost = case engine_family
                     when "mysql"
                       "~$100-500/month per region (depends on instance sizes)"
                     when "postgresql"
                       "~$120-600/month per region (depends on instance sizes)"
                     else
                       "Varies by engine and instance configuration"
                     end
          
          "#{base_cost} + cross-region data transfer costs"
        end

        # Generate configuration summary
        def configuration_summary
          summary = [
            "Engine: #{engine_family}",
            "Regions: Global (multi-region)",
            "Encryption: #{is_encrypted? ? 'enabled' : 'disabled'}"
          ]

          if created_from_source?
            summary << "Source: #{source_db_cluster_identifier}"
          end

          if has_backup_configuration?
            summary << "Backup: #{effective_backup_retention_period} days"
          end

          summary.join("; ")
        end

        # Get recommended secondary regions based on primary
        def recommended_secondary_regions(primary_region)
          case primary_region
          when "us-east-1"
            ["us-west-2", "eu-west-1"]
          when "us-west-2"
            ["us-east-1", "eu-west-1"]
          when "eu-west-1"
            ["us-east-1", "ap-northeast-1"]
          when "ap-northeast-1"
            ["us-west-2", "eu-west-1"]
          else
            # Generic recommendations
            ["us-east-1", "us-west-2", "eu-west-1"].reject { |r| r == primary_region }
          end
        end
      end

      # Common RDS Global Cluster configurations
      module RdsGlobalClusterConfigs
        # Production global cluster with high availability
        def self.production_mysql(identifier: nil)
          {
            global_cluster_identifier: identifier,
            engine: "aurora-mysql",
            engine_version: "8.0.mysql_aurora.3.02.0",
            storage_encrypted: true,
            manage_master_user_password: true,
            backup_configuration: {
              backup_retention_period: 14,
              preferred_backup_window: "03:00-04:00",
              copy_tags_to_snapshot: true
            },
            tags: { Environment: "production", Engine: "mysql", Type: "global" }
          }
        end

        # Production PostgreSQL global cluster
        def self.production_postgresql(identifier: nil)
          {
            global_cluster_identifier: identifier,
            engine: "aurora-postgresql",
            engine_version: "14.9",
            storage_encrypted: true,
            manage_master_user_password: true,
            backup_configuration: {
              backup_retention_period: 14,
              preferred_backup_window: "02:00-03:00",
              copy_tags_to_snapshot: true
            },
            tags: { Environment: "production", Engine: "postgresql", Type: "global" }
          }
        end

        # Development global cluster with minimal retention
        def self.development(engine: "aurora-mysql", identifier: nil)
          base_config = {
            global_cluster_identifier: identifier,
            engine: engine,
            storage_encrypted: true,
            manage_master_user_password: true,
            force_destroy: true,
            backup_configuration: {
              backup_retention_period: 7,
              preferred_backup_window: "05:00-06:00",
              copy_tags_to_snapshot: false
            },
            tags: { Environment: "development", Type: "global", Purpose: "testing" }
          }

          case engine
          when "aurora-mysql", "aurora"
            base_config.merge(engine_version: "8.0.mysql_aurora.3.02.0")
          when "aurora-postgresql"
            base_config.merge(engine_version: "14.9")
          else
            base_config
          end
        end

        # Disaster recovery global cluster
        def self.disaster_recovery(primary_region:, engine: "aurora-mysql")
          {
            engine: engine,
            storage_encrypted: true,
            manage_master_user_password: true,
            backup_configuration: {
              backup_retention_period: 35, # Maximum retention for DR
              preferred_backup_window: "04:00-05:00",
              copy_tags_to_snapshot: true
            },
            tags: { 
              Purpose: "disaster-recovery", 
              PrimaryRegion: primary_region,
              Type: "global",
              Recovery: "cross-region"
            }
          }
        end

        # Global cluster from existing cluster
        def self.from_existing_cluster(source_cluster_identifier:, engine: "aurora-mysql")
          {
            engine: engine,
            source_db_cluster_identifier: source_cluster_identifier,
            storage_encrypted: true,
            backup_configuration: {
              backup_retention_period: 14,
              preferred_backup_window: "03:00-04:00",
              copy_tags_to_snapshot: true
            },
            tags: { 
              Source: "existing-cluster",
              Type: "global",
              Migration: "cluster-to-global"
            }
          }
        end
      end
    end
      end
    end
  end
end