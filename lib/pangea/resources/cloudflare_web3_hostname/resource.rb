# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_web3_hostname/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareWeb3Hostname
    def cloudflare_web3_hostname(name, attributes = {})
      attrs = Cloudflare::Types::Web3HostnameAttributes.new(attributes)
      resource(:cloudflare_web3_hostname, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_web3_hostname',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_web3_hostname.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareWeb3Hostname
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
