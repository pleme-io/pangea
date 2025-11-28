# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_organization/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustOrganization
    def cloudflare_zero_trust_organization(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustOrganizationAttributes.new(attributes)
      resource(:cloudflare_zero_trust_organization, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_organization',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_organization.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustOrganization
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
