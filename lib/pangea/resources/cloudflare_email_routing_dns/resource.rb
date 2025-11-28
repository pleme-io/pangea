# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_email_routing_dns/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareEmailRoutingDns
    def cloudflare_email_routing_dns(name, attributes = {})
      attrs = Cloudflare::Types::EmailRoutingDnsAttributes.new(attributes)
      resource(:cloudflare_email_routing_dns, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_email_routing_dns',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_email_routing_dns.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareEmailRoutingDns
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
