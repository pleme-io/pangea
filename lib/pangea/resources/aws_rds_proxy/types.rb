# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Authentication method configuration for RDS Proxy
      class ProxyAuth < Dry::Struct
        # Authentication scheme (SECRETS for Secrets Manager)
        attribute :auth_scheme, Resources::Types::String.enum("SECRETS")

        # Client password authentication type
        attribute :client_password_auth_type, Resources::Types::String.enum("MYSQL_NATIVE_PASSWORD", "POSTGRES_SCRAM_SHA_256", "POSTGRES_MD5", "SQL_SERVER_AUTHENTICATION").optional

        # Description of the auth configuration
        attribute :description, Resources::Types::String.optional

        # IAM authentication requirement (DISABLED, REQUIRED)
        attribute :iam_auth, Resources::Types::String.enum("DISABLED", "REQUIRED").default("DISABLED")

        # Secrets Manager secret ARN
        attribute :secret_arn, Resources::Types::String

        # Username for the authentication (optional for IAM auth)
        attribute :username, Resources::Types::String.optional

        def self.new(attributes = {})
          attrs = super(attributes)

          # Username validation based on auth type
          if attrs.iam_auth == "DISABLED" && !attrs.username
            raise Dry::Struct::Error, "username is required when iam_auth is DISABLED"
          end

          # Client password auth type validation by engine
          if attrs.client_password_auth_type
            case attrs.client_password_auth_type
            when "MYSQL_NATIVE_PASSWORD"
              # MySQL/Aurora MySQL only
            when "POSTGRES_SCRAM_SHA_256", "POSTGRES_MD5"
              # PostgreSQL/Aurora PostgreSQL only
            when "SQL_SERVER_AUTHENTICATION"
              # SQL Server only (not supported for Aurora)
              raise Dry::Struct::Error, "SQL Server authentication not supported for Aurora"
            end
          end

          attrs
        end

        # Check if IAM authentication is required
        def requires_iam_auth?
          iam_auth == "REQUIRED"
        end

        # Check if using native database authentication
        def uses_native_auth?
          iam_auth == "DISABLED"
        end

        # Get authentication type summary
        def auth_summary
          summary = [auth_scheme]
          summary << "IAM: #{iam_auth.downcase}"
          summary << "Username: #{username}" if username
          summary << "Client Auth: #{client_password_auth_type}" if client_password_auth_type
          summary.join(", ")
        end
      end

      # Connection pooling configuration for RDS Proxy
      class ProxyConnectionPoolConfig < Dry::Struct
        # Maximum connections as percentage of max_connections parameter (0-100)
        attribute :max_connections_percent, Resources::Types::Integer.default(100).constrained(gteq: 0, lteq: 100)

        # Maximum idle connections as percentage (0-max_connections_percent)
        attribute :max_idle_connections_percent, Resources::Types::Integer.default(50).constrained(gteq: 0, lteq: 100)

        # Session pinning filters to reduce connection reuse
        attribute :session_pinning_filters, Resources::Types::Array.of(
          Types::String.enum(
            "EXCLUDE_VARIABLE_SETS"
          )
        ).default([].freeze)

        # Initialize query for database connections
        attribute :init_query, Resources::Types::String.optional

        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate idle connections don't exceed max connections
          if attrs.max_idle_connections_percent > attrs.max_connections_percent
            raise Dry::Struct::Error, "max_idle_connections_percent cannot exceed max_connections_percent"
          end

          attrs
        end

        # Check if session pinning filters are configured
        def has_session_pinning_filters?
          session_pinning_filters.any?
        end

        # Check if initialization query is configured
        def has_init_query?
          !init_query.nil?
        end

        # Get connection pool efficiency ratio
        def connection_efficiency_ratio
          return 1.0 if max_connections_percent == 0
          max_idle_connections_percent.to_f / max_connections_percent
        end

        # Generate pool configuration summary
        def pool_summary
          summary = ["Max: #{max_connections_percent}%", "Idle: #{max_idle_connections_percent}%"]
          summary << "Filters: #{session_pinning_filters.count}" if has_session_pinning_filters?
          summary << "Init Query: configured" if has_init_query?
          summary.join(", ")
        end
      end

      # Type-safe attributes for AWS RDS Proxy resources
      class RdsProxyAttributes < Dry::Struct
        # Proxy name (must be unique within AWS account and region)
        attribute :db_proxy_name, Resources::Types::String

        # Database engine family (mysql, postgresql)
        attribute :engine_family, Resources::Types::String.enum("MYSQL", "POSTGRESQL")

        # Authentication configurations
        attribute :auth, Resources::Types::Array.of(ProxyAuth).constrained(min_size: 1)

        # IAM role ARN for proxy to access Secrets Manager and other AWS services
        attribute :role_arn, Resources::Types::String

        # VPC subnet IDs where proxy endpoints will be created
        attribute :vpc_subnet_ids, Resources::Types::Array.of(Types::String).constrained(min_size: 1)

        # VPC security group IDs for proxy endpoints
        attribute :vpc_security_group_ids, Resources::Types::Array.of(Types::String).optional

        # Whether to require TLS connections
        attribute :require_tls, Resources::Types::Bool.default(true)

        # Idle client connection timeout in seconds (1800-28800)
        attribute :idle_client_timeout, Resources::Types::Integer.default(1800).constrained(gteq: 1800, lteq: 28800)

        # Whether debug logging is enabled
        attribute :debug_logging, Resources::Types::Bool.default(false)

        # Tags to apply to the proxy
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate proxy name format
          unless attrs.db_proxy_name.match?(/^[a-zA-Z][a-zA-Z0-9-]*$/)
            raise Dry::Struct::Error, "db_proxy_name must start with a letter and contain only letters, numbers, and hyphens"
          end

          # Validate proxy name length
          if attrs.db_proxy_name.length > 63
            raise Dry::Struct::Error, "db_proxy_name cannot exceed 63 characters"
          end

          # Validate auth configurations for engine family
          attrs.auth.each do |auth_config|
            if auth_config.client_password_auth_type
              case attrs.engine_family
              when "MYSQL"
                unless auth_config.client_password_auth_type == "MYSQL_NATIVE_PASSWORD"
                  raise Dry::Struct::Error, "Invalid client_password_auth_type for MySQL engine family"
                end
              when "POSTGRESQL"
                unless ["POSTGRES_SCRAM_SHA_256", "POSTGRES_MD5"].include?(auth_config.client_password_auth_type)
                  raise Dry::Struct::Error, "Invalid client_password_auth_type for PostgreSQL engine family"
                end
              end
            end
          end

          # Validate subnet count (minimum 2 for high availability)
          if attrs.vpc_subnet_ids.count < 2
            raise Dry::Struct::Error, "At least 2 VPC subnets required for high availability"
          end

          attrs
        end

        # Check if this is a MySQL proxy
        def is_mysql?
          engine_family == "MYSQL"
        end

        # Check if this is a PostgreSQL proxy
        def is_postgresql?
          engine_family == "POSTGRESQL"
        end

        # Check if TLS is required
        def requires_tls?
          require_tls
        end

        # Check if debug logging is enabled
        def debug_logging_enabled?
          debug_logging
        end

        # Check if any auth configurations use IAM
        def uses_iam_auth?
          auth.any?(&:requires_iam_auth?)
        end

        # Check if high availability is configured
        def is_highly_available?
          vpc_subnet_ids.count >= 2
        end

        # Get auth configuration count
        def auth_config_count
          auth.count
        end

        # Get timeout in hours for readability
        def idle_timeout_hours
          (idle_client_timeout / 3600.0).round(2)
        end

        # Get all secrets manager ARNs
        def secrets_manager_arns
          auth.map(&:secret_arn).uniq
        end

        # Check if proxy has security groups configured
        def has_security_groups?
          vpc_security_group_ids && vpc_security_group_ids.any?
        end

        # Generate proxy configuration summary
        def configuration_summary
          summary = [
            "Engine: #{engine_family.downcase}",
            "Auth: #{auth_config_count} configs",
            "TLS: #{requires_tls? ? 'required' : 'optional'}",
            "Timeout: #{idle_timeout_hours}h"
          ]
          
          summary << "IAM: enabled" if uses_iam_auth?
          summary << "Debug: enabled" if debug_logging_enabled?
          summary << "HA: #{vpc_subnet_ids.count} subnets"
          
          summary.join("; ")
        end

        # Estimate monthly cost (RDS Proxy pricing)
        def estimated_monthly_cost
          # RDS Proxy pricing is per vCPU hour
          # Rough estimate: $0.015 per vCPU hour
          vcpu_hours_per_month = 730
          estimated_vcpus = 2 # Minimum for high availability
          
          monthly_cost = estimated_vcpus * vcpu_hours_per_month * 0.015
          "$#{monthly_cost.round(2)}/month (plus target database costs)"
        end

        # Get supported database engines
        def supported_database_engines
          case engine_family
          when "MYSQL"
            ["MySQL", "Aurora MySQL"]
          when "POSTGRESQL"
            ["PostgreSQL", "Aurora PostgreSQL"]
          else
            []
          end
        end

        # Validate auth configuration compatibility
        def validate_auth_for_database(database_engine)
          auth.each do |auth_config|
            case database_engine.downcase
            when "mysql", "aurora-mysql"
              if auth_config.client_password_auth_type && auth_config.client_password_auth_type != "MYSQL_NATIVE_PASSWORD"
                raise Dry::Struct::Error, "Invalid auth type #{auth_config.client_password_auth_type} for #{database_engine}"
              end
            when "postgresql", "aurora-postgresql"
              if auth_config.client_password_auth_type && !["POSTGRES_SCRAM_SHA_256", "POSTGRES_MD5"].include?(auth_config.client_password_auth_type)
                raise Dry::Struct::Error, "Invalid auth type #{auth_config.client_password_auth_type} for #{database_engine}"
              end
            end
          end
        end
      end

      # Common RDS Proxy configurations
      module RdsProxyConfigs
        # Production MySQL proxy with IAM authentication
        def self.mysql_production(proxy_name:, role_arn:, secret_arn:, vpc_subnet_ids:, vpc_security_group_ids: nil)
          {
            db_proxy_name: proxy_name,
            engine_family: "MYSQL",
            auth: [
              {
                auth_scheme: "SECRETS",
                client_password_auth_type: "MYSQL_NATIVE_PASSWORD",
                description: "Production MySQL authentication",
                iam_auth: "REQUIRED",
                secret_arn: secret_arn
              }
            ],
            role_arn: role_arn,
            vpc_subnet_ids: vpc_subnet_ids,
            vpc_security_group_ids: vpc_security_group_ids,
            require_tls: true,
            idle_client_timeout: 3600, # 1 hour
            debug_logging: false,
            tags: { Environment: "production", Engine: "mysql", Type: "proxy" }
          }
        end

        # Production PostgreSQL proxy
        def self.postgresql_production(proxy_name:, role_arn:, secret_arn:, vpc_subnet_ids:, vpc_security_group_ids: nil)
          {
            db_proxy_name: proxy_name,
            engine_family: "POSTGRESQL",
            auth: [
              {
                auth_scheme: "SECRETS",
                client_password_auth_type: "POSTGRES_SCRAM_SHA_256",
                description: "Production PostgreSQL authentication",
                iam_auth: "REQUIRED",
                secret_arn: secret_arn
              }
            ],
            role_arn: role_arn,
            vpc_subnet_ids: vpc_subnet_ids,
            vpc_security_group_ids: vpc_security_group_ids,
            require_tls: true,
            idle_client_timeout: 3600,
            debug_logging: false,
            tags: { Environment: "production", Engine: "postgresql", Type: "proxy" }
          }
        end

        # Development proxy with debug logging
        def self.development(proxy_name:, engine_family:, role_arn:, secret_arn:, username:, vpc_subnet_ids:)
          {
            db_proxy_name: proxy_name,
            engine_family: engine_family,
            auth: [
              {
                auth_scheme: "SECRETS",
                description: "Development authentication",
                iam_auth: "DISABLED",
                secret_arn: secret_arn,
                username: username
              }
            ],
            role_arn: role_arn,
            vpc_subnet_ids: vpc_subnet_ids,
            require_tls: false,
            idle_client_timeout: 1800, # 30 minutes
            debug_logging: true,
            tags: { Environment: "development", Type: "proxy", Debug: "enabled" }
          }
        end

        # High-availability proxy with multiple auth methods
        def self.high_availability(proxy_name:, engine_family:, role_arn:, auth_configs:, vpc_subnet_ids:, vpc_security_group_ids:)
          {
            db_proxy_name: proxy_name,
            engine_family: engine_family,
            auth: auth_configs,
            role_arn: role_arn,
            vpc_subnet_ids: vpc_subnet_ids,
            vpc_security_group_ids: vpc_security_group_ids,
            require_tls: true,
            idle_client_timeout: 7200, # 2 hours
            debug_logging: false,
            tags: { Purpose: "high-availability", Type: "proxy", Redundancy: "multi-auth" }
          }
        end
      end
    end
      end
    end
  end
end