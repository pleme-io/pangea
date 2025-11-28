# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class StreamAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
    attribute :name, Dry::Types['strict.string'].optional.default(nil)
    attribute :meta, Dry::Types['strict.hash'].optional.default(nil)
    attribute :require_signed_urls, Dry::Types['strict.bool'].optional.default(nil)
    attribute :allowed_origins, Dry::Types['strict.array'].of(Dry::Types['strict.string']).optional.default(nil)
    attribute :thumbnail_timestamp_pct, Dry::Types['strict.float'].optional.default(nil)
  end
end
