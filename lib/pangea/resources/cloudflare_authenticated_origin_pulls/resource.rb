# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_authenticated_origin_pulls/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareAuthenticatedOriginPulls
    def cloudflare_authenticated_origin_pulls(name, attributes = {})
      attrs = Cloudflare::Types::AuthenticatedOriginPullsAttributes.new(attributes)
      resource(:cloudflare_authenticated_origin_pulls, name) do
        zone_id attrs.zone_id
        enabled attrs.enabled
        authenticated_origin_pulls_certificate attrs.authenticated_origin_pulls_certificate if attrs.authenticated_origin_pulls_certificate
        hostname attrs.hostname if attrs.hostname
      end
      ResourceReference.new(
        type: 'cloudflare_authenticated_origin_pulls',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_authenticated_origin_pulls.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareAuthenticatedOriginPulls
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
