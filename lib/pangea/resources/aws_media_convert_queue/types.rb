# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS MediaConvert Queue resources
      class MediaConvertQueueAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Queue name (required)
        attribute :name, Resources::Types::String

        # Queue description
        attribute :description, Resources::Types::String.default("")

        # Pricing plan
        attribute :pricing_plan, Resources::Types::String.enum('ON_DEMAND', 'RESERVED').default('ON_DEMAND')

        # Reservation plan settings (for RESERVED pricing)
        attribute :reservation_plan_settings, Resources::Types::Hash.schema(
          commitment: Resources::Types::String.enum('ONE_YEAR'),
          renewal_type: Resources::Types::String.enum('AUTO_RENEW', 'EXPIRE'),
          reserved_slots: Resources::Types::Integer
        ).default({})

        # Status
        attribute :status, Resources::Types::String.enum('ACTIVE', 'PAUSED').default('ACTIVE')

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({})

        # Helper methods
        def reserved_pricing?
          pricing_plan == 'RESERVED'
        end

        def on_demand_pricing?
          pricing_plan == 'ON_DEMAND'
        end

        def active?
          status == 'ACTIVE'
        end

        def paused?
          status == 'PAUSED'
        end
      end
    end
      end
    end
  end
end