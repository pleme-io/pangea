# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_magic_network_monitoring_rule/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareMagicNetworkMonitoringRule
    def cloudflare_magic_network_monitoring_rule(name, attributes = {})
      attrs = Cloudflare::Types::MagicNetworkMonitoringRuleAttributes.new(attributes)
      resource(:cloudflare_magic_network_monitoring_rule, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_magic_network_monitoring_rule',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_magic_network_monitoring_rule.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareMagicNetworkMonitoringRule
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
