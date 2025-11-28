# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_custom_ssl/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareCustomSsl
    def cloudflare_custom_ssl(name, attributes = {})
      attrs = Cloudflare::Types::CustomSslAttributes.new(attributes)
      resource(:cloudflare_custom_ssl, name) do
        zone_id attrs.zone_id
        certificate attrs.certificate if attrs.certificate
        private_key attrs.private_key if attrs.private_key
        bundle_method attrs.bundle_method if attrs.bundle_method
        geo_restrictions attrs.geo_restrictions if attrs.geo_restrictions
        type attrs.type if attrs.type
        policy attrs.policy if attrs.policy
      end
      ResourceReference.new(
        type: 'cloudflare_custom_ssl',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: {
          id: "${cloudflare_custom_ssl.#{name}.id}",
          status: "${cloudflare_custom_ssl.#{name}.status}",
          expires_on: "${cloudflare_custom_ssl.#{name}.expires_on}"
        }
      )
    end
  end
  module Cloudflare
    include CloudflareCustomSsl
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
