# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_waiting_room_settings/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareWaitingRoomSettings
    def cloudflare_waiting_room_settings(name, attributes = {})
      attrs = Cloudflare::Types::WaitingRoomSettingsAttributes.new(attributes)
      resource(:cloudflare_waiting_room_settings, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_waiting_room_settings',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_waiting_room_settings.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareWaitingRoomSettings
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
