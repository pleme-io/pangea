# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class R2BucketEventNotificationAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
    attribute :bucket, Dry::Types['strict.string']
    attribute :queue, Dry::Types['strict.string']
    attribute :event_types, Dry::Types['strict.array'].of(Dry::Types['strict.string']).optional.default(nil)
    attribute :prefix, Dry::Types['strict.string'].optional.default(nil)
    attribute :suffix, Dry::Types['strict.string'].optional.default(nil)
  end
end
