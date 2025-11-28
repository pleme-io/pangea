# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Load Balancer Service attributes
        class LoadBalancerServiceAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :load_balancer_id, Resources::Types::String
          attribute :protocol, Resources::Types::HetznerLoadBalancerProtocol

          # Optional attributes
          attribute :listen_port, Resources::Types::Integer.optional.default(nil)
          attribute :destination_port, Resources::Types::Integer.optional.default(nil)
          attribute :proxyprotocol, Resources::Types::Bool.default(false)
          attribute :http, Resources::Types::Hash.optional.default(nil)
          attribute :health_check, Resources::Types::Hash.optional.default(nil)
        end
      end
    end
  end
end
