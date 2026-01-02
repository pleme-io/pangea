# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'nested_types'

module Pangea
  module Resources
    module AWS
      module Types
        class RdsProxyAttributes < Dry::Struct
          attribute :db_proxy_name, Resources::Types::String
          attribute :engine_family, Resources::Types::String.enum('MYSQL', 'POSTGRESQL')
          attribute :auth, Resources::Types::Array.of(ProxyAuth).constrained(min_size: 1)
          attribute :role_arn, Resources::Types::String
          attribute :vpc_subnet_ids, Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1)
          attribute :vpc_security_group_ids, Resources::Types::Array.of(Resources::Types::String).optional
          attribute :require_tls, Resources::Types::Bool.default(true)
          attribute :idle_client_timeout, Resources::Types::Integer.default(1800).constrained(gteq: 1800, lteq: 28800)
          attribute :debug_logging, Resources::Types::Bool.default(false)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, 'db_proxy_name must start with a letter and contain only letters, numbers, and hyphens' unless attrs.db_proxy_name.match?(/^[a-zA-Z][a-zA-Z0-9-]*$/)
            raise Dry::Struct::Error, 'db_proxy_name cannot exceed 63 characters' if attrs.db_proxy_name.length > 63
            validate_auth_for_engine(attrs)
            raise Dry::Struct::Error, 'At least 2 VPC subnets required for high availability' if attrs.vpc_subnet_ids.count < 2
            attrs
          end

          def self.validate_auth_for_engine(attrs)
            attrs.auth.each do |auth_config|
              next unless auth_config.client_password_auth_type
              case attrs.engine_family
              when 'MYSQL'
                raise Dry::Struct::Error, 'Invalid client_password_auth_type for MySQL engine family' unless auth_config.client_password_auth_type == 'MYSQL_NATIVE_PASSWORD'
              when 'POSTGRESQL'
                raise Dry::Struct::Error, 'Invalid client_password_auth_type for PostgreSQL engine family' unless %w[POSTGRES_SCRAM_SHA_256 POSTGRES_MD5].include?(auth_config.client_password_auth_type)
              end
            end
          end

          def is_mysql? = engine_family == 'MYSQL'
          def is_postgresql? = engine_family == 'POSTGRESQL'
          def requires_tls? = require_tls
          def debug_logging_enabled? = debug_logging
          def uses_iam_auth? = auth.any?(&:requires_iam_auth?)
          def is_highly_available? = vpc_subnet_ids.count >= 2
          def auth_config_count = auth.count
          def idle_timeout_hours = (idle_client_timeout / 3600.0).round(2)
          def secrets_manager_arns = auth.map(&:secret_arn).uniq
          def has_security_groups? = vpc_security_group_ids&.any?

          def configuration_summary
            summary = ["Engine: #{engine_family.downcase}", "Auth: #{auth_config_count} configs", "TLS: #{requires_tls? ? 'required' : 'optional'}", "Timeout: #{idle_timeout_hours}h"]
            summary << 'IAM: enabled' if uses_iam_auth?
            summary << 'Debug: enabled' if debug_logging_enabled?
            summary << "HA: #{vpc_subnet_ids.count} subnets"
            summary.join('; ')
          end

          def estimated_monthly_cost
            monthly_cost = 2 * 730 * 0.015
            "$#{monthly_cost.round(2)}/month (plus target database costs)"
          end

          def supported_database_engines = is_mysql? ? %w[MySQL Aurora\ MySQL] : %w[PostgreSQL Aurora\ PostgreSQL]
        end
      end
    end
  end
end
