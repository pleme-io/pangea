# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_authenticated_origin_pulls_settings/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareAuthenticatedOriginPullsSettings
    def cloudflare_authenticated_origin_pulls_settings(name, attributes = {})
      attrs = Cloudflare::Types::AuthenticatedOriginPullsSettingsAttributes.new(attributes)
      resource(:cloudflare_authenticated_origin_pulls_settings, name) do
        zone_id attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_authenticated_origin_pulls_settings',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_authenticated_origin_pulls_settings.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareAuthenticatedOriginPullsSettings
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
