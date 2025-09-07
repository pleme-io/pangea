# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module ElastiCacheExtended
        class CachePolicyAttributes < Dry::Struct
          attribute :name, Types::String
          attribute :comment, Types::String.optional
          attribute :default_ttl, Types::Integer.optional
          attribute :max_ttl, Types::Integer.optional
          attribute :min_ttl, Types::Integer.optional
        end

        class CachePolicyReference < ::Pangea::Resources::ResourceReference
          property :id
          property :etag
        end

        module CachePolicy
          def aws_elasticache_cache_policy(name, attributes = {})
            attrs = CachePolicyAttributes.new(attributes)
            
            synthesizer.resource :aws_elasticache_cache_policy, name do
              name attrs.name
              comment attrs.comment if attrs.comment
              default_ttl attrs.default_ttl if attrs.default_ttl
              max_ttl attrs.max_ttl if attrs.max_ttl
              min_ttl attrs.min_ttl if attrs.min_ttl
            end

            CachePolicyReference.new(name, :aws_elasticache_cache_policy, synthesizer, attrs)
          end
        end
      end
    end
  end
end