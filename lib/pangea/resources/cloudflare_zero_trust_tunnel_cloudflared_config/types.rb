# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class ZeroTrustTunnelCloudflaredConfigAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
    attribute :tunnel_id, Dry::Types['strict.string']
    attribute :config, Dry::Types['strict.hash']
  end
end
