# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsMemorydbUser resources
      # Provides a MemoryDB User resource.
      class MemorydbUserAttributes < Dry::Struct
        attribute :user_name, Resources::Types::String
        attribute :access_string, Resources::Types::String
        attribute :authentication_mode, Resources::Types::Hash.default({})
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_memorydb_user

      end
    end
      end
    end
  end
end