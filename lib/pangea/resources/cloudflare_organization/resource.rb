# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_organization/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareOrganization
    def cloudflare_organization(name, attributes = {})
      attrs = Cloudflare::Types::OrganizationAttributes.new(attributes)
      resource(:cloudflare_organization, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_organization',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_organization.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareOrganization
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
