# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_worker_version/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareWorkerVersion
    def cloudflare_worker_version(name, attributes = {})
      attrs = Cloudflare::Types::WorkerVersionAttributes.new(attributes)
      resource(:cloudflare_worker_version, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_worker_version',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_worker_version.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareWorkerVersion
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
