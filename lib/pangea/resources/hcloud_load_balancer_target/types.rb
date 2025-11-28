# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Load Balancer Target attributes
        class LoadBalancerTargetAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :load_balancer_id, Resources::Types::String
          attribute :type, Resources::Types::String.enum('server', 'label_selector', 'ip')

          # Optional attributes (depends on type)
          attribute :server_id, Resources::Types::String.optional.default(nil)
          attribute :label_selector, Resources::Types::String.optional.default(nil)
          attribute :ip, Resources::Types::String.optional.default(nil)
          attribute :use_private_ip, Resources::Types::Bool.default(false)
        end
      end
    end
  end
end
