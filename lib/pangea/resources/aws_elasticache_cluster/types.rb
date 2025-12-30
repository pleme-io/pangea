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

require_relative 'types/node_types'
require_relative 'types/validators'
require_relative 'types/helpers'
require_relative 'types/configs'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS ElastiCache Cluster resources
        class ElastiCacheClusterAttributes < Dry::Struct
          include ElastiCacheHelpers

          transform_keys(&:to_sym)

          # Cluster identifier (required)
          attribute :cluster_id, Pangea::Resources::Types::String

          # Engine type
          attribute :engine, Pangea::Resources::Types::String.constrained(included_in: %w[redis memcached])

          # Node type (instance class)
          attribute :node_type, Pangea::Resources::Types::String.constrained(
            included_in: ElastiCacheNodeTypes::ALL
          )

          # Number of cache nodes
          attribute :num_cache_nodes, Pangea::Resources::Types::Integer.default(1).constrained(gteq: 1, lteq: 40)

          # Engine version (optional, uses default if not specified)
          attribute? :engine_version, Pangea::Resources::Types::String.optional

          # Parameter group name
          attribute? :parameter_group_name, Pangea::Resources::Types::String.optional

          # Port number
          attribute? :port, Pangea::Resources::Types::Integer.optional.constrained(gteq: 1024, lteq: 65_535)

          # Subnet group name
          attribute? :subnet_group_name, Pangea::Resources::Types::String.optional

          # Security group IDs
          attribute :security_group_ids,
                    Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)

          # Availability zone (single AZ placement)
          attribute? :availability_zone, Pangea::Resources::Types::String.optional

          # Preferred availability zones (for multi-AZ)
          attribute :preferred_availability_zones,
                    Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)

          # Maintenance window (Format: "ddd:hh24:mi-ddd:hh24:mi")
          attribute? :maintenance_window, Pangea::Resources::Types::String.optional

          # Notification topic ARN
          attribute? :notification_topic_arn, Pangea::Resources::Types::String.optional

          # Auto minor version upgrade
          attribute :auto_minor_version_upgrade, Pangea::Resources::Types::Bool.default(true)

          # Snapshot configuration (Redis only)
          attribute? :snapshot_arns, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional
          attribute? :snapshot_name, Pangea::Resources::Types::String.optional
          attribute? :snapshot_window, Pangea::Resources::Types::String.optional
          attribute :snapshot_retention_limit, Pangea::Resources::Types::Integer.default(0).constrained(gteq: 0, lteq: 35)

          # Log delivery configuration
          attribute :log_delivery_configuration, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash
          ).default([].freeze)

          # Transit encryption (Redis 6.0+ only)
          attribute? :transit_encryption_enabled, Pangea::Resources::Types::Bool.optional

          # At-rest encryption (Redis only)
          attribute? :at_rest_encryption_enabled, Pangea::Resources::Types::Bool.optional

          # Auth token (Redis only, requires transit encryption)
          attribute? :auth_token, Pangea::Resources::Types::String.optional

          # Apply changes immediately
          attribute :apply_immediately, Pangea::Resources::Types::Bool.default(false)

          # Tags to apply to the cluster
          attribute :tags, Pangea::Resources::Types::Hash.default({}.freeze)

          # Final snapshot identifier (Redis only)
          attribute? :final_snapshot_identifier, Pangea::Resources::Types::String.optional

          # Custom validation with engine-specific rules
          def self.new(attributes = {})
            attrs = super(attributes)
            ElastiCacheValidators.validate_and_apply_defaults(attrs)
          end
        end
      end
    end
  end
end
