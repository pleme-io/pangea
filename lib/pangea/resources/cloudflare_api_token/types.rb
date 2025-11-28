# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class ApiTokenAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :name, Dry::Types['strict.string']
    attribute :policy, Dry::Types['strict.array']
    attribute :condition, Dry::Types['strict.hash'].optional.default(nil)
    attribute :expires_on, Dry::Types['strict.string'].optional.default(nil)
    attribute :not_before, Dry::Types['strict.string'].optional.default(nil)
  end
end
