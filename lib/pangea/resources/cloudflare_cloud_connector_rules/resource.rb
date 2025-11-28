# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_cloud_connector_rules/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareCloudConnectorRules
    def cloudflare_cloud_connector_rules(name, attributes = {})
      attrs = Cloudflare::Types::CloudConnectorRulesAttributes.new(attributes)
      resource(:cloudflare_cloud_connector_rules, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_cloud_connector_rules',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_cloud_connector_rules.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareCloudConnectorRules
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
