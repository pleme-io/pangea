# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Network Subnet resource attributes with validation
        class NetworkSubnetAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :network_id, Resources::Types::String
          attribute :type, Resources::Types::HetznerSubnetType
          attribute :network_zone, Resources::Types::HetznerNetworkZone
          attribute :ip_range, Resources::Types::CidrBlock

          # Optional attributes
          attribute :vswitch_id, Resources::Types::Integer.optional.default(nil)
        end
      end
    end
  end
end
