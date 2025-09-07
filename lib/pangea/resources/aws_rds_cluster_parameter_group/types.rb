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
      # Database parameter configuration
      class DbParameter < Dry::Struct
        # Parameter name
        attribute :name, Resources::Types::String

        # Parameter value (can be string, number, or boolean)
        attribute :value, Resources::Types::String | Types::Integer | Types::Float | Types::Bool

        # Apply method for parameter changes (immediate or pending-reboot)
        attribute :apply_method, Resources::Types::String.enum("immediate", "pending-reboot").default("pending-reboot")

        def self.new(attributes = {})
          attrs = super(attributes)

          # Convert non-string values to strings for Terraform
          if attrs.value.is_a?(TrueClass) || attrs.value.is_a?(FalseClass)
            attrs = attrs.copy(value: attrs.value ? "1" : "0")
          elsif attrs.value.is_a?(Numeric)
            attrs = attrs.copy(value: attrs.value.to_s)
          end

          attrs
        end

        # Get the parameter value as a string (Terraform format)
        def terraform_value
          value.to_s
        end

        # Check if parameter requires immediate application
        def requires_immediate_application?
          apply_method == "immediate"
        end

        # Check if parameter requires reboot
        def requires_reboot?
          apply_method == "pending-reboot"
        end
      end

      # Type-safe attributes for AWS RDS Cluster Parameter Group resources
      class RdsClusterParameterGroupAttributes < Dry::Struct
        # Parameter group name (optional, AWS will generate if not provided)
        attribute :name, Resources::Types::String.optional

        # Parameter group name prefix (alternative to name)  
        attribute :name_prefix, Resources::Types::String.optional

        # Database engine family (e.g., aurora-mysql5.7, aurora-postgresql11)
        attribute :family, Resources::Types::String.enum(
          # Aurora MySQL families
          "aurora-mysql5.7", "aurora-mysql8.0",
          # Aurora PostgreSQL families  
          "aurora-postgresql10", "aurora-postgresql11", "aurora-postgresql12",
          "aurora-postgresql13", "aurora-postgresql14", "aurora-postgresql15"
        )

        # Description of the parameter group
        attribute :description, Resources::Types::String

        # Database parameters to configure
        attribute :parameter, Resources::Types::Array.of(DbParameter).default([].freeze)

        # Tags to apply to the parameter group
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Cannot specify both name and name_prefix
          if attrs.name && attrs.name_prefix
            raise Dry::Struct::Error, "Cannot specify both 'name' and 'name_prefix'"
          end

          # Parameter name validation - no duplicates
          parameter_names = attrs.parameter.map(&:name)
          duplicates = parameter_names.select { |name| parameter_names.count(name) > 1 }.uniq
          if duplicates.any?
            raise Dry::Struct::Error, "Duplicate parameter names found: #{duplicates.join(', ')}"
          end

          # Validate parameter names for family
          invalid_params = validate_parameters_for_family(attrs.family, attrs.parameter)
          if invalid_params.any?
            raise Dry::Struct::Error, "Invalid parameters for family '#{attrs.family}': #{invalid_params.join(', ')}"
          end

          attrs
        end

        # Validate parameters are appropriate for the database engine family
        def self.validate_parameters_for_family(family, parameters)
          invalid = []
          
          parameters.each do |param|
            case family
            when /^aurora-mysql/
              unless AURORA_MYSQL_PARAMETERS.include?(param.name)
                invalid << param.name
              end
            when /^aurora-postgresql/
              unless AURORA_POSTGRESQL_PARAMETERS.include?(param.name)
                invalid << param.name
              end
            end
          end

          invalid
        end

        # Get the database engine from family
        def engine_type
          case family
          when /^aurora-mysql/
            "mysql"
          when /^aurora-postgresql/
            "postgresql"
          else
            "unknown"
          end
        end

        # Get the engine version from family
        def engine_version
          case family
          when "aurora-mysql5.7"
            "5.7"
          when "aurora-mysql8.0"
            "8.0"
          when /^aurora-postgresql(\d+)/
            $1
          else
            "unknown"
          end
        end

        # Check if this is a MySQL family
        def is_mysql_family?
          family.start_with?("aurora-mysql")
        end

        # Check if this is a PostgreSQL family
        def is_postgresql_family?
          family.start_with?("aurora-postgresql")
        end

        # Get parameters that require immediate application
        def immediate_parameters
          parameter.select(&:requires_immediate_application?)
        end

        # Get parameters that require reboot
        def reboot_parameters
          parameter.select(&:requires_reboot?)
        end

        # Check if any parameters require immediate application
        def has_immediate_parameters?
          immediate_parameters.any?
        end

        # Check if any parameters require reboot
        def has_reboot_parameters?
          reboot_parameters.any?
        end

        # Get parameter by name
        def get_parameter(name)
          parameter.find { |p| p.name == name }
        end

        # Check if parameter exists
        def has_parameter?(name)
          !get_parameter(name).nil?
        end

        # Get all parameter names
        def parameter_names
          parameter.map(&:name)
        end

        # Generate summary of configuration
        def configuration_summary
          summary = ["Engine: #{engine_type}", "Version: #{engine_version}", "Parameters: #{parameter.count}"]
          
          if has_immediate_parameters?
            summary << "Immediate changes: #{immediate_parameters.count}"
          end
          
          if has_reboot_parameters?
            summary << "Reboot required: #{reboot_parameters.count}"
          end

          summary.join("; ")
        end

        # Common Aurora MySQL parameters with descriptions
        AURORA_MYSQL_PARAMETERS = Set.new([
          "innodb_buffer_pool_size", "max_connections", "slow_query_log",
          "long_query_time", "innodb_lock_wait_timeout", "interactive_timeout",
          "wait_timeout", "max_allowed_packet", "innodb_flush_log_at_trx_commit",
          "innodb_file_per_table", "general_log", "binlog_format",
          "innodb_autoinc_lock_mode", "character_set_server", "collation_server",
          "time_zone", "sql_mode", "innodb_log_buffer_size", "read_buffer_size",
          "sort_buffer_size", "join_buffer_size", "tmp_table_size",
          "max_heap_table_size", "thread_cache_size", "table_open_cache",
          "innodb_thread_concurrency", "innodb_read_io_threads", "innodb_write_io_threads"
        ]).freeze

        # Common Aurora PostgreSQL parameters with descriptions
        AURORA_POSTGRESQL_PARAMETERS = Set.new([
          "shared_buffers", "max_connections", "work_mem", "maintenance_work_mem",
          "effective_cache_size", "random_page_cost", "seq_page_cost", "log_statement",
          "log_min_duration_statement", "log_connections", "log_disconnections",
          "log_lock_waits", "log_temp_files", "checkpoint_timeout", "checkpoint_completion_target",
          "wal_buffers", "default_statistics_target", "effective_io_concurrency",
          "max_wal_size", "min_wal_size", "autovacuum", "autovacuum_max_workers",
          "autovacuum_naptime", "autovacuum_vacuum_threshold", "autovacuum_analyze_threshold",
          "timezone", "log_timezone", "datestyle", "lc_messages", "lc_monetary",
          "lc_numeric", "lc_time", "statement_timeout", "idle_in_transaction_session_timeout"
        ]).freeze
      end

      # Common RDS Cluster Parameter Group configurations
      module RdsClusterParameterGroupConfigs
        # Aurora MySQL performance optimization
        def self.aurora_mysql_performance(family: "aurora-mysql8.0")
          {
            family: family,
            description: "Aurora MySQL performance optimized parameter group",
            parameter: [
              { name: "innodb_buffer_pool_size", value: "{DBInstanceClassMemory*3/4}", apply_method: "pending-reboot" },
              { name: "max_connections", value: 1000, apply_method: "immediate" },
              { name: "slow_query_log", value: 1, apply_method: "immediate" },
              { name: "long_query_time", value: 0.5, apply_method: "immediate" },
              { name: "innodb_lock_wait_timeout", value: 120, apply_method: "immediate" },
              { name: "wait_timeout", value: 28800, apply_method: "immediate" },
              { name: "interactive_timeout", value: 28800, apply_method: "immediate" }
            ],
            tags: { Purpose: "performance", Engine: "aurora-mysql" }
          }
        end

        # Aurora PostgreSQL performance optimization
        def self.aurora_postgresql_performance(family: "aurora-postgresql14")
          {
            family: family,
            description: "Aurora PostgreSQL performance optimized parameter group",
            parameter: [
              { name: "shared_buffers", value: "{DBInstanceClassMemory/4}", apply_method: "pending-reboot" },
              { name: "max_connections", value: 1000, apply_method: "pending-reboot" },
              { name: "work_mem", value: "64MB", apply_method: "immediate" },
              { name: "maintenance_work_mem", value: "2GB", apply_method: "immediate" },
              { name: "effective_cache_size", value: "{DBInstanceClassMemory*3/4}", apply_method: "immediate" },
              { name: "random_page_cost", value: 1.1, apply_method: "immediate" },
              { name: "checkpoint_completion_target", value: 0.9, apply_method: "immediate" }
            ],
            tags: { Purpose: "performance", Engine: "aurora-postgresql" }
          }
        end

        # Development configuration with logging
        def self.development_logging(family:, engine_type:)
          if engine_type == "mysql"
            parameters = [
              { name: "slow_query_log", value: 1, apply_method: "immediate" },
              { name: "long_query_time", value: 0.1, apply_method: "immediate" },
              { name: "general_log", value: 1, apply_method: "immediate" }
            ]
          else # postgresql
            parameters = [
              { name: "log_statement", value: "all", apply_method: "immediate" },
              { name: "log_min_duration_statement", value: 100, apply_method: "immediate" },
              { name: "log_connections", value: 1, apply_method: "immediate" },
              { name: "log_disconnections", value: 1, apply_method: "immediate" }
            ]
          end

          {
            family: family,
            description: "Development parameter group with extensive logging",
            parameter: parameters,
            tags: { Environment: "development", Purpose: "debugging" }
          }
        end

        # Security hardened configuration
        def self.security_hardened(family:, engine_type:)
          if engine_type == "mysql"
            parameters = [
              { name: "sql_mode", value: "STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION", apply_method: "immediate" },
              { name: "innodb_lock_wait_timeout", value: 50, apply_method: "immediate" }
            ]
          else # postgresql  
            parameters = [
              { name: "statement_timeout", value: 300000, apply_method: "immediate" }, # 5 minutes
              { name: "idle_in_transaction_session_timeout", value: 600000, apply_method: "immediate" } # 10 minutes
            ]
          end

          {
            family: family,
            description: "Security hardened parameter group",
            parameter: parameters,
            tags: { Purpose: "security", Compliance: "hardened" }
          }
        end

        # High connection workload optimization
        def self.high_connections(family:, engine_type:)
          if engine_type == "mysql"
            parameters = [
              { name: "max_connections", value: 5000, apply_method: "immediate" },
              { name: "thread_cache_size", value: 256, apply_method: "immediate" },
              { name: "table_open_cache", value: 4000, apply_method: "immediate" },
              { name: "innodb_thread_concurrency", value: 0, apply_method: "immediate" }
            ]
          else # postgresql
            parameters = [
              { name: "max_connections", value: 5000, apply_method: "pending-reboot" },
              { name: "shared_buffers", value: "{DBInstanceClassMemory/3}", apply_method: "pending-reboot" },
              { name: "work_mem", value: "32MB", apply_method: "immediate" }
            ]
          end

          {
            family: family,
            description: "High connection count optimization",
            parameter: parameters,
            tags: { Purpose: "high-connections", Workload: "connection-heavy" }
          }
        end
      end
    end
      end
    end
  end
end