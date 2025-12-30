# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        class ProxyAuth < Dry::Struct
          attribute :auth_scheme, Resources::Types::String.enum('SECRETS')
          attribute :client_password_auth_type, Resources::Types::String.enum('MYSQL_NATIVE_PASSWORD', 'POSTGRES_SCRAM_SHA_256', 'POSTGRES_MD5', 'SQL_SERVER_AUTHENTICATION').optional
          attribute :description, Resources::Types::String.optional
          attribute :iam_auth, Resources::Types::String.enum('DISABLED', 'REQUIRED').default('DISABLED')
          attribute :secret_arn, Resources::Types::String
          attribute :username, Resources::Types::String.optional

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, 'username is required when iam_auth is DISABLED' if attrs.iam_auth == 'DISABLED' && !attrs.username
            raise Dry::Struct::Error, 'SQL Server authentication not supported for Aurora' if attrs.client_password_auth_type == 'SQL_SERVER_AUTHENTICATION'
            attrs
          end

          def requires_iam_auth? = iam_auth == 'REQUIRED'
          def uses_native_auth? = iam_auth == 'DISABLED'

          def auth_summary
            summary = [auth_scheme, "IAM: #{iam_auth.downcase}"]
            summary << "Username: #{username}" if username
            summary << "Client Auth: #{client_password_auth_type}" if client_password_auth_type
            summary.join(', ')
          end
        end

        class ProxyConnectionPoolConfig < Dry::Struct
          attribute :max_connections_percent, Resources::Types::Integer.default(100).constrained(gteq: 0, lteq: 100)
          attribute :max_idle_connections_percent, Resources::Types::Integer.default(50).constrained(gteq: 0, lteq: 100)
          attribute :session_pinning_filters, Resources::Types::Array.of(Resources::Types::String.enum('EXCLUDE_VARIABLE_SETS')).default([].freeze)
          attribute :init_query, Resources::Types::String.optional

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, 'max_idle_connections_percent cannot exceed max_connections_percent' if attrs.max_idle_connections_percent > attrs.max_connections_percent
            attrs
          end

          def has_session_pinning_filters? = session_pinning_filters.any?
          def has_init_query? = !init_query.nil?
          def connection_efficiency_ratio = max_connections_percent.zero? ? 1.0 : max_idle_connections_percent.to_f / max_connections_percent

          def pool_summary
            summary = ["Max: #{max_connections_percent}%", "Idle: #{max_idle_connections_percent}%"]
            summary << "Filters: #{session_pinning_filters.count}" if has_session_pinning_filters?
            summary << 'Init Query: configured' if has_init_query?
            summary.join(', ')
          end
        end
      end
    end
  end
end
