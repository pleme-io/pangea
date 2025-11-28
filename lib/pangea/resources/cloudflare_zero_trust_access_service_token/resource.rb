# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_access_service_token/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustAccessServiceToken
    def cloudflare_zero_trust_access_service_token(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustAccessServiceTokenAttributes.new(attributes)
      resource(:cloudflare_zero_trust_access_service_token, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_access_service_token',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_access_service_token.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustAccessServiceToken
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
