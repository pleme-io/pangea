# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Volume resource attributes
        class VolumeAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :name, Resources::Types::String
          attribute :size, Resources::Types::Integer.constrained(gteq: 10, lteq: 10000)

          # Optional attributes (must specify either location or server_id)
          attribute :location, Resources::Types::HetznerLocation.optional.default(nil)
          attribute :server_id, Resources::Types::String.optional.default(nil)
          attribute :format, Resources::Types::HetznerVolumeFormat.optional.default(nil)
          attribute :labels, Resources::Types::HetznerLabels.default({}.freeze)
        end
      end
    end
  end
end
