# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Floating IP attributes
        class FloatingIpAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :type, Resources::Types::String.enum('ipv4', 'ipv6')

          # Optional attributes (must specify either home_location or server_id)
          attribute :home_location, Resources::Types::HetznerLocation.optional.default(nil)
          attribute :server_id, Resources::Types::String.optional.default(nil)
          attribute :description, Resources::Types::String.optional.default(nil)
          attribute :labels, Resources::Types::HetznerLabels.default({}.freeze)
          attribute :name, Resources::Types::String.optional.default(nil)
        end
      end
    end
  end
end
