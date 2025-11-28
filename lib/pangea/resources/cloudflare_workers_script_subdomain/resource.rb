# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_workers_script_subdomain/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareWorkersScriptSubdomain
    def cloudflare_workers_script_subdomain(name, attributes = {})
      attrs = Cloudflare::Types::WorkersScriptSubdomainAttributes.new(attributes)
      resource(:cloudflare_workers_script_subdomain, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_workers_script_subdomain',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_workers_script_subdomain.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareWorkersScriptSubdomain
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
