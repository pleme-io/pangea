# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_device_default_profile_local_domain_fallback/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareDeviceDefaultProfileLocalDomainFallback
    def cloudflare_zero_trust_device_default_profile_local_domain_fallback(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustDeviceDefaultProfileLocalDomainFallbackAttributes.new(attributes)
      resource(:cloudflare_zero_trust_device_default_profile_local_domain_fallback, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_device_default_profile_local_domain_fallback',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_device_default_profile_local_domain_fallback.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareDeviceDefaultProfileLocalDomainFallback
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
