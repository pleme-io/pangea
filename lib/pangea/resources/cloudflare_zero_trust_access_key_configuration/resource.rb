# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_access_key_configuration/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustAccessKeyConfiguration
    def cloudflare_zero_trust_access_key_configuration(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustAccessKeyConfigurationAttributes.new(attributes)
      resource(:cloudflare_zero_trust_access_key_configuration, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_access_key_configuration',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_access_key_configuration.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustAccessKeyConfiguration
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
