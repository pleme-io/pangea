# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_r2_managed_domain/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareR2ManagedDomain
    def cloudflare_r2_managed_domain(name, attributes = {})
      attrs = Cloudflare::Types::R2ManagedDomainAttributes.new(attributes)
      resource(:cloudflare_r2_managed_domain, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_r2_managed_domain',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_r2_managed_domain.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareR2ManagedDomain
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
