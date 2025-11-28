# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class AccountAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :name, Dry::Types['strict.string']
    attribute :type, Dry::Types['strict.string'].enum('standard', 'enterprise').optional.default(nil)
    attribute :enforce_twofactor, Dry::Types['strict.bool'].optional.default(nil)
  end
end
