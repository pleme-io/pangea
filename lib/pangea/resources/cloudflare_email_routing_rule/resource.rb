# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_email_routing_rule/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareEmailRoutingRule
    def cloudflare_email_routing_rule(name, attributes = {})
      attrs = Cloudflare::Types::EmailRoutingRuleAttributes.new(attributes)
      resource(:cloudflare_email_routing_rule, name) do
        zone_id attrs.zone_id
      end
      ResourceReference.new(
        type: 'cloudflare_email_routing_rule',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_email_routing_rule.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareEmailRoutingRule
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
