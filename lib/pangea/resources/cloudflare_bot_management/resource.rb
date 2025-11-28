# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_bot_management/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareBotManagement
    def cloudflare_bot_management(name, attributes = {})
      attrs = Cloudflare::Types::BotManagementAttributes.new(attributes)
      resource(:cloudflare_bot_management, name) do
        zone_id attrs.zone_id
        enable_js attrs.enable_js if !attrs.enable_js.nil?
        fight_mode attrs.fight_mode if !attrs.fight_mode.nil?
        suppress_session_score attrs.suppress_session_score if !attrs.suppress_session_score.nil?
        auto_update_model attrs.auto_update_model if !attrs.auto_update_model.nil?
        optimize_wordpress attrs.optimize_wordpress if !attrs.optimize_wordpress.nil?
      end
      ResourceReference.new(
        type: 'cloudflare_bot_management',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_bot_management.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareBotManagement
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
