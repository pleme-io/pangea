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
      end
    end
  end
end
