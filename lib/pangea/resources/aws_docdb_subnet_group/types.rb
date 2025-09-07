# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsDocdbSubnetGroup resources
      # Provides a DocumentDB subnet group resource.
      class DocdbSubnetGroupAttributes < Dry::Struct
        attribute :name, Resources::Types::String
        attribute :description, Resources::Types::String.optional
        attribute :subnet_ids, Resources::Types::Array.of(Types::String).default([].freeze)
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_docdb_subnet_group

      end
    end
      end
    end
  end
end