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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_hyperdrive_config/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Hyperdrive Config resource module that self-registers
    module CloudflareHyperdriveConfig
      # Create a Cloudflare Hyperdrive Config
      #
      # Hyperdrive accelerates database queries through connection pooling,
      # caching, and smart routing. Supports PostgreSQL and MySQL databases
      # with optional Cloudflare Access integration for private databases.
      #
      # Connection pooling reduces overhead, SQL caching speeds up repeated
      # queries, and regional routing minimizes latency.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Hyperdrive config attributes
      # @option attributes [String] :account_id Account ID (required)
      # @option attributes [String] :name Configuration name (required)
      # @option attributes [Hash] :origin Origin database config (required)
      # @option attributes [Integer] :origin_connection_limit Max connections to origin
      # @option attributes [Hash] :caching Caching configuration
      # @option attributes [Hash] :mtls mTLS configuration
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Basic PostgreSQL configuration
      #   cloudflare_hyperdrive_config(:postgres_db, {
      #     account_id: "a" * 32,
      #     name: "my-postgres",
      #     origin: {
      #       database: "mydb",
      #       host: "db.example.com",
      #       user: "postgres",
      #       password: "secret",
      #       scheme: "postgres",
      #       port: 5432
      #     }
      #   })
      #
      # @example MySQL with caching
      #   cloudflare_hyperdrive_config(:mysql_db, {
      #     account_id: "a" * 32,
      #     name: "my-mysql",
      #     origin: {
      #       database: "mydb",
      #       host: "mysql.example.com",
      #       user: "root",
      #       password: "secret",
      #       scheme: "mysql",
      #       port: 3306
      #     },
      #     caching: {
      #       max_age: 120,
      #       stale_while_revalidate: 30
      #     }
      #   })
      #
      # @example Private database via Cloudflare Access
      #   cloudflare_hyperdrive_config(:private_db, {
      #     account_id: "a" * 32,
      #     name: "private-postgres",
      #     origin: {
      #       database: "mydb",
      #       host: "internal-db.corp.example.com",
      #       user: "postgres",
      #       password: "secret",
      #       scheme: "postgres",
      #       access_client_id: "abc123",
      #       access_client_secret: "def456"
      #     }
      #   })
      #
      # @example With mTLS and connection limits
      #   cloudflare_hyperdrive_config(:secure_db, {
      #     account_id: "a" * 32,
      #     name: "secure-postgres",
      #     origin: {
      #       database: "mydb",
      #       host: "secure-db.example.com",
      #       user: "postgres",
      #       password: "secret",
      #       scheme: "postgres"
      #     },
      #     origin_connection_limit: 50,
      #     mtls: {
      #       ca_certificate_id: "ca-cert-123",
      #       mtls_certificate_id: "client-cert-456",
      #       sslmode: "verify-full"
      #     }
      #   })
      def cloudflare_hyperdrive_config(name, attributes = {})
        # Validate attributes using dry-struct
        config_attrs = Cloudflare::Types::HyperdriveConfigAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_hyperdrive_config, name) do
          account_id config_attrs.account_id
          name config_attrs.name

          # Origin database configuration
          origin do
            database config_attrs.origin.database
            host config_attrs.origin.host
            user config_attrs.origin.user
            password config_attrs.origin.password
            scheme config_attrs.origin.scheme
            port config_attrs.origin.port if config_attrs.origin.port

            # Access configuration for private databases
            access_client_id config_attrs.origin.access_client_id if config_attrs.origin.access_client_id
            access_client_secret config_attrs.origin.access_client_secret if config_attrs.origin.access_client_secret
          end

          # Connection limit
          origin_connection_limit config_attrs.origin_connection_limit if config_attrs.origin_connection_limit

          # Caching configuration
          if config_attrs.caching
            caching do
              disabled config_attrs.caching.disabled if config_attrs.caching.disabled
              max_age config_attrs.caching.max_age if config_attrs.caching.max_age
              stale_while_revalidate config_attrs.caching.stale_while_revalidate if config_attrs.caching.stale_while_revalidate
            end
          end

          # mTLS configuration
          if config_attrs.mtls
            mtls do
              ca_certificate_id config_attrs.mtls.ca_certificate_id if config_attrs.mtls.ca_certificate_id
              mtls_certificate_id config_attrs.mtls.mtls_certificate_id if config_attrs.mtls.mtls_certificate_id
              sslmode config_attrs.mtls.sslmode if config_attrs.mtls.sslmode
            end
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_hyperdrive_config',
          name: name,
          resource_attributes: config_attrs.to_h,
          outputs: {
            id: "${cloudflare_hyperdrive_config.#{name}.id}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareHyperdriveConfig
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
