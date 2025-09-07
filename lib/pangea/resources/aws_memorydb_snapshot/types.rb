# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsMemorydbSnapshot resources
      # Provides a MemoryDB Snapshot resource.
      class MemorydbSnapshotAttributes < Dry::Struct
        attribute :cluster_name, Resources::Types::String
        attribute :name, Resources::Types::String
        attribute :name_prefix, Resources::Types::String.optional
        attribute :kms_key_id, Resources::Types::String.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_memorydb_snapshot

      end
    end
      end
    end
  end
end