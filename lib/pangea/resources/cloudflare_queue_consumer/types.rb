# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class QueueConsumerAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
    attribute :queue_id, Dry::Types['strict.string']
    attribute :script_name, Dry::Types['strict.string']
    attribute :batch_size, Dry::Types['coercible.integer'].optional.default(nil)
    attribute :max_retries, Dry::Types['coercible.integer'].optional.default(nil)
    attribute :max_wait_time_ms, Dry::Types['coercible.integer'].optional.default(nil)
  end
end
