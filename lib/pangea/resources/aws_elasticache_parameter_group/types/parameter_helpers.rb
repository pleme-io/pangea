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
        # Helper methods for ElastiCache parameter validation and categorization
        module ElastiCacheParameterHelpers
          # Common Redis parameters
          REDIS_PARAMETERS = [
            'maxmemory-policy', 'timeout', 'tcp-keepalive', 'maxclients',
            'reserved-memory', 'reserved-memory-percent', 'save',
            'rdbchecksum', 'rdbcompression', 'repl-backlog-size',
            'repl-backlog-ttl', 'repl-timeout', 'notify-keyspace-events',
            'hash-max-ziplist-entries', 'hash-max-ziplist-value',
            'list-max-ziplist-size', 'list-compress-depth',
            'set-max-intset-entries', 'zset-max-ziplist-entries',
            'zset-max-ziplist-value', 'slowlog-log-slower-than',
            'slowlog-max-len', 'lua-time-limit', 'cluster-enabled',
            'cluster-require-full-coverage', 'cluster-node-timeout'
          ].freeze

          # Common Memcached parameters
          MEMCACHED_PARAMETERS = [
            'binding_protocol', 'backlog_queue_limit', 'max_item_size',
            'chunk_size_growth_factor', 'chunk_size', 'max_simultaneous_connections',
            'minimum_allocated_slab', 'hash_algorithm'
          ].freeze

          MEMORY_RELATED_PARAMETERS = [
            'maxmemory-policy', 'reserved-memory', 'reserved-memory-percent', 'max_item_size'
          ].freeze

          PERFORMANCE_RELATED_PARAMETERS = [
            'maxclients', 'timeout', 'tcp-keepalive', 'slowlog-log-slower-than', 'chunk_size'
          ].freeze

          PERSISTENCE_RELATED_PARAMETERS = [
            'save', 'rdbchecksum', 'rdbcompression'
          ].freeze

          def redis_parameters
            REDIS_PARAMETERS
          end

          def memcached_parameters
            MEMCACHED_PARAMETERS
          end

          def memory_related_parameters
            MEMORY_RELATED_PARAMETERS
          end

          def performance_related_parameters
            PERFORMANCE_RELATED_PARAMETERS
          end

          def persistence_related_parameters
            PERSISTENCE_RELATED_PARAMETERS
          end

          # Validate parameter compatibility with engine
          def parameter_valid_for_engine?(param_name, engine_type)
            case engine_type
            when 'redis'
              redis_parameters.include?(param_name)
            when 'memcached'
              memcached_parameters.include?(param_name)
            else
              false
            end
          end

          # Get parameters by type
          def get_parameters_by_type(param_type)
            case param_type
            when :memory
              parameters.select { |p| memory_related_parameters.include?(p[:name]) }
            when :performance
              parameters.select { |p| performance_related_parameters.include?(p[:name]) }
            when :persistence
              parameters.select { |p| persistence_related_parameters.include?(p[:name]) }
            else
              parameters
            end
          end

          # Validate parameter values
          def validate_parameter_values
            errors = []

            parameters.each do |param|
              case param[:name]
              when 'maxmemory-policy'
                valid_policies = %w[
                  volatile-lru allkeys-lru volatile-lfu allkeys-lfu
                  volatile-random allkeys-random volatile-ttl noeviction
                ]
                unless valid_policies.include?(param[:value])
                  errors << "Invalid maxmemory-policy value: #{param[:value]}"
                end
              when 'timeout'
                unless param[:value].to_i >= 0
                  errors << 'timeout must be >= 0'
                end
              when 'maxclients'
                unless param[:value].to_i >= 1
                  errors << 'maxclients must be >= 1'
                end
              end
            end

            errors
          end
        end
      end
    end
  end
end
