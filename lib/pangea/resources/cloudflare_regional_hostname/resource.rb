# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_regional_hostname/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareRegionalHostname
    def cloudflare_regional_hostname(name, attributes = {})
      attrs = Cloudflare::Types::RegionalHostnameAttributes.new(attributes)
      resource(:cloudflare_regional_hostname, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_regional_hostname',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_regional_hostname.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareRegionalHostname
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
