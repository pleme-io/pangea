# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsMemorydbMultiRegionCluster resources
      # Provides a MemoryDB Multi-Region Cluster resource.
      class MemorydbMultiRegionClusterAttributes < Dry::Struct
        attribute :cluster_name_suffix, Resources::Types::String
        attribute :node_type, Resources::Types::String
        attribute :num_shards, Resources::Types::Integer.optional
        attribute :description, Resources::Types::String.optional
        attribute :engine, Resources::Types::String.optional
        attribute :engine_version, Resources::Types::String.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_memorydb_multi_region_cluster

      end
    end
      end
    end
  end
end