# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Server resource attributes with validation
        class ServerAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :name, Resources::Types::String
          attribute :server_type, Resources::Types::HetznerServerType
          attribute :image, Resources::Types::String

          # Optional attributes with defaults
          attribute :location, Resources::Types::HetznerLocation.optional.default(nil)
          attribute :datacenter, Resources::Types::String.optional.default(nil)
          attribute :ssh_keys, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
          attribute :firewall_ids, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
          attribute :user_data, Resources::Types::String.optional.default(nil)
          attribute :labels, Resources::Types::HetznerLabels.default({}.freeze)
          attribute :backups, Resources::Types::Bool.default(false)
          attribute :placement_group_id, Resources::Types::String.optional.default(nil)
          attribute :iso, Resources::Types::String.optional.default(nil)
          attribute :rescue, Resources::Types::String.optional.default(nil)

          # Nested attributes
          attribute :public_net, Resources::Types::Hash.optional.default(nil)
          attribute :network, Resources::Types::Hash.optional.default(nil)

          # Computed properties
          def is_arm?
            server_type.start_with?('cax')
          end

          def is_dedicated?
            server_type.start_with?('ccx')
          end

          def cpu_type
            case server_type[0..2]
            when 'cax' then 'arm64'
            when 'ccx' then 'amd-dedicated'
            when 'cpx' then 'amd-shared'
            when 'cx' then 'intel'
            else 'unknown'
            end
          end
        end
      end
    end
  end
end
