# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class ManagedTransformsAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId
    attribute :managed_request_headers, Dry::Types['strict.hash'].optional.default(nil)
    attribute :managed_response_headers, Dry::Types['strict.hash'].optional.default(nil)
  end
end
