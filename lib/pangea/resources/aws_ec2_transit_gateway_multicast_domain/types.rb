# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsEc2TransitGatewayMulticastDomain resources
      # Manages aws ec2 transit gateway multicast domain resources.
      class AwsEc2TransitGatewayMulticastDomainAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_ec2_transit_gateway_multicast_domain
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_ec2_transit_gateway_multicast_domain
      end
    end
      end
    end
  end
end