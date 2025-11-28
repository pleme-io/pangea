# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_waiting_room_rules/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module CloudflareWaitingRoomRules
      def cloudflare_waiting_room_rules(name, attributes = {})
        rules_attrs = Cloudflare::Types::WaitingRoomRulesAttributes.new(attributes)

        resource(:cloudflare_waiting_room_rules, name) do
          zone_id rules_attrs.zone_id
          waiting_room_id rules_attrs.waiting_room_id

          # Waiting room rules as array (terraform-synthesizer handles array → blocks conversion)
          if rules_attrs.rules.any?
            rules rules_attrs.rules.map { |r| r.to_h }
          end
        end

        ResourceReference.new(
          type: 'cloudflare_waiting_room_rules',
          name: name,
          resource_attributes: rules_attrs.to_h,
          outputs: { id: "${cloudflare_waiting_room_rules.#{name}.id}" }
        )
      end
    end

    module Cloudflare
      include CloudflareWaitingRoomRules
    end
  end
end

Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
