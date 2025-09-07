# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Architectures
    module SimpleWebApp
      module Types
        # Simple web app architecture attributes
        class SimpleWebAppAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :vpc_cidr, Resources::Types::CidrBlock.default("10.1.0.0/16")
          attribute :environment, Resources::Types::String.default("development")
          attribute :availability_zones, Resources::Types::Array.of(Resources::Types::String).default(["us-east-1a", "us-east-1b"])
          attribute :tags, Resources::Types::AwsTags.default({})
        end
      end
    end
  end
end