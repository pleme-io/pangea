# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_dns_firewall/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareDnsFirewall
    def cloudflare_dns_firewall(name, attributes = {})
      attrs = Cloudflare::Types::DnsFirewallAttributes.new(attributes)
      resource(:cloudflare_dns_firewall, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_dns_firewall',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_dns_firewall.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareDnsFirewall
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
