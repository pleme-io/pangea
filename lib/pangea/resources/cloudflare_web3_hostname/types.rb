# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class Web3HostnameAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId.optional.default(nil)
    attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId.optional.default(nil)
  end
end
