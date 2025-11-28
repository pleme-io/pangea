# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class ZeroTrustAccessPolicyAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId.optional.default(nil)
    attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId.optional.default(nil)
    attribute :application_id, Dry::Types['strict.string'].optional.default(nil)
    attribute :name, Dry::Types['strict.string']
    attribute :decision, Dry::Types['strict.string'].enum('allow', 'deny', 'non_identity', 'bypass')
    attribute :precedence, Dry::Types['strict.integer']
    attribute :include, Dry::Types['strict.array'].optional.default(nil)
    attribute :exclude, Dry::Types['strict.array'].optional.default(nil)
    attribute :require, Dry::Types['strict.array'].optional.default(nil)
    attribute :approval_required, Dry::Types['strict.bool'].optional.default(nil)
    attribute :approval_groups, Dry::Types['strict.array'].optional.default(nil)
    attribute :purpose_justification_required, Dry::Types['strict.bool'].optional.default(nil)
    attribute :purpose_justification_prompt, Dry::Types['strict.string'].optional.default(nil)
    attribute :session_duration, Dry::Types['strict.string'].optional.default(nil)
  end
end
