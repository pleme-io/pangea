# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class R2BucketLockAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
    attribute :bucket_name, Dry::Types['strict.string']
    attribute :enabled, Dry::Types['strict.bool']
    attribute :retention_period_days, Dry::Types['strict.integer'].optional.default(nil)
  end
end
