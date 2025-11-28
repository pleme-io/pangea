# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Snapshot attributes
        class SnapshotAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :server_id, Resources::Types::String

          # Optional attributes
          attribute :description, Resources::Types::String.optional.default(nil)
          attribute :labels, Resources::Types::HetznerLabels.default({}.freeze)
        end
      end
    end
  end
end
