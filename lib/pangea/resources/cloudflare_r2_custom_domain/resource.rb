# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_r2_custom_domain/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareR2CustomDomain
    def cloudflare_r2_custom_domain(name, attributes = {})
      attrs = Cloudflare::Types::R2CustomDomainAttributes.new(attributes)
      resource(:cloudflare_r2_custom_domain, name) do
        account_id attrs.account_id
        bucket_name attrs.bucket_name
        domain attrs.domain
      end
      ResourceReference.new(
        type: 'cloudflare_r2_custom_domain',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_r2_custom_domain.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareR2CustomDomain
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
