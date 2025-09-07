# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsNeptuneClusterEndpoint resources
      # Provides a Neptune cluster endpoint resource.
      class NeptuneClusterEndpointAttributes < Dry::Struct
        attribute :cluster_endpoint_identifier, Resources::Types::String
        attribute :cluster_identifier, Resources::Types::String
        attribute :endpoint_type, Resources::Types::String
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_neptune_cluster_endpoint

      end
    end
      end
    end
  end
end