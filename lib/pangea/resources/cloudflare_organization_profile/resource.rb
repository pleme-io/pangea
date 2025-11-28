# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_organization_profile/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareOrganizationProfile
    def cloudflare_organization_profile(name, attributes = {})
      attrs = Cloudflare::Types::OrganizationProfileAttributes.new(attributes)
      resource(:cloudflare_organization_profile, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_organization_profile',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_organization_profile.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareOrganizationProfile
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
