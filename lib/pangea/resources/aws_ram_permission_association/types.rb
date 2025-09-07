# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsRamPermissionAssociation resources
      # Associates a permission with a Resource Access Manager (RAM) resource share.
      class RamPermissionAssociationAttributes < Dry::Struct
        attribute :permission_arn, Resources::Types::String
        attribute :resource_share_arn, Resources::Types::String
        attribute :replace, Resources::Types::Bool.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_ram_permission_association

      end
    end
      end
    end
  end
end