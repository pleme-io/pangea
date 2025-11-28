# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_web_analytics_rule/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareWebAnalyticsRule
    def cloudflare_web_analytics_rule(name, attributes = {})
      attrs = Cloudflare::Types::WebAnalyticsRuleAttributes.new(attributes)
      resource(:cloudflare_web_analytics_rule, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_web_analytics_rule',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_web_analytics_rule.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareWebAnalyticsRule
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
