# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsRamResourceShare resources
      # Provides a Resource Access Manager (RAM) Resource Share.
      class RamResourceShareAttributes < Dry::Struct
        attribute :name, Resources::Types::String
        attribute :allow_external_principals, Resources::Types::Bool.optional
        attribute :permission_arns, Resources::Types::Array.of(Types::String).default([].freeze).optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_ram_resource_share

      end
    end
      end
    end
  end
end