# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_observatory_scheduled_test/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareObservatoryScheduledTest
    def cloudflare_observatory_scheduled_test(name, attributes = {})
      attrs = Cloudflare::Types::ObservatoryScheduledTestAttributes.new(attributes)
      resource(:cloudflare_observatory_scheduled_test, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_observatory_scheduled_test',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_observatory_scheduled_test.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareObservatoryScheduledTest
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
