# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Internet Gateway resource attributes with validation
        class InternetGatewayAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # VPC ID is optional as it can be attached separately
          attribute :vpc_id, Resources::Types::String.optional.default(nil)
          attribute :tags, Resources::Types::AwsTags
          
          # Computed properties
          def attached?
            !vpc_id.nil?
          end
          
          def to_h
            {
              vpc_id: vpc_id,
              tags: tags
            }.compact
          end
        end
      end
    end
  end
end