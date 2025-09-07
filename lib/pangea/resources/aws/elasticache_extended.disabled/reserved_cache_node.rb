# frozen_string_literal: true

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