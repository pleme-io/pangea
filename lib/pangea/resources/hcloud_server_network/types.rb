# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Server Network attachment attributes
        class ServerNetworkAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :server_id, Resources::Types::String
          attribute :network_id, Resources::Types::String

          # Optional attributes
          attribute :ip, Resources::Types::String.optional.default(nil)
          attribute :alias_ips, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
        end
      end
    end
  end
end
