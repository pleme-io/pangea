# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsRamSharingWithOrganization resources
      # Manages Resource Access Manager (RAM) resource sharing with AWS Organizations.
      class RamSharingWithOrganizationAttributes < Dry::Struct
        attribute :enable, Resources::Types::Bool
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_ram_sharing_with_organization

      end
    end
      end
    end
  end
end