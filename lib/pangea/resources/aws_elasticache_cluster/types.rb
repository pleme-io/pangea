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
    module AWS
      module Types
        # Type-safe attributes for AWS ElastiCache Cluster resources
        class ElastiCacheClusterAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Cluster identifier (required)
          attribute :cluster_id, Pangea::Resources::Types::String

          # Engine type
          attribute :engine, Pangea::Resources::Types::String.constrained(included_in: ["redis", "memcached"])

          # Node type (instance class)
          attribute :node_type, Pangea::Resources::Types::String.constrained(included_in: [
            # Burstable Performance
            "cache.t4g.nano", "cache.t4g.micro", "cache.t4g.small", "cache.t4g.medium",
            "cache.t3.micro", "cache.t3.small", "cache.t3.medium",
            # General Purpose
            "cache.m6g.large", "cache.m6g.xlarge", "cache.m6g.2xlarge", "cache.m6g.4xlarge",
            "cache.m6g.8xlarge", "cache.m6g.12xlarge", "cache.m6g.16xlarge",
            "cache.m5.large", "cache.m5.xlarge", "cache.m5.2xlarge", "cache.m5.4xlarge",
            "cache.m5.12xlarge", "cache.m5.24xlarge",
            # Memory Optimized
            "cache.r6g.large", "cache.r6g.xlarge", "cache.r6g.2xlarge", "cache.r6g.4xlarge",
            "cache.r6g.8xlarge", "cache.r6g.12xlarge", "cache.r6g.16xlarge",
            "cache.r5.large", "cache.r5.xlarge", "cache.r5.2xlarge", "cache.r5.4xlarge",
            "cache.r5.12xlarge", "cache.r5.24xlarge"
          ])

          # Number of cache nodes (Memcached only, Redis uses num_cache_nodes=1 and replication_group for scaling)
          attribute :num_cache_nodes, Pangea::Resources::Types::Integer.default(1).constrained(gteq: 1, lteq: 40)

          # Engine version (optional, uses default if not specified)
          attribute? :engine_version, Pangea::Resources::Types::String.optional

          # Parameter group name
          attribute? :parameter_group_name, Pangea::Resources::Types::String.optional

          # Port number
          attribute? :port, Pangea::Resources::Types::Integer.optional.constrained(gteq: 1024, lteq: 65535)

          # Subnet group name
          attribute? :subnet_group_name, Pangea::Resources::Types::String.optional

          # Security group IDs
          attribute :security_group_ids, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)

          # Availability zone (single AZ placement)
          attribute? :availability_zone, Pangea::Resources::Types::String.optional

          # Preferred availability zones (for multi-AZ)
          attribute :preferred_availability_zones, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)

          # Maintenance window
          attribute? :maintenance_window, Pangea::Resources::Types::String.optional  # Format: "ddd:hh24:mi-ddd:hh24:mi"

          # Notification topic ARN
          attribute? :notification_topic_arn, Pangea::Resources::Types::String.optional

          # Auto minor version upgrade
          attribute :auto_minor_version_upgrade, Pangea::Resources::Types::Bool.default(true)

          # Snapshot configuration (Redis only)
          attribute? :snapshot_arns, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional
          attribute? :snapshot_name, Pangea::Resources::Types::String.optional
          attribute? :snapshot_window, Pangea::Resources::Types::String.optional  # Format: "hh24:mi-hh24:mi"
          attribute :snapshot_retention_limit, Pangea::Resources::Types::Integer.default(0).constrained(gteq: 0, lteq: 35)

          # Log delivery configuration
          attribute :log_delivery_configuration, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::Hash).default([].freeze)

          # Transit encryption (Redis 6.0+ only)
          attribute? :transit_encryption_enabled, Pangea::Resources::Types::Bool.optional

          # At-rest encryption (Redis only)
          attribute? :at_rest_encryption_enabled, Pangea::Resources::Types::Bool.optional

          # Auth token (Redis only, requires transit encryption)
          attribute? :auth_token, Pangea::Resources::Types::String.optional

          # Apply changes immediately
          attribute :apply_immediately, Pangea::Resources::Types::Bool.default(false)

          # Tags to apply to the cluster
          attribute :tags, Pangea::Resources::Types::Hash.default({})

          # Final snapshot identifier (Redis only)
          attribute? :final_snapshot_identifier, Pangea::Resources::Types::String.optional

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
          
            # Engine-specific validations
            if attrs.engine == "redis"
              # Redis specific validations
              if attrs.num_cache_nodes > 1
                raise Dry::Struct::Error, "Redis clusters should use num_cache_nodes=1 and replication groups for scaling"
              end
            
              # Auth token requires transit encryption
              if attrs.auth_token && !attrs.transit_encryption_enabled
                raise Dry::Struct::Error, "Auth token requires transit_encryption_enabled=true"
              end
            
              # Encryption validations
              if attrs.at_rest_encryption_enabled && !attrs.engine_supports_encryption?
                raise Dry::Struct::Error, "At-rest encryption requires Redis 3.2.6 or later"
              end
            
              # Port default for Redis
              attrs = attrs.copy_with(port: attrs.port || 6379)
            
            elsif attrs.engine == "memcached"
              # Memcached specific validations
              if attrs.snapshot_arns || attrs.snapshot_name || attrs.snapshot_window || attrs.snapshot_retention_limit > 0
                raise Dry::Struct::Error, "Snapshot configuration is only available for Redis"
              end
            
              if attrs.transit_encryption_enabled || attrs.at_rest_encryption_enabled
                raise Dry::Struct::Error, "Encryption is only available for Redis"
              end
            
              if attrs.auth_token
                raise Dry::Struct::Error, "Auth token is only available for Redis"
              end
            
              if attrs.final_snapshot_identifier
                raise Dry::Struct::Error, "Final snapshot is only available for Redis"
              end
            
              # Port default for Memcached
              attrs = attrs.copy_with(port: attrs.port || 11211)
            end

            # AZ validations
            if attrs.availability_zone && attrs.preferred_availability_zones.any?
              raise Dry::Struct::Error, "Cannot specify both availability_zone and preferred_availability_zones"
            end

            # Multi-AZ requires multiple nodes for Memcached
            if attrs.engine == "memcached" && attrs.preferred_availability_zones.any? && attrs.num_cache_nodes < 2
              raise Dry::Struct::Error, "Multi-AZ deployment requires at least 2 cache nodes for Memcached"
            end

            attrs
          end

          # Helper methods
          def is_redis?
            engine == "redis"
          end

          def is_memcached?
            engine == "memcached"
          end

          def default_port
            is_redis? ? 6379 : 11211
          end

          def supports_encryption?
            is_redis?
          end

          def supports_backup?
            is_redis?
          end

          def supports_auth?
            is_redis?
          end

          def engine_supports_encryption?
            # Redis 3.2.6+ supports at-rest encryption
            return false unless is_redis?
            return true unless engine_version  # Assume latest version supports it
            
            version_parts = engine_version.split('.').map(&:to_i)
            major, minor, patch = version_parts[0], version_parts[1], version_parts[2] || 0
            
            major > 3 || (major == 3 && minor > 2) || (major == 3 && minor == 2 && patch >= 6)
          end

          def is_cluster_mode?
            # This would be true for Redis Cluster mode (replication groups)
            # For single-node clusters, this is false
            false
          end

          def estimated_monthly_cost
            # Base hourly rates for different node types (simplified)
            hourly_rate = case node_type
                         when /t4g.nano/ then 0.016
                         when /t4g.micro/ then 0.032
                         when /t4g.small/ then 0.064
                         when /t4g.medium/ then 0.128
                         when /t3.micro/ then 0.017
                         when /t3.small/ then 0.034
                         when /t3.medium/ then 0.068
                         when /m6g.large/ then 0.077
                         when /m6g.xlarge/ then 0.154
                         when /m5.large/ then 0.083
                         when /m5.xlarge/ then 0.166
                         when /r6g.large/ then 0.101
                         when /r6g.xlarge/ then 0.202
                         when /r5.large/ then 0.126
                         when /r5.xlarge/ then 0.252
                         else 0.100  # Default estimate
                         end

            # Monthly cost (730 hours) * number of nodes
            total_cost = hourly_rate * 730 * num_cache_nodes

            "~$#{total_cost.round(2)}/month"
          end
        end

        # Common ElastiCache configurations
        module ElastiCacheConfigs
          # Redis default configuration
          def self.redis(version: "7.0", node_type: "cache.t4g.micro")
            {
              engine: "redis",
              engine_version: version,
              node_type: node_type,
              num_cache_nodes: 1,
              port: 6379,
              at_rest_encryption_enabled: true,
              transit_encryption_enabled: true,
              auto_minor_version_upgrade: true
            }
          end

          # Memcached default configuration
          def self.memcached(version: "1.6.17", node_type: "cache.t4g.micro", num_nodes: 2)
            {
              engine: "memcached",
              engine_version: version,
              node_type: node_type,
              num_cache_nodes: num_nodes,
              port: 11211,
              auto_minor_version_upgrade: true
            }
          end

          # High-performance Redis configuration
          def self.redis_high_performance(node_type: "cache.r6g.large")
            {
              engine: "redis",
              engine_version: "7.0",
              node_type: node_type,
              num_cache_nodes: 1,
              port: 6379,
              at_rest_encryption_enabled: true,
              transit_encryption_enabled: true,
              snapshot_retention_limit: 7,
              auto_minor_version_upgrade: false  # Control upgrades manually
            }
          end
        end
      end
    end
  end
end