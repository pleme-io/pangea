# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_pages_domain/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflarePagesDomain
    def cloudflare_pages_domain(name, attributes = {})
      attrs = Cloudflare::Types::PagesDomainAttributes.new(attributes)
      resource(:cloudflare_pages_domain, name) do
        account_id attrs.account_id
        project_name attrs.project_name
        domain attrs.domain
      end
      ResourceReference.new(
        type: 'cloudflare_pages_domain',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_pages_domain.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflarePagesDomain
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
