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
        # Common ElastiCache configurations
        module ElastiCacheConfigs
          module_function

          # Redis default configuration
          def redis(version: '7.0', node_type: 'cache.t4g.micro')
            {
              engine: 'redis',
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
          def memcached(version: '1.6.17', node_type: 'cache.t4g.micro', num_nodes: 2)
            {
              engine: 'memcached',
              engine_version: version,
              node_type: node_type,
              num_cache_nodes: num_nodes,
              port: 11_211,
              auto_minor_version_upgrade: true
            }
          end

          # High-performance Redis configuration
          def redis_high_performance(node_type: 'cache.r6g.large')
            {
              engine: 'redis',
              engine_version: '7.0',
              node_type: node_type,
              num_cache_nodes: 1,
              port: 6379,
              at_rest_encryption_enabled: true,
              transit_encryption_enabled: true,
              snapshot_retention_limit: 7,
              auto_minor_version_upgrade: false
            }
          end
        end
      end
    end
  end
end
