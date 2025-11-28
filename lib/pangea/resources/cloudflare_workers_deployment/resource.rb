# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_workers_deployment/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareWorkersDeployment
    def cloudflare_workers_deployment(name, attributes = {})
      attrs = Cloudflare::Types::WorkersDeploymentAttributes.new(attributes)
      resource(:cloudflare_workers_deployment, name) do
        account_id attrs.account_id
        script_name attrs.script_name
        version_id attrs.version_id if attrs.version_id
      end
      ResourceReference.new(
        type: 'cloudflare_workers_deployment',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_workers_deployment.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareWorkersDeployment
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
