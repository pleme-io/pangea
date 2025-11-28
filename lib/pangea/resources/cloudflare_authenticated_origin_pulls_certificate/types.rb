# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class AuthenticatedOriginPullsCertificateAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId
    attribute :certificate, Dry::Types['strict.string']
    attribute :private_key, Dry::Types['strict.string']
    attribute :type, Dry::Types['strict.string'].enum('per-zone', 'per-hostname').optional.default(nil)
  end
end
