# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class NotificationPolicyAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
    attribute :name, Dry::Types['strict.string']
    attribute :alert_type, Dry::Types['strict.string']
    attribute :enabled, Dry::Types['strict.bool']
    attribute :description, Dry::Types['strict.string'].optional.default(nil)
    attribute :email_integration, Dry::Types['strict.array'].optional.default(nil)
    attribute :webhooks_integration, Dry::Types['strict.array'].optional.default(nil)
    attribute :pagerduty_integration, Dry::Types['strict.array'].optional.default(nil)
    attribute :filters, Dry::Types['strict.hash'].optional.default(nil)
  end
end
