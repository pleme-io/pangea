# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_email_routing_settings/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareEmailRoutingSettings
    def cloudflare_email_routing_settings(name, attributes = {})
      attrs = Cloudflare::Types::EmailRoutingSettingsAttributes.new(attributes)
      resource(:cloudflare_email_routing_settings, name) do
        zone_id attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_email_routing_settings',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_email_routing_settings.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareEmailRoutingSettings
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
