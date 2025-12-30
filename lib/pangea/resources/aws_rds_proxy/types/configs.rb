# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module RdsProxyConfigs
          def self.mysql_production(proxy_name:, role_arn:, secret_arn:, vpc_subnet_ids:, vpc_security_group_ids: nil)
            { db_proxy_name: proxy_name, engine_family: 'MYSQL',
              auth: [{ auth_scheme: 'SECRETS', client_password_auth_type: 'MYSQL_NATIVE_PASSWORD', description: 'Production MySQL authentication', iam_auth: 'REQUIRED', secret_arn: secret_arn }],
              role_arn: role_arn, vpc_subnet_ids: vpc_subnet_ids, vpc_security_group_ids: vpc_security_group_ids,
              require_tls: true, idle_client_timeout: 3600, debug_logging: false,
              tags: { Environment: 'production', Engine: 'mysql', Type: 'proxy' } }
          end

          def self.postgresql_production(proxy_name:, role_arn:, secret_arn:, vpc_subnet_ids:, vpc_security_group_ids: nil)
            { db_proxy_name: proxy_name, engine_family: 'POSTGRESQL',
              auth: [{ auth_scheme: 'SECRETS', client_password_auth_type: 'POSTGRES_SCRAM_SHA_256', description: 'Production PostgreSQL authentication', iam_auth: 'REQUIRED', secret_arn: secret_arn }],
              role_arn: role_arn, vpc_subnet_ids: vpc_subnet_ids, vpc_security_group_ids: vpc_security_group_ids,
              require_tls: true, idle_client_timeout: 3600, debug_logging: false,
              tags: { Environment: 'production', Engine: 'postgresql', Type: 'proxy' } }
          end

          def self.development(proxy_name:, engine_family:, role_arn:, secret_arn:, username:, vpc_subnet_ids:)
            { db_proxy_name: proxy_name, engine_family: engine_family,
              auth: [{ auth_scheme: 'SECRETS', description: 'Development authentication', iam_auth: 'DISABLED', secret_arn: secret_arn, username: username }],
              role_arn: role_arn, vpc_subnet_ids: vpc_subnet_ids, require_tls: false, idle_client_timeout: 1800, debug_logging: true,
              tags: { Environment: 'development', Type: 'proxy', Debug: 'enabled' } }
          end

          def self.high_availability(proxy_name:, engine_family:, role_arn:, auth_configs:, vpc_subnet_ids:, vpc_security_group_ids:)
            { db_proxy_name: proxy_name, engine_family: engine_family, auth: auth_configs,
              role_arn: role_arn, vpc_subnet_ids: vpc_subnet_ids, vpc_security_group_ids: vpc_security_group_ids,
              require_tls: true, idle_client_timeout: 7200, debug_logging: false,
              tags: { Purpose: 'high-availability', Type: 'proxy', Redundancy: 'multi-auth' } }
          end
        end
      end
    end
  end
end
