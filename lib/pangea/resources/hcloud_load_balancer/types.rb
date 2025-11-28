# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Load Balancer resource attributes
        class LoadBalancerAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :name, Resources::Types::String
          attribute :load_balancer_type, Resources::Types::HetznerLoadBalancerType

          # Optional attributes
          attribute :location, Resources::Types::HetznerLocation.optional.default(nil)
          attribute :network_zone, Resources::Types::HetznerNetworkZone.optional.default(nil)
          attribute :labels, Resources::Types::HetznerLabels.default({}.freeze)
          attribute :algorithm, Resources::Types::Hash.optional.default(nil)
        end
      end
    end
  end
end
