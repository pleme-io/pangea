# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea::Resources::Cloudflare::Types
  class BotManagementAttributes < Dry::Struct
    transform_keys(&:to_sym)
    attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId
    attribute :enable_js, Dry::Types['strict.bool'].optional.default(nil)
    attribute :fight_mode, Dry::Types['strict.bool'].optional.default(nil)
    attribute :suppress_session_score, Dry::Types['strict.bool'].optional.default(nil)
    attribute :auto_update_model, Dry::Types['strict.bool'].optional.default(nil)
    attribute :optimize_wordpress, Dry::Types['strict.bool'].optional.default(nil)
  end
end
