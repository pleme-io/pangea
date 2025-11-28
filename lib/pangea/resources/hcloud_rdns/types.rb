# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Reverse DNS attributes
        class RdnsAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :server_id, Resources::Types::String
          attribute :ip_address, Resources::Types::String
          attribute :dns_ptr, Resources::Types::String
        end
      end
    end
  end
end
