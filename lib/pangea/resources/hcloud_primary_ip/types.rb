# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Primary IP attributes
        class PrimaryIpAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :name, Resources::Types::String
          attribute :type, Resources::Types::String.enum('ipv4', 'ipv6')
          attribute :assignee_type, Resources::Types::String.enum('server')

          # Optional attributes
          attribute :assignee_id, Resources::Types::String.optional.default(nil)
          attribute :datacenter, Resources::Types::String.optional.default(nil)
          attribute :auto_delete, Resources::Types::Bool.default(true)
          attribute :labels, Resources::Types::HetznerLabels.default({}.freeze)
        end
      end
    end
  end
end
