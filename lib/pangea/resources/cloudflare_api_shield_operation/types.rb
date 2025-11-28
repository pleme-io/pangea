# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class ApiShieldOperationAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId
    attribute :method, Dry::Types['strict.string']
    attribute :host, Dry::Types['strict.string']
    attribute :endpoint, Dry::Types['strict.string']
  end
end
