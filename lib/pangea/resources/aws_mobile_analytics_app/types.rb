# frozen_string_literal: true

require "dry-struct"
require "pangea/types"

module Pangea
  module Resources
    module AwsMobileAnalyticsApp
      module Types
        # Main attributes for Mobile Analytics app
        class Attributes < Dry::Struct
          # Required attributes
          attribute :name, Pangea::Types::String
          
          # Note: AWS Mobile Analytics is deprecated in favor of Amazon Pinpoint
          # This resource is maintained for legacy support
          
          def self.from_dynamic(d)
            d = Pangea::Types::Hash[d]
            new(
              name: d.fetch(:name)
            )
          end
        end

        # Reference for Mobile Analytics app resources
        class Reference < Dry::Struct
          attribute :id, Pangea::Types::String
        end
      end
    end
  end
end