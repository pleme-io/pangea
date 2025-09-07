# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsDefaultRouteTable resources
      # Manages aws default route table resources.
      class AwsDefaultRouteTableAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_default_route_table
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_default_route_table
      end
    end
      end
    end
  end
end