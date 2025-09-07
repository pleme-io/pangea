# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsRamPrincipalAssociation resources
      # Associates a principal with a RAM Resource Share.
      class RamPrincipalAssociationAttributes < Dry::Struct
        attribute :principal, Resources::Types::String
        attribute :resource_share_arn, Resources::Types::String
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_ram_principal_association

      end
    end
      end
    end
  end
end