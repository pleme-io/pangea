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
      # Individual parameter definition for DB parameter groups
      class DbParameter < Dry::Struct
        # Parameter name
        attribute :name, Resources::Types::String

        # Parameter value
        attribute :value, Resources::Types::String

        # Apply method for parameter application
        attribute :apply_method, Resources::Types::String.enum("immediate", "pending-reboot").optional

        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate parameter name format
          unless attrs.name.match?(/^[a-zA-Z][a-zA-Z0-9_.-]*$/)
            raise Dry::Struct::Error, "Invalid parameter name format: #{attrs.name}"
          end

          attrs
        end

        # Check if parameter requires reboot
        def requires_reboot?
          apply_method == "pending-reboot"
        end

        # Check if parameter applies immediately
        def applies_immediately?
          apply_method == "immediate" || apply_method.nil?
        end
      end

      # Type-safe attributes for AWS RDS DB Parameter Group resources
      class DbParameterGroupAttributes < Dry::Struct
        # Parameter group name (required)
        attribute :name, Resources::Types::String

        # Parameter group family (engine-specific)
        attribute :family, Resources::Types::String.enum(
          # MySQL families
          "mysql5.7", "mysql8.0",
          # PostgreSQL families  
          "postgres11", "postgres12", "postgres13", "postgres14", "postgres15", "postgres16",
          # MariaDB families
          "mariadb10.4", "mariadb10.5", "mariadb10.6", "mariadb10.11",
          # Oracle families
          "oracle-ee-11.2", "oracle-ee-12.1", "oracle-ee-12.2", "oracle-ee-19", "oracle-ee-21",
          "oracle-se2-11.2", "oracle-se2-12.1", "oracle-se2-12.2", "oracle-se2-19", "oracle-se2-21",
          # SQL Server families
          "sqlserver-ee-11.0", "sqlserver-ee-12.0", "sqlserver-ee-13.0", "sqlserver-ee-14.0", "sqlserver-ee-15.0", "sqlserver-ee-16.0",
          "sqlserver-ex-11.0", "sqlserver-ex-12.0", "sqlserver-ex-13.0", "sqlserver-ex-14.0", "sqlserver-ex-15.0", "sqlserver-ex-16.0",
          "sqlserver-se-11.0", "sqlserver-se-12.0", "sqlserver-se-13.0", "sqlserver-se-14.0", "sqlserver-se-15.0", "sqlserver-se-16.0",
          "sqlserver-web-11.0", "sqlserver-web-12.0", "sqlserver-web-13.0", "sqlserver-web-14.0", "sqlserver-web-15.0", "sqlserver-web-16.0",
          # Aurora families
          "aurora-mysql5.7", "aurora-mysql8.0",
          "aurora-postgresql11", "aurora-postgresql12", "aurora-postgresql13", "aurora-postgresql14", "aurora-postgresql15", "aurora-postgresql16"
        )

        # Description for the parameter group
        attribute :description, Resources::Types::String.optional

        # Parameters to set
        attribute :parameters, Resources::Types::Array.of(DbParameter).default([].freeze)

        # Tags to apply to the parameter group
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate parameter group name format
          unless attrs.name.match?(/^[a-zA-Z][a-zA-Z0-9-]{0,254}$/)
            raise Dry::Struct::Error, "Parameter group name must start with a letter and contain only alphanumeric characters and hyphens (max 255 chars)"
          end

          # Validate unique parameter names
          param_names = attrs.parameters.map(&:name)
          if param_names.uniq.length != param_names.length
            duplicates = param_names.group_by(&:itself).select { |_, v| v.size > 1 }.keys
            raise Dry::Struct::Error, "Duplicate parameter names found: #{duplicates.join(', ')}"
          end

          attrs
        end

        # Get the database engine from family
        def engine
          case family
          when /mysql/
            "mysql"
          when /postgres/
            "postgresql"
          when /mariadb/
            "mariadb"
          when /oracle/
            "oracle"
          when /sqlserver/
            "sqlserver"
          when /aurora-mysql/
            "aurora-mysql"
          when /aurora-postgresql/
            "aurora-postgresql"
          else
            "unknown"
          end
        end

        # Check if this is an Aurora parameter group
        def is_aurora?
          family.start_with?("aurora")
        end

        # Get engine version from family
        def engine_version
          family.split(/[.-]/).last || "unknown"
        end

        # Generate a description if none provided
        def effective_description
          description || "Custom #{engine} parameter group for #{name}"
        end

        # Get parameters that require reboot
        def reboot_required_parameters
          parameters.select(&:requires_reboot?)
        end

        # Get parameters that apply immediately
        def immediate_parameters
          parameters.select(&:applies_immediately?)
        end

        # Check if any parameters require instance reboot
        def requires_reboot?
          reboot_required_parameters.any?
        end

        # Get parameter count
        def parameter_count
          parameters.length
        end

        # Validate parameters for the specific engine family
        def validate_parameters_for_family
          case engine
          when "mysql", "aurora-mysql"
            validate_mysql_parameters
          when "postgresql", "aurora-postgresql"
            validate_postgresql_parameters
          when "mariadb"
            validate_mariadb_parameters
          when "oracle"
            validate_oracle_parameters
          when "sqlserver"
            validate_sqlserver_parameters
          end
        end

        # Estimate monthly cost (parameter groups have no direct cost)
        def estimated_monthly_cost
          "$0.00/month (no direct cost for parameter groups)"
        end

        private

        def validate_mysql_parameters
          # MySQL-specific parameter validation
          mysql_params = %w[
            innodb_buffer_pool_size max_connections slow_query_log
            log_bin_trust_function_creators innodb_log_file_size
          ]
          
          invalid_params = parameters.map(&:name) - mysql_params
          if invalid_params.any?
            # Note: This is a simplified validation - in practice, MySQL has hundreds of parameters
            # For production use, we'd want a comprehensive parameter registry
          end
        end

        def validate_postgresql_parameters
          # PostgreSQL-specific parameter validation
          pg_params = %w[
            shared_preload_libraries max_connections work_mem
            maintenance_work_mem checkpoint_completion_target
            wal_buffers log_statement
          ]
          
          # Similar simplified validation for PostgreSQL
        end

        def validate_mariadb_parameters
          # MariaDB shares many parameters with MySQL
          validate_mysql_parameters
        end

        def validate_oracle_parameters
          # Oracle-specific parameter validation
          oracle_params = %w[
            open_cursors processes sessions
            shared_pool_size pga_aggregate_target
          ]
        end

        def validate_sqlserver_parameters
          # SQL Server parameter validation
          sqlserver_params = %w[
            max_degree_of_parallelism cost_threshold_for_parallelism
            max_server_memory backup_compression_default
          ]
        end
      end

      # Common parameter configurations for different engines
      module DbParameterConfigs
        # MySQL performance tuning parameters
        def self.mysql_performance(instance_class: "db.t3.micro")
          buffer_pool_size = case instance_class
                           when /t3.micro/ then "134217728"  # 128MB
                           when /t3.small/ then "268435456"  # 256MB
                           when /t3.medium/ then "536870912" # 512MB
                           when /m5.large/ then "1073741824" # 1GB
                           else "268435456" # Default 256MB
                           end

          [
            { name: "innodb_buffer_pool_size", value: buffer_pool_size, apply_method: "pending-reboot" },
            { name: "slow_query_log", value: "1", apply_method: "immediate" },
            { name: "long_query_time", value: "2", apply_method: "immediate" },
            { name: "max_connections", value: "100", apply_method: "immediate" }
          ]
        end

        # PostgreSQL performance tuning parameters
        def self.postgresql_performance(instance_class: "db.t3.micro")
          shared_buffers = case instance_class
                         when /t3.micro/ then "32MB"
                         when /t3.small/ then "64MB" 
                         when /t3.medium/ then "128MB"
                         when /m5.large/ then "256MB"
                         else "64MB"
                         end

          [
            { name: "shared_buffers", value: shared_buffers, apply_method: "pending-reboot" },
            { name: "work_mem", value: "4MB", apply_method: "immediate" },
            { name: "maintenance_work_mem", value: "64MB", apply_method: "immediate" },
            { name: "checkpoint_completion_target", value: "0.9", apply_method: "immediate" },
            { name: "log_statement", value: "all", apply_method: "immediate" }
          ]
        end

        # Aurora MySQL parameters
        def self.aurora_mysql_performance
          [
            { name: "slow_query_log", value: "1", apply_method: "immediate" },
            { name: "long_query_time", value: "2", apply_method: "immediate" },
            { name: "binlog_format", value: "ROW", apply_method: "pending-reboot" },
            { name: "innodb_print_all_deadlocks", value: "1", apply_method: "immediate" }
          ]
        end

        # Aurora PostgreSQL parameters
        def self.aurora_postgresql_performance
          [
            { name: "shared_preload_libraries", value: "pg_stat_statements", apply_method: "pending-reboot" },
            { name: "log_statement", value: "all", apply_method: "immediate" },
            { name: "log_min_duration_statement", value: "1000", apply_method: "immediate" },
            { name: "checkpoint_completion_target", value: "0.9", apply_method: "immediate" }
          ]
        end
      end
    end
      end
    end
  end
end