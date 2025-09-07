# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsRamManagedPermission resources
      # Retrieves information about a Resource Access Manager (RAM) managed permission.
      class RamManagedPermissionAttributes < Dry::Struct
        attribute :name, Resources::Types::String
        attribute :resource_type, Resources::Types::String.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_ram_managed_permission

      end
    end
      end
    end
  end
end