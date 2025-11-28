# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner Firewall Attachment attributes
        class FirewallAttachmentAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :firewall_id, Resources::Types::String
          attribute :server_ids, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
        end
      end
    end
  end
end
