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
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module ElastiCacheExtended
        # ElastiCache Serverless cache configuration
        class ServerlessCacheAttributes < Dry::Struct
          attribute :cache_name, Types::String
          attribute :description, Types::String.optional
          attribute :engine, Types::String.default('redis') # 'redis', 'memcached'
          attribute :major_engine_version, Types::String.optional
          
          attribute? :cache_usage_limits do
            attribute? :data_storage do
              attribute :maximum, Types::Integer
              attribute :unit, Types::String.default('GB')
            end
            attribute? :ecpu_per_second do
              attribute :maximum, Types::Integer
            end
          end

          attribute :kms_key_id, Types::String.optional
          attribute :security_group_ids, Types::Array.of(Types::String).default([])
          attribute :subnet_ids, Types::Array.of(Types::String).default([])
          attribute :user_group_id, Types::String.optional
          
          attribute? :daily_snapshot_time, Types::String
          attribute? :snapshot_retention_limit, Types::Integer.default(1)
          attribute? :final_snapshot_name, Types::String

          attribute :tags, Types::Hash.default({})
        end

        # ElastiCache Serverless cache reference
        class ServerlessCacheReference < ::Pangea::Resources::ResourceReference
          property :id
          property :cache_name
          property :arn
          property :engine
          property :full_engine_version
          property :status
          property :endpoint do
            property :address
            property :port
          end
          property :reader_endpoint do
            property :address
            property :port
          end

          def redis?
            engine == 'redis'
          end

          def memcached?
            engine == 'memcached'
          end

          def available?
            status == 'available'
          end

          def creating?
            status == 'creating'
          end

          def cache_usage_limits
            get_attribute(:cache_usage_limits)
          end

          def max_data_storage_gb
            limits = cache_usage_limits
            limits&.data_storage&.maximum
          end

          def max_ecpu_per_second
            limits = cache_usage_limits
            limits&.ecpu_per_second&.maximum
          end

          def primary_endpoint
            "#{endpoint.address}:#{endpoint.port}" if endpoint
          end

          def reader_endpoint_url
            "#{reader_endpoint.address}:#{reader_endpoint.port}" if reader_endpoint
          end

          def connection_string(read_only: false)
            endpoint_to_use = read_only && reader_endpoint ? reader_endpoint : endpoint
            return nil unless endpoint_to_use
            
            if redis?
              "redis://#{endpoint_to_use.address}:#{endpoint_to_use.port}"
            else
              "#{endpoint_to_use.address}:#{endpoint_to_use.port}"
            end
          end

          # Helper for auto-scaling characteristics
          def serverless_scaling_enabled?
            limits = cache_usage_limits
            limits&.data_storage&.maximum && limits&.ecpu_per_second&.maximum
          end
        end

        module ServerlessCache
          # Creates an ElastiCache Serverless cache
          #
          # @param name [Symbol] The serverless cache name
          # @param attributes [Hash] Serverless cache configuration
          # @return [ServerlessCacheReference] Reference to the serverless cache
          def aws_elasticache_serverless_cache(name, attributes = {})
            serverless_attrs = ServerlessCacheAttributes.new(attributes)
            
            synthesizer.resource :aws_elasticache_serverless_cache, name do
              cache_name serverless_attrs.cache_name
              description serverless_attrs.description if serverless_attrs.description
              engine serverless_attrs.engine
              major_engine_version serverless_attrs.major_engine_version if serverless_attrs.major_engine_version

              if serverless_attrs.cache_usage_limits
                cache_usage_limits do
                  if serverless_attrs.cache_usage_limits.data_storage
                    data_storage do
                      maximum serverless_attrs.cache_usage_limits.data_storage.maximum
                      unit serverless_attrs.cache_usage_limits.data_storage.unit
                    end
                  end

                  if serverless_attrs.cache_usage_limits.ecpu_per_second
                    ecpu_per_second do
                      maximum serverless_attrs.cache_usage_limits.ecpu_per_second.maximum
                    end
                  end
                end
              end

              kms_key_id serverless_attrs.kms_key_id if serverless_attrs.kms_key_id
              security_group_ids serverless_attrs.security_group_ids unless serverless_attrs.security_group_ids.empty?
              subnet_ids serverless_attrs.subnet_ids unless serverless_attrs.subnet_ids.empty?
              user_group_id serverless_attrs.user_group_id if serverless_attrs.user_group_id
              
              daily_snapshot_time serverless_attrs.daily_snapshot_time if serverless_attrs.daily_snapshot_time
              snapshot_retention_limit serverless_attrs.snapshot_retention_limit if serverless_attrs.snapshot_retention_limit
              final_snapshot_name serverless_attrs.final_snapshot_name if serverless_attrs.final_snapshot_name

              tags serverless_attrs.tags unless serverless_attrs.tags.empty?
            end

            ServerlessCacheReference.new(name, :aws_elasticache_serverless_cache, synthesizer, serverless_attrs)
          end
        end
      end
    end
  end
end