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
        class ReservedCacheNodeAttributes < Dry::Struct
          attribute :reserved_cache_nodes_offering_id, Types::String
          attribute :reserved_cache_node_id, Types::String.optional
          attribute :cache_node_count, Types::Integer.default(1)
          attribute :tags, Types::Hash.default({})
        end

        class ReservedCacheNodeReference < ::Pangea::Resources::ResourceReference
          property :id
          property :arn
        end

        module ReservedCacheNode
          def aws_elasticache_reserved_cache_node(name, attributes = {})
            attrs = ReservedCacheNodeAttributes.new(attributes)
            
            synthesizer.resource :aws_elasticache_reserved_cache_node, name do
              reserved_cache_nodes_offering_id attrs.reserved_cache_nodes_offering_id
              reserved_cache_node_id attrs.reserved_cache_node_id if attrs.reserved_cache_node_id
              cache_node_count attrs.cache_node_count
              tags attrs.tags unless attrs.tags.empty?
            end

            ReservedCacheNodeReference.new(name, :aws_elasticache_reserved_cache_node, synthesizer, attrs)
          end
        end
      end
    end
  end
end