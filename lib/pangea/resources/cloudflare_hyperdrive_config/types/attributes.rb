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

module Pangea
  module Resources
    module Cloudflare
      module Types
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
