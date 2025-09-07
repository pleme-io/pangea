# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsDefaultVpcDhcpOptions resources
      # Manages aws default vpc dhcp options resources.
      class AwsDefaultVpcDhcpOptionsAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_default_vpc_dhcp_options
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_default_vpc_dhcp_options
      end
    end
      end
    end
  end
end