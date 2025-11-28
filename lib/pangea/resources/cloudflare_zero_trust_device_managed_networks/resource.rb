# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_device_managed_networks/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustDeviceManagedNetworks
    def cloudflare_zero_trust_device_managed_networks(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustDeviceManagedNetworksAttributes.new(attributes)
      resource(:cloudflare_zero_trust_device_managed_networks, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_device_managed_networks',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_device_managed_networks.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustDeviceManagedNetworks
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
