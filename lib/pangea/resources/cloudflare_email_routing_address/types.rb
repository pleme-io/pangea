# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class EmailRoutingAddressAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId
  end
end
