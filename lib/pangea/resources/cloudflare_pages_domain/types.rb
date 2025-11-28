# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class PagesDomainAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
    attribute :project_name, Dry::Types['strict.string']
    attribute :domain, Dry::Types['strict.string']
  end
end
