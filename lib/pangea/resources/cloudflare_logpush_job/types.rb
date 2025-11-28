# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class LogpushJobAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId.optional.default(nil)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId.optional.default(nil)
    attribute :dataset, Dry::Types['strict.string']
    attribute :destination_conf, Dry::Types['strict.string']
    attribute :enabled, Dry::Types['strict.bool'].optional.default(nil)
    attribute :filter, Dry::Types['strict.string'].optional.default(nil)
    attribute :frequency, Dry::Types['strict.string'].enum('high', 'low').optional.default(nil)
    attribute :kind, Dry::Types['strict.string'].optional.default(nil)
    attribute :logpull_options, Dry::Types['strict.string'].optional.default(nil)
    attribute :max_upload_bytes, Dry::Types['strict.integer'].optional.default(nil)
    attribute :max_upload_interval_seconds, Dry::Types['strict.integer'].optional.default(nil)
    attribute :max_upload_records, Dry::Types['strict.integer'].optional.default(nil)
    attribute :name, Dry::Types['strict.string'].optional.default(nil)
    attribute :output_options, Dry::Types['strict.hash'].optional.default(nil)
    attribute :ownership_challenge, Dry::Types['strict.string'].optional.default(nil)
  end
end
