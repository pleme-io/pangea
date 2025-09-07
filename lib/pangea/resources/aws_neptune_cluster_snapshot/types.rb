# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsNeptuneClusterSnapshot resources
      # Manages a Neptune cluster snapshot.
      class NeptuneClusterSnapshotAttributes < Dry::Struct
        attribute :db_cluster_identifier, Resources::Types::String
        attribute :db_cluster_snapshot_identifier, Resources::Types::String
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_neptune_cluster_snapshot

      end
    end
      end
    end
  end
end