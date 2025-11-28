# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class ZeroTrustAccessIdentityProviderAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId.optional.default(nil)
    attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId.optional.default(nil)
    attribute :name, Dry::Types['strict.string']
    attribute :type, Dry::Types['strict.string']
    attribute :config, Dry::Types['strict.array'].optional.default(nil)
    attribute :scim_config, Dry::Types['strict.array'].optional.default(nil)
  end
end
