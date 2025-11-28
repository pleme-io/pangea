# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_magic_transit_site_acl/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareMagicTransitSiteAcl
    def cloudflare_magic_transit_site_acl(name, attributes = {})
      attrs = Cloudflare::Types::MagicTransitSiteAclAttributes.new(attributes)
      resource(:cloudflare_magic_transit_site_acl, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_magic_transit_site_acl',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_magic_transit_site_acl.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareMagicTransitSiteAcl
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
