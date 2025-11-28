# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class ZeroTrustTunnelCloudflaredAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
    attribute :name, Dry::Types['strict.string']
    attribute :secret, Dry::Types['strict.string']
    attribute :config_src, Dry::Types['strict.string'].enum('local', 'cloudflare').optional.default(nil)
  end
end
