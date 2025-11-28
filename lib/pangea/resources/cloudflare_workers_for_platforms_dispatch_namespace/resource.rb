# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_workers_for_platforms_dispatch_namespace/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareWorkersForPlatformsDispatchNamespace
    def cloudflare_workers_for_platforms_dispatch_namespace(name, attributes = {})
      attrs = Cloudflare::Types::WorkersForPlatformsDispatchNamespaceAttributes.new(attributes)
      resource(:cloudflare_workers_for_platforms_dispatch_namespace, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_workers_for_platforms_dispatch_namespace',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_workers_for_platforms_dispatch_namespace.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareWorkersForPlatformsDispatchNamespace
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
