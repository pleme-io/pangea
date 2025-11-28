# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Load Balancer Network attachment attributes
        class LoadBalancerNetworkAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :load_balancer_id, Resources::Types::String
          attribute :network_id, Resources::Types::String

          # Optional attributes
          attribute :ip, Resources::Types::String.optional.default(nil)
          attribute :enable_public_interface, Resources::Types::Bool.default(true)
        end
      end
    end
  end
end
