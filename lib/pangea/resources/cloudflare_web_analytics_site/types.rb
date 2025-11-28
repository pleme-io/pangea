# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class WebAnalyticsSiteAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
    attribute :auto_install, Dry::Types['strict.bool']
    attribute :host, Dry::Types['strict.string'].optional.default(nil)
    attribute :zone_tag, Dry::Types['strict.string'].optional.default(nil)
  end
end
