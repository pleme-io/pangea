# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_access_identity_provider/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustAccessIdentityProvider
    def cloudflare_zero_trust_access_identity_provider(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustAccessIdentityProviderAttributes.new(attributes)
      resource(:cloudflare_zero_trust_access_identity_provider, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
        name attrs.name
        type attrs.type
        config attrs.config if attrs.config
        scim_config attrs.scim_config if attrs.scim_config
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_access_identity_provider',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_access_identity_provider.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustAccessIdentityProvider
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
