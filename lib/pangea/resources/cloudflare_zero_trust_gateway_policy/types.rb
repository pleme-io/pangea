# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class ZeroTrustGatewayPolicyAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
    attribute :name, Dry::Types['strict.string']
    attribute :action, Dry::Types['strict.string'].enum('allow', 'block', 'safesearch', 'ytrestricted', 'on', 'off', 'scan', 'noscan', 'isolate', 'noisolate', 'override', 'l4_override', 'egress')
    attribute :precedence, Dry::Types['strict.integer']
    attribute :enabled, Dry::Types['strict.bool'].optional.default(nil)
    attribute :description, Dry::Types['strict.string'].optional.default(nil)
    attribute :traffic, Dry::Types['strict.string'].optional.default(nil)
    attribute :filters, Dry::Types['strict.array'].optional.default(nil)
    attribute :rule_settings, Dry::Types['strict.hash'].optional.default(nil)
  end
end
