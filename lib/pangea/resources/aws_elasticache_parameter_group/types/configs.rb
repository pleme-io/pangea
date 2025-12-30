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
        # Common ElastiCache parameter group configurations
        module ElastiCacheParameterGroupConfigs
          # Redis performance optimized configuration
          def self.redis_performance(name, family: 'redis7.x')
            {
              name: name,
              family: family,
              description: 'Performance optimized Redis parameter group',
              parameters: [
                { name: 'maxmemory-policy', value: 'allkeys-lru' },
                { name: 'timeout', value: '300' },
                { name: 'tcp-keepalive', value: '60' },
                { name: 'reserved-memory-percent', value: '10' }
              ]
            }
          end

          # Redis persistence optimized configuration
          def self.redis_persistence(name, family: 'redis7.x')
            {
              name: name,
              family: family,
              description: 'Persistence optimized Redis parameter group',
              parameters: [
                { name: 'save', value: '900 1 300 10 60 10000' },
                { name: 'rdbcompression', value: 'yes' },
                { name: 'rdbchecksum', value: 'yes' },
                { name: 'maxmemory-policy', value: 'allkeys-lru' }
              ]
            }
          end

          # Redis cluster mode configuration
          def self.redis_cluster(name, family: 'redis7.x')
            {
              name: name,
              family: family,
              description: 'Redis cluster mode parameter group',
              parameters: [
                { name: 'cluster-enabled', value: 'yes' },
                { name: 'cluster-require-full-coverage', value: 'no' },
                { name: 'cluster-node-timeout', value: '15000' },
                { name: 'maxmemory-policy', value: 'allkeys-lru' }
              ]
            }
          end

          # Memcached performance configuration
          def self.memcached_performance(name, family: 'memcached1.6')
            {
              name: name,
              family: family,
              description: 'Performance optimized Memcached parameter group',
              parameters: [
                { name: 'max_item_size', value: '134217728' }, # 128MB
                { name: 'chunk_size_growth_factor', value: '1.25' },
                { name: 'max_simultaneous_connections', value: '65000' }
              ]
            }
          end

          # Redis memory optimized configuration
          def self.redis_memory_optimized(name, family: 'redis7.x')
            {
              name: name,
              family: family,
              description: 'Memory optimized Redis parameter group',
              parameters: [
                { name: 'maxmemory-policy', value: 'volatile-lru' },
                { name: 'reserved-memory-percent', value: '25' },
                { name: 'hash-max-ziplist-entries', value: '1024' },
                { name: 'hash-max-ziplist-value', value: '64' },
                { name: 'list-max-ziplist-size', value: '-2' },
                { name: 'set-max-intset-entries', value: '512' }
              ]
            }
          end
        end
      end
    end
  end
end
