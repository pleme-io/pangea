# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsVpcSecurityGroupEgressRule resources
      # Manages aws vpc security group egress rule resources.
      class AwsVpcSecurityGroupEgressRuleAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_vpc_security_group_egress_rule
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_vpc_security_group_egress_rule
      end
    end
      end
    end
  end
end