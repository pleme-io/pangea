# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class TurnstileWidgetAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
    attribute :name, Dry::Types['strict.string']
    attribute :domains, Dry::Types['strict.array'].of(Dry::Types['strict.string'])
    attribute :mode, Dry::Types['strict.string']
    attribute :region, Dry::Types['strict.string'].optional.default(nil)
    attribute :offlabel, Dry::Types['strict.bool'].optional.default(nil)
  end
end
