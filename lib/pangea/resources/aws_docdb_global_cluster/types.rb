# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsDocdbGlobalCluster resources
      # Provides a DocumentDB Global Cluster resource.
      class DocdbGlobalClusterAttributes < Dry::Struct
        attribute :global_cluster_identifier, Resources::Types::String
        attribute :source_db_cluster_identifier, Resources::Types::String.optional
        attribute :engine, Resources::Types::String.optional
        attribute :engine_version, Resources::Types::String.optional
        attribute :database_name, Resources::Types::String.optional
        attribute :deletion_protection, Resources::Types::Bool.optional
        attribute :storage_encrypted, Resources::Types::Bool.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_docdb_global_cluster

      end
    end
      end
    end
  end
end