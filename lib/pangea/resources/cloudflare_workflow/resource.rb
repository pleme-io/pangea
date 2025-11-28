# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_workflow/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareWorkflow
    def cloudflare_workflow(name, attributes = {})
      attrs = Cloudflare::Types::WorkflowAttributes.new(attributes)
      resource(:cloudflare_workflow, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_workflow',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_workflow.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareWorkflow
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
