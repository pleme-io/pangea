# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Cloudflare
      module Types
        # Waiting room rule
        class WaitingRoomRule < Dry::Struct
          transform_keys(&:to_sym)

          attribute :expression, Dry::Types['strict.string'].constrained(min_size: 1)
          attribute :action, Dry::Types['strict.string'].constrained(min_size: 1)
          attribute :description, Dry::Types['strict.string'].optional.default(nil)
          attribute :status, Dry::Types['strict.string'].optional.default(nil)
        end

        # Waiting room rules attributes
        class WaitingRoomRulesAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId
          attribute :waiting_room_id, Dry::Types['strict.string'].constrained(min_size: 1)
          attribute :rules, Dry::Types['strict.array'].of(WaitingRoomRule).constrained(min_size: 1)
        end
      end
    end
  end
end
