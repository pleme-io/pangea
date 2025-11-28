# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_user_agent_blocking_rule/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareUserAgentBlockingRule
    def cloudflare_user_agent_blocking_rule(name, attributes = {})
      attrs = Cloudflare::Types::UserAgentBlockingRuleAttributes.new(attributes)
      resource(:cloudflare_user_agent_blocking_rule, name) do
        zone_id attrs.zone_id if attrs.zone_id
        account_id attrs.account_id if attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_user_agent_blocking_rule',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_user_agent_blocking_rule.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareUserAgentBlockingRule
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
