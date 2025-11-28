# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class MtlsCertificateAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
    attribute :ca, Dry::Types['strict.bool']
    attribute :certificates, Dry::Types['strict.string']
    attribute :name, Dry::Types['strict.string'].optional.default(nil)
    attribute :private_key, Dry::Types['strict.string'].optional.default(nil)
  end
end
