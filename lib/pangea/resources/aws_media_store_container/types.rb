# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS MediaStore Container resources
      class MediaStoreContainerAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Container name (required)
        attribute :name, Resources::Types::String

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate container name format
          unless attrs.name.match?(/^[a-zA-Z0-9_.-]{1,255}$/)
            raise Dry::Struct::Error, "Container name must be 1-255 characters with letters, numbers, dots, hyphens, underscores"
          end

          attrs
        end

        # Helper methods
        def name_valid?
          name.match?(/^[a-zA-Z0-9_.-]{1,255}$/)
        end
      end
    end
      end
    end
  end
end