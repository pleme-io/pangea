# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_device_default_profile_certificates/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareDeviceDefaultProfileCertificates
    def cloudflare_zero_trust_device_default_profile_certificates(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustDeviceDefaultProfileCertificatesAttributes.new(attributes)
      resource(:cloudflare_zero_trust_device_default_profile_certificates, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_device_default_profile_certificates',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_device_default_profile_certificates.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareDeviceDefaultProfileCertificates
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
