# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Placement Group attributes
        class PlacementGroupAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :name, Resources::Types::String
          attribute :type, Resources::Types::HetznerPlacementGroupType

          # Optional attributes
          attribute :labels, Resources::Types::HetznerLabels.default({}.freeze)
        end
      end
    end
  end
end
