# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_device_default_profile/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareDeviceDefaultProfile
    def cloudflare_zero_trust_device_default_profile(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustDeviceDefaultProfileAttributes.new(attributes)
      resource(:cloudflare_zero_trust_device_default_profile, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_device_default_profile',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_device_default_profile.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareDeviceDefaultProfile
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
