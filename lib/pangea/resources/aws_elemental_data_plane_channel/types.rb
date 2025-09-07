# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Elemental Data Plane Channel resources
      class ElementalDataPlaneChannelAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Channel name (required)
        attribute :name, Resources::Types::String

        # Channel description
        attribute :description, Resources::Types::String.default("")

        # Channel type
        attribute :channel_type, Resources::Types::String.enum('LIVE', 'PLAYOUT').default('LIVE')

        # Input specifications
        attribute :input_specifications, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            codec: Resources::Types::String.enum('MPEG2', 'AVC', 'HEVC'),
            maximum_bitrate: Resources::Types::String.enum('MAX_10_MBPS', 'MAX_20_MBPS', 'MAX_50_MBPS'),
            resolution: Resources::Types::String.enum('SD', 'HD', 'UHD')
          )
        ).default([])

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({})

        # Helper methods
        def live_channel?
          channel_type == 'LIVE'
        end

        def playout_channel?
          channel_type == 'PLAYOUT'
        end

        def has_input_specs?
          input_specifications.any?
        end
      end
    end
      end
    end
  end
end