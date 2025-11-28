# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Floating IP Assignment attributes
        class FloatingIpAssignmentAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :floating_ip_id, Resources::Types::String
          attribute :server_id, Resources::Types::String
        end
      end
    end
  end
end
