# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsEc2HostResourceGroupAssociation resources
      # Manages aws ec2 host resource group association resources.
      class AwsEc2HostResourceGroupAssociationAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_ec2_host_resource_group_association
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_ec2_host_resource_group_association
      end
    end
      end
    end
  end
end