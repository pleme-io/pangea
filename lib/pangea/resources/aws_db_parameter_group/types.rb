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
require_relative 'types/db_parameter'
require_relative 'types/db_parameter_configs'
require_relative 'types/parameter_validators'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS RDS DB Parameter Group resources
        class DbParameterGroupAttributes < Dry::Struct
          include ParameterValidators

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
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

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
        end
      end
    end
  end
end
