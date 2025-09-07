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
      # Type-safe attributes for AWS RDS Database Instance resources
      class DbInstanceAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Database identifier (optional, AWS will generate if not provided)
        attribute :identifier, Resources::Types::String.optional

        # Database identifier prefix (optional, alternative to identifier)
        attribute :identifier_prefix, Resources::Types::String.optional

        # Database engine
        attribute :engine, Resources::Types::String.enum(
          "mysql", "postgres", "mariadb", "oracle-se", "oracle-se1", "oracle-se2", 
          "oracle-ee", "sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web",
          "aurora", "aurora-mysql", "aurora-postgresql"
        )

        # Engine version (optional, uses default for engine if not specified)
        attribute :engine_version, Resources::Types::String.optional

        # Instance class (e.g., "db.t3.micro", "db.r5.large")
        attribute :instance_class, Resources::Types::String

        # Allocated storage in GB (not used for Aurora)
        attribute :allocated_storage, Resources::Types::Integer.optional.constrained(gteq: 20, lteq: 65536)

        # Storage type
        attribute :storage_type, Resources::Types::String.default("gp3").enum("standard", "gp2", "gp3", "io1", "io2")

        # Storage encryption
        attribute :storage_encrypted, Resources::Types::Bool.default(true)

        # KMS key for encryption
        attribute :kms_key_id, Resources::Types::String.optional

        # IOPS (only for io1/io2 storage types)
        attribute :iops, Resources::Types::Integer.optional.constrained(gteq: 1000, lteq: 256000)

        # Database name (optional, not applicable for SQL Server)
        attribute :db_name, Resources::Types::String.optional

        # Master username
        attribute :username, Resources::Types::String.optional

        # Master password (use manage_master_user_password instead for security)
        attribute :password, Resources::Types::String.optional

        # Let AWS manage the master password
        attribute :manage_master_user_password, Resources::Types::Bool.default(true)

        # Network configuration
        attribute :db_subnet_group_name, Resources::Types::String.optional
        attribute :vpc_security_group_ids, Resources::Types::Array.of(Types::String).default([].freeze)
        attribute :availability_zone, Resources::Types::String.optional
        attribute :multi_az, Resources::Types::Bool.default(false)
        attribute :publicly_accessible, Resources::Types::Bool.default(false)

        # Backup configuration
        attribute :backup_retention_period, Resources::Types::Integer.default(7).constrained(gteq: 0, lteq: 35)
        attribute :backup_window, Resources::Types::String.optional  # Format: "hh24:mi-hh24:mi"
        attribute :maintenance_window, Resources::Types::String.optional  # Format: "ddd:hh24:mi-ddd:hh24:mi"

        # Performance and monitoring
        attribute :enabled_cloudwatch_logs_exports, Resources::Types::Array.of(Types::String).default([].freeze)
        attribute :performance_insights_enabled, Resources::Types::Bool.default(false)
        attribute :performance_insights_retention_period, Resources::Types::Integer.default(7)

        # Additional options
        attribute :auto_minor_version_upgrade, Resources::Types::Bool.default(true)
        attribute :deletion_protection, Resources::Types::Bool.default(false)
        attribute :skip_final_snapshot, Resources::Types::Bool.default(true)
        attribute :final_snapshot_identifier, Resources::Types::String.optional

        # Tags to apply to the database
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Cannot specify both identifier and identifier_prefix
          if attrs.identifier && attrs.identifier_prefix
            raise Dry::Struct::Error, "Cannot specify both 'identifier' and 'identifier_prefix'"
          end

          # IOPS only valid for io1/io2 storage types
          if attrs.iops && !%w[io1 io2].include?(attrs.storage_type)
            raise Dry::Struct::Error, "IOPS can only be specified for io1 or io2 storage types"
          end

          # Password security validation
          if attrs.password && attrs.manage_master_user_password
            raise Dry::Struct::Error, "Cannot specify both 'password' and 'manage_master_user_password'"
          end

          # Aurora validations
          if attrs.engine.start_with?("aurora")
            if attrs.allocated_storage
              raise Dry::Struct::Error, "Aurora engines do not support 'allocated_storage' - use cluster configuration instead"
            end
            if attrs.multi_az
              raise Dry::Struct::Error, "Aurora engines handle multi-AZ at the cluster level, not instance level"
            end
          else
            # Non-Aurora engines require allocated_storage
            if attrs.allocated_storage.nil?
              raise Dry::Struct::Error, "Non-Aurora engines require 'allocated_storage' to be specified"
            end
          end

          # SQL Server doesn't support db_name
          if attrs.engine.start_with?("sqlserver") && attrs.db_name
            raise Dry::Struct::Error, "SQL Server engines do not support 'db_name' parameter"
          end

          attrs
        end

        # Helper method to get engine family
        def engine_family
          case engine
          when /mysql/, /aurora-mysql/
            "mysql"
          when /postgres/, /aurora-postgresql/
            "postgresql"
          when /mariadb/
            "mariadb"
          when /oracle/
            "oracle"
          when /sqlserver/
            "sqlserver"
          else
            engine
          end
        end

        # Check if this is an Aurora engine
        def is_aurora?
          engine.start_with?("aurora")
        end

        # Check if this is a serverless instance
        def is_serverless?
          instance_class.include?("serverless")
        end

        # Check if subnet group is required
        def requires_subnet_group?
          !publicly_accessible || vpc_security_group_ids.any?
        end

        # Check if encryption is supported
        def supports_encryption?
          # All modern RDS engines support encryption
          true
        end

        # Estimate monthly cost (very rough estimate)
        def estimated_monthly_cost
          # Base hourly rates (simplified)
          hourly_rate = case instance_class
                       when /t3.micro/ then 0.017
                       when /t3.small/ then 0.034
                       when /t3.medium/ then 0.068
                       when /t3.large/ then 0.136
                       when /m5.large/ then 0.171
                       when /m5.xlarge/ then 0.342
                       when /r5.large/ then 0.250
                       when /r5.xlarge/ then 0.500
                       else 0.100  # Default estimate
                       end

          # Storage cost estimate ($0.10 per GB-month for gp3)
          storage_cost = allocated_storage ? allocated_storage * 0.10 : 0

          # Multi-AZ doubles the cost
          if multi_az
            hourly_rate *= 2
          end

          # Monthly cost (730 hours)
          compute_cost = hourly_rate * 730
          total_cost = compute_cost + storage_cost

          "~$#{total_cost.round(2)}/month"
        end
      end

      # Common RDS engine configurations
      module RdsEngineConfigs
        # MySQL default configuration
        def self.mysql(version: "8.0")
          {
            engine: "mysql",
            engine_version: version,
            enabled_cloudwatch_logs_exports: ["error", "general", "slowquery"]
          }
        end

        # PostgreSQL default configuration
        def self.postgresql(version: "15")
          {
            engine: "postgres",
            engine_version: version,
            enabled_cloudwatch_logs_exports: ["postgresql"]
          }
        end

        # Aurora MySQL configuration
        def self.aurora_mysql(version: "8.0.mysql_aurora.3.02.0")
          {
            engine: "aurora-mysql",
            engine_version: version
          }
        end

        # Aurora PostgreSQL configuration
        def self.aurora_postgresql(version: "15.2")
          {
            engine: "aurora-postgresql",
            engine_version: version
          }
        end

        # MariaDB configuration
        def self.mariadb(version: "10.11")
          {
            engine: "mariadb",
            engine_version: version,
            enabled_cloudwatch_logs_exports: ["error", "general", "slowquery"]
          }
        end
      end
    end
      end
    end
  end
end