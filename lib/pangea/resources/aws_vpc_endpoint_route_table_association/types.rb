# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsVpcEndpointRouteTableAssociation resources
      # Manages aws vpc endpoint route table association resources.
      class AwsVpcEndpointRouteTableAssociationAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_vpc_endpoint_route_table_association
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_vpc_endpoint_route_table_association
      end
    end
      end
    end
  end
end