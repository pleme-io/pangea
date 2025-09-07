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
      # Connection pooling configuration for RDS Proxy default target group
      class ProxyDefaultTargetGroupConnectionPoolConfig < Dry::Struct
        # Maximum connections as percentage of max_connections parameter (0-100)
        attribute :max_connections_percent, Resources::Types::Integer.default(100).constrained(gteq: 0, lteq: 100)

        # Maximum idle connections as percentage (0-max_connections_percent)
        attribute :max_idle_connections_percent, Resources::Types::Integer.default(50).constrained(gteq: 0, lteq: 100)

        # Session pinning filters to reduce connection reuse
        attribute :session_pinning_filters, Resources::Types::Array.of(
          Types::String.enum("EXCLUDE_VARIABLE_SETS")
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

        # Get connection efficiency ratio
        def connection_efficiency_ratio
          return 1.0 if max_connections_percent == 0
          max_idle_connections_percent.to_f / max_connections_percent
        end
      end

      # Type-safe attributes for AWS RDS Proxy Default Target Group resources
      class RdsProxyDefaultTargetGroupAttributes < Dry::Struct
        # DB proxy name this target group belongs to
        attribute :db_proxy_name, Resources::Types::String

        # Connection pooling configuration
        attribute? :connection_pool_config, ProxyDefaultTargetGroupConnectionPoolConfig.optional

        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate proxy name format
          unless attrs.db_proxy_name.match?(/^[a-zA-Z][a-zA-Z0-9-]*$/)
            raise Dry::Struct::Error, "db_proxy_name must start with a letter and contain only letters, numbers, and hyphens"
          end

          attrs
        end

        # Check if connection pool config is specified
        def has_connection_pool_config?
          !connection_pool_config.nil?
        end

        # Get effective max connections percentage
        def effective_max_connections_percent
          connection_pool_config&.max_connections_percent || 100
        end

        # Get effective max idle connections percentage
        def effective_max_idle_connections_percent
          connection_pool_config&.max_idle_connections_percent || 50
        end
      end

      # Common RDS Proxy Default Target Group configurations
      module RdsProxyDefaultTargetGroupConfigs
        # High-throughput configuration
        def self.high_throughput(proxy_name:)
          {
            db_proxy_name: proxy_name,
            connection_pool_config: {
              max_connections_percent: 100,
              max_idle_connections_percent: 25,
              session_pinning_filters: ["EXCLUDE_VARIABLE_SETS"]
            }
          }
        end

        # Connection-conservative configuration
        def self.conservative(proxy_name:)
          {
            db_proxy_name: proxy_name,
            connection_pool_config: {
              max_connections_percent: 75,
              max_idle_connections_percent: 50
            }
          }
        end
      end
    end
      end
    end
  end
end