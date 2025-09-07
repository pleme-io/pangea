# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsEc2TransitGatewayMulticastDomainAssociation resources
      # Manages aws ec2 transit gateway multicast domain association resources.
      class AwsEc2TransitGatewayMulticastDomainAssociationAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_ec2_transit_gateway_multicast_domain_association
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_ec2_transit_gateway_multicast_domain_association
      end
    end
      end
    end
  end
end