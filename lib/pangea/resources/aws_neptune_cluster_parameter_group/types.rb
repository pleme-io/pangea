# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsNeptuneClusterParameterGroup resources
      # Provides a Neptune Cluster Parameter Group resource.
      class NeptuneClusterParameterGroupAttributes < Dry::Struct
        attribute :name, Resources::Types::String
        attribute :family, Resources::Types::String
        attribute :description, Resources::Types::String.optional
        attribute :parameter, Resources::Types::Array.of(Types::Hash).default([].freeze).optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_neptune_cluster_parameter_group

      end
    end
      end
    end
  end
end