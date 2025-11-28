# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_worker/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareWorker
    def cloudflare_worker(name, attributes = {})
      attrs = Cloudflare::Types::WorkerAttributes.new(attributes)
      resource(:cloudflare_worker, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_worker',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_worker.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareWorker
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
