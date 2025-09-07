# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsMemorydbSubnetGroup resources
      # Provides a MemoryDB Subnet Group resource.
      class MemorydbSubnetGroupAttributes < Dry::Struct
        attribute :name, Resources::Types::String
        attribute :subnet_ids, Resources::Types::Array.of(Types::String).default([].freeze)
        attribute :description, Resources::Types::String.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_memorydb_subnet_group

      end
    end
      end
    end
  end
end