# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class WorkersDeploymentAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
    attribute :script_name, Dry::Types['strict.string']
    attribute :version_id, Dry::Types['strict.string'].optional.default(nil)
  end
end
