# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Network Route attributes
        class NetworkRouteAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :network_id, Resources::Types::String
          attribute :destination, Resources::Types::CidrBlock
          attribute :gateway, Resources::Types::String
        end
      end
    end
  end
end
