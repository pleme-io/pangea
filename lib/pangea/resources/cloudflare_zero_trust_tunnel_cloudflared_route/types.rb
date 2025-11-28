# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class ZeroTrustTunnelCloudflaredRouteAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
    attribute :tunnel_id, Dry::Types['strict.string']
    attribute :network, Dry::Types['strict.string']
    attribute :comment, Dry::Types['strict.string'].optional.default(nil)
    attribute :virtual_network_id, Dry::Types['strict.string'].optional.default(nil)
  end
end
