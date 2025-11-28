# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Hetzner
      module Types
        # Hetzner DNS Zone Record Set attributes
        class ZoneRrsetAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :zone_id, Resources::Types::String
          attribute :name, Resources::Types::String  # Record name (e.g., "@", "www", "mail")
          attribute :type, Resources::Types::HetznerDnsRecordType
          attribute :values, Resources::Types::Array.of(Resources::Types::String)

          # Optional attributes
          attribute :ttl, Resources::Types::HetznerDnsRecordTtl.optional.default(nil)
        end
      end
    end
  end
end
