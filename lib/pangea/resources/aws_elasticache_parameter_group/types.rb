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
      # Type-safe attributes for AWS ElastiCache Parameter Group resources
      class ElastiCacheParameterGroupAttributes < Dry::Struct
        # Name of the parameter group
        attribute :name, Resources::Types::String

        # Description of the parameter group
        attribute :description, Resources::Types::String.optional

        # Cache parameter group family (e.g., "redis7.x", "memcached1.6")
        attribute :family, Resources::Types::String.enum(
          # Redis families
          "redis2.6", "redis2.8", "redis3.2", "redis4.0", "redis5.0", "redis6.x", "redis7.x",
          # Memcached families  
          "memcached1.4", "memcached1.5", "memcached1.6"
        )

        # Parameters to apply to the parameter group
        attribute :parameters, Resources::Types::Array.of(
          Types::Hash.schema(
            name: Types::String,
            value: Types::String
          )
        ).default([].freeze)

        # Tags to apply to the parameter group
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate parameter group name format
          unless attrs.name.match?(/\A[a-zA-Z0-9\-]+\z/)
            raise Dry::Struct::Error, "Parameter group name must contain only letters, numbers, and hyphens"
          end

          # Validate name length
          if attrs.name.length < 1 || attrs.name.length > 255
            raise Dry::Struct::Error, "Parameter group name must be between 1 and 255 characters"
          end

          # Cannot start with a number or hyphen
          if attrs.name.match?(/\A[\d\-]/)
            raise Dry::Struct::Error, "Parameter group name cannot start with a number or hyphen"
          end

          # Cannot end with hyphen
          if attrs.name.end_with?('-')
            raise Dry::Struct::Error, "Parameter group name cannot end with a hyphen"
          end

          # Validate engine compatibility between family and parameters
          engine_type = attrs.engine_type_from_family
          attrs.parameters.each do |param|
            unless attrs.parameter_valid_for_engine?(param[:name], engine_type)
              raise Dry::Struct::Error, "Parameter '#{param[:name]}' is not valid for #{engine_type} engine"
            end
          end

          # Default description if not provided
          unless attrs.description
            attrs = attrs.copy_with(description: "Custom parameter group for #{attrs.family}")
          end

          attrs
        end

        # Helper methods
        def engine_type_from_family
          family.start_with?('redis') ? 'redis' : 'memcached'
        end

        def is_redis_family?
          family.start_with?('redis')
        end

        def is_memcached_family?
          family.start_with?('memcached')
        end

        def family_version
          family.sub(/^(redis|memcached)/, '')
        end

        def parameter_count
          parameters.length
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

        # Common Redis parameters
        def redis_parameters
          [
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
          ]
        end

        # Common Memcached parameters
        def memcached_parameters
          [
            'binding_protocol', 'backlog_queue_limit', 'max_item_size',
            'chunk_size_growth_factor', 'chunk_size', 'max_simultaneous_connections',
            'minimum_allocated_slab', 'hash_algorithm'
          ]
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

        def memory_related_parameters
          ['maxmemory-policy', 'reserved-memory', 'reserved-memory-percent', 'max_item_size']
        end

        def performance_related_parameters
          ['maxclients', 'timeout', 'tcp-keepalive', 'slowlog-log-slower-than', 'chunk_size']
        end

        def persistence_related_parameters
          ['save', 'rdbchecksum', 'rdbcompression']
        end

        # Validate parameter values
        def validate_parameter_values
          errors = []
          
          parameters.each do |param|
            case param[:name]
            when 'maxmemory-policy'
              unless %w[volatile-lru allkeys-lru volatile-lfu allkeys-lfu volatile-random allkeys-random volatile-ttl noeviction].include?(param[:value])
                errors << "Invalid maxmemory-policy value: #{param[:value]}"
              end
            when 'timeout'
              unless param[:value].to_i >= 0
                errors << "timeout must be >= 0"
              end
            when 'maxclients'
              unless param[:value].to_i >= 1
                errors << "maxclients must be >= 1"
              end
            end
          end
          
          errors
        end

        # Check if this is a default parameter group
        def is_default_group?
          name.start_with?('default.')
        end

        # Cost implications (parameter groups themselves are free)
        def has_cost_implications?
          false
        end

        def estimated_monthly_cost
          "$0.00/month (parameter groups are free)"
        end
      end

      # Common ElastiCache parameter group configurations
      module ElastiCacheParameterGroupConfigs
        # Redis performance optimized configuration
        def self.redis_performance(name, family: "redis7.x")
          {
            name: name,
            family: family,
            description: "Performance optimized Redis parameter group",
            parameters: [
              { name: "maxmemory-policy", value: "allkeys-lru" },
              { name: "timeout", value: "300" },
              { name: "tcp-keepalive", value: "60" },
              { name: "reserved-memory-percent", value: "10" }
            ]
          }
        end

        # Redis persistence optimized configuration
        def self.redis_persistence(name, family: "redis7.x")
          {
            name: name,
            family: family,
            description: "Persistence optimized Redis parameter group",
            parameters: [
              { name: "save", value: "900 1 300 10 60 10000" },
              { name: "rdbcompression", value: "yes" },
              { name: "rdbchecksum", value: "yes" },
              { name: "maxmemory-policy", value: "allkeys-lru" }
            ]
          }
        end

        # Redis cluster mode configuration
        def self.redis_cluster(name, family: "redis7.x")
          {
            name: name,
            family: family,
            description: "Redis cluster mode parameter group",
            parameters: [
              { name: "cluster-enabled", value: "yes" },
              { name: "cluster-require-full-coverage", value: "no" },
              { name: "cluster-node-timeout", value: "15000" },
              { name: "maxmemory-policy", value: "allkeys-lru" }
            ]
          }
        end

        # Memcached performance configuration
        def self.memcached_performance(name, family: "memcached1.6")
          {
            name: name,
            family: family,
            description: "Performance optimized Memcached parameter group",
            parameters: [
              { name: "max_item_size", value: "134217728" },  # 128MB
              { name: "chunk_size_growth_factor", value: "1.25" },
              { name: "max_simultaneous_connections", value: "65000" }
            ]
          }
        end

        # Redis memory optimized configuration
        def self.redis_memory_optimized(name, family: "redis7.x")
          {
            name: name,
            family: family,
            description: "Memory optimized Redis parameter group",
            parameters: [
              { name: "maxmemory-policy", value: "volatile-lru" },
              { name: "reserved-memory-percent", value: "25" },
              { name: "hash-max-ziplist-entries", value: "1024" },
              { name: "hash-max-ziplist-value", value: "64" },
              { name: "list-max-ziplist-size", value: "-2" },
              { name: "set-max-intset-entries", value: "512" }
            ]
          }
        end
      end
    end
      end
    end
  end
end