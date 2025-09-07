# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsMemorydbAcl resources
      # Provides a MemoryDB ACL resource.
      class MemorydbAclAttributes < Dry::Struct
        attribute :name, Resources::Types::String
        attribute :user_names, Resources::Types::Array.of(Types::String).default([].freeze).optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_memorydb_acl

      end
    end
      end
    end
  end
end