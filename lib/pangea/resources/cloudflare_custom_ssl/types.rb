# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class CustomSslAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId
    attribute :certificate, Dry::Types['strict.string'].optional.default(nil)
    attribute :private_key, Dry::Types['strict.string'].optional.default(nil)
    attribute :bundle_method, Dry::Types['strict.string'].enum('ubiquitous', 'optimal', 'force').optional.default(nil)
    attribute :geo_restrictions, Dry::Types['strict.hash'].optional.default(nil)
    attribute :type, Dry::Types['strict.string'].enum('legacy_custom', 'sni_custom').optional.default(nil)
    attribute :policy, Dry::Types['strict.string'].optional.default(nil)
  end
end
