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
    module AWS
      module Types
        # Validation logic for ElastiCache cluster attributes
        module ElastiCacheValidators
          module_function

          def validate_and_apply_defaults(attrs)
            validate_availability_zones(attrs)

            case attrs.engine
            when 'redis'
              attrs = validate_redis(attrs)
            when 'memcached'
              validate_memcached(attrs)
              attrs = attrs.copy_with(port: attrs.port || 11_211)
            end

            attrs
          end

          def validate_redis(attrs)
            validate_redis_num_cache_nodes(attrs)
            validate_redis_auth_token(attrs)
            validate_redis_encryption(attrs)
            attrs.copy_with(port: attrs.port || 6379)
          end

          def validate_redis_num_cache_nodes(attrs)
            return unless attrs.num_cache_nodes > 1

            raise Dry::Struct::Error,
                  'Redis clusters should use num_cache_nodes=1 and replication groups for scaling'
          end

          def validate_redis_auth_token(attrs)
            return unless attrs.auth_token && !attrs.transit_encryption_enabled

            raise Dry::Struct::Error, 'Auth token requires transit_encryption_enabled=true'
          end

          def validate_redis_encryption(attrs)
            return unless attrs.at_rest_encryption_enabled && !attrs.engine_supports_encryption?

            raise Dry::Struct::Error, 'At-rest encryption requires Redis 3.2.6 or later'
          end

          def validate_memcached(attrs)
            validate_memcached_snapshots(attrs)
            validate_memcached_encryption(attrs)
            validate_memcached_auth(attrs)
            validate_memcached_final_snapshot(attrs)
            validate_memcached_multi_az(attrs)
          end

          def validate_memcached_snapshots(attrs)
            has_snapshot_config = attrs.snapshot_arns || attrs.snapshot_name ||
                                  attrs.snapshot_window || attrs.snapshot_retention_limit.positive?
            return unless has_snapshot_config

            raise Dry::Struct::Error, 'Snapshot configuration is only available for Redis'
          end

          def validate_memcached_encryption(attrs)
            return unless attrs.transit_encryption_enabled || attrs.at_rest_encryption_enabled

            raise Dry::Struct::Error, 'Encryption is only available for Redis'
          end

          def validate_memcached_auth(attrs)
            return unless attrs.auth_token

            raise Dry::Struct::Error, 'Auth token is only available for Redis'
          end

          def validate_memcached_final_snapshot(attrs)
            return unless attrs.final_snapshot_identifier

            raise Dry::Struct::Error, 'Final snapshot is only available for Redis'
          end

          def validate_memcached_multi_az(attrs)
            return unless attrs.preferred_availability_zones.any? && attrs.num_cache_nodes < 2

            raise Dry::Struct::Error, 'Multi-AZ deployment requires at least 2 cache nodes for Memcached'
          end

          def validate_availability_zones(attrs)
            return unless attrs.availability_zone && attrs.preferred_availability_zones.any?

            raise Dry::Struct::Error, 'Cannot specify both availability_zone and preferred_availability_zones'
          end
        end
      end
    end
  end
end
