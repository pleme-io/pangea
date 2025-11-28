# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class AccountMemberAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
    attribute :email_address, Dry::Types['strict.string']
    attribute :role_ids, Dry::Types['strict.array'].of(Dry::Types['strict.string'])
    attribute :status, Dry::Types['strict.string'].enum('accepted', 'pending').optional.default(nil)
  end
end
