# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class ApiShieldSchemaAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId
    attribute :name, Dry::Types['strict.string']
    attribute :source, Dry::Types['strict.string']
    attribute :kind, Dry::Types['strict.string'].enum('openapi_v3').optional.default(nil)
    attribute :validation_enabled, Dry::Types['strict.bool'].optional.default(nil)
  end
end
