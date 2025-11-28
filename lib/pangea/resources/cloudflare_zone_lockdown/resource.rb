# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zone_lockdown/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZoneLockdown
    def cloudflare_zone_lockdown(name, attributes = {})
      attrs = Cloudflare::Types::ZoneLockdownAttributes.new(attributes)
      resource(:cloudflare_zone_lockdown, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zone_lockdown',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zone_lockdown.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZoneLockdown
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
