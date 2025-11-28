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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Cloudflare
      module Types
        # Database scheme for Hyperdrive
        CloudflareHyperdriveScheme = Dry::Types['strict.string'].enum(
          'postgres',
          'postgresql',
          'mysql'
        )

        # SSL mode for mTLS connections
        CloudflareHyperdriveSslMode = Dry::Types['strict.string'].enum(
          'require',      # Require SSL but don't verify CA
          'verify-ca',    # Verify CA certificate
          'verify-full'   # Verify CA and hostname
        )

        # Origin database configuration for Hyperdrive
        class HyperdriveOrigin < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute database
          #   @return [String] Database name
          attribute :database, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute host
          #   @return [String] Database hostname or IP
          attribute :host, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute user
          #   @return [String] Database username
          attribute :user, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute password
          #   @return [String] Database password
          attribute :password, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute scheme
          #   @return [String] Database scheme (postgres, postgresql, mysql)
          attribute :scheme, CloudflareHyperdriveScheme

          # @!attribute port
          #   @return [Integer, nil] Database port (defaults: 5432 for Postgres, 3306 for MySQL)
          attribute :port, Dry::Types['coercible.integer']
            .constrained(gteq: 1, lteq: 65535)
            .optional
            .default(nil)

          # @!attribute access_client_id
          #   @return [String, nil] Access Client ID for private database via Tunnel
          attribute :access_client_id, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute access_client_secret
          #   @return [String, nil] Access Client Secret for private database
          attribute :access_client_secret, Dry::Types['strict.string'].optional.default(nil)

          # Check if using Cloudflare Access for private database
          # @return [Boolean] true if Access configured
          def access_configured?
            !access_client_id.nil? && !access_client_secret.nil?
          end

          # Check if PostgreSQL
          # @return [Boolean] true if postgres/postgresql
          def postgres?
            %w[postgres postgresql].include?(scheme)
          end

          # Check if MySQL
          # @return [Boolean] true if mysql
          def mysql?
            scheme == 'mysql'
          end

          # Get default port for scheme if not specified
          # @return [Integer] default port
          def default_port
            return port if port

            postgres? ? 5432 : 3306
          end
        end

        # Caching configuration for SQL responses
        class HyperdriveCaching < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute disabled
          #   @return [Boolean, nil] Disable caching (default: false)
          attribute :disabled, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute max_age
          #   @return [Integer, nil] Cache duration in seconds (default: 60)
          attribute :max_age, Dry::Types['coercible.integer']
            .constrained(gteq: 0)
            .optional
            .default(nil)

          # @!attribute stale_while_revalidate
          #   @return [Integer, nil] Stale response serving window in seconds (default: 15)
          attribute :stale_while_revalidate, Dry::Types['coercible.integer']
            .constrained(gteq: 0)
            .optional
            .default(nil)

          # Check if caching is enabled
          # @return [Boolean] true if not disabled
          def enabled?
            disabled != true
          end
        end

        # mTLS configuration for secure database connections
        class HyperdriveMtls < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute ca_certificate_id
          #   @return [String, nil] CA certificate identifier
          attribute :ca_certificate_id, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute mtls_certificate_id
          #   @return [String, nil] Client certificate identifier
          attribute :mtls_certificate_id, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute sslmode
          #   @return [String, nil] SSL verification mode
          attribute :sslmode, CloudflareHyperdriveSslMode.optional.default(nil)

          # Check if CA certificate configured
          # @return [Boolean] true if CA cert provided
          def ca_configured?
            !ca_certificate_id.nil?
          end

          # Check if full verification required
          # @return [Boolean] true if verify-full mode
          def full_verification?
            sslmode == 'verify-full'
          end
        end

        # Type-safe attributes for Cloudflare Hyperdrive Config
        #
        # Hyperdrive accelerates database queries by connection pooling,
        # caching, and smart routing to origin databases.
        #
        # Supports PostgreSQL and MySQL with optional Cloudflare Access
        # integration for private databases via Tunnel.
        #
        # @example Basic PostgreSQL configuration
        #   HyperdriveConfigAttributes.new(
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
        #   )
        #
        # @example With caching configuration
        #   HyperdriveConfigAttributes.new(
        #     account_id: "a" * 32,
        #     name: "cached-db",
        #     origin: { ... },
        #     caching: {
        #       max_age: 120,
        #       stale_while_revalidate: 30
        #     }
        #   )
        #
        # @example Private database via Cloudflare Access
        #   HyperdriveConfigAttributes.new(
        #     account_id: "a" * 32,
        #     name: "private-db",
        #     origin: {
        #       database: "mydb",
        #       host: "internal-db.example.com",
        #       user: "postgres",
        #       password: "secret",
        #       scheme: "postgres",
        #       access_client_id: "abc123",
        #       access_client_secret: "def456"
        #     }
        #   )
        class HyperdriveConfigAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute account_id
          #   @return [String] The account ID
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId

          # @!attribute name
          #   @return [String] Hyperdrive configuration name
          attribute :name, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute origin
          #   @return [HyperdriveOrigin] Origin database configuration
          attribute :origin, HyperdriveOrigin

          # @!attribute origin_connection_limit
          #   @return [Integer, nil] Maximum connections to origin database (soft limit)
          attribute :origin_connection_limit, Dry::Types['coercible.integer']
            .constrained(gteq: 1)
            .optional
            .default(nil)

          # @!attribute caching
          #   @return [HyperdriveCaching, nil] Caching configuration
          attribute :caching, HyperdriveCaching.optional.default(nil)

          # @!attribute mtls
          #   @return [HyperdriveMtls, nil] mTLS configuration
          attribute :mtls, HyperdriveMtls.optional.default(nil)

          # Check if caching is configured
          # @return [Boolean] true if caching config provided
          def has_caching?
            !caching.nil?
          end

          # Check if mTLS is configured
          # @return [Boolean] true if mTLS config provided
          def has_mtls?
            !mtls.nil?
          end

          # Check if using private database via Access
          # @return [Boolean] true if Access configured
          def private_database?
            origin.access_configured?
          end

          # Check if connection limit is set
          # @return [Boolean] true if limit configured
          def has_connection_limit?
            !origin_connection_limit.nil?
          end
        end
      end
    end
  end
end
