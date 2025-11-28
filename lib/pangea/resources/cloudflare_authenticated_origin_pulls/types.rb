# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class AuthenticatedOriginPullsAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId
    attribute :enabled, Dry::Types['strict.bool']
    attribute :authenticated_origin_pulls_certificate, Dry::Types['strict.string'].optional.default(nil)
    attribute :hostname, Dry::Types['strict.string'].optional.default(nil)
  end
end
