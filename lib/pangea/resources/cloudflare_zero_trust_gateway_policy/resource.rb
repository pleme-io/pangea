# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_gateway_policy/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustGatewayPolicy
    def cloudflare_zero_trust_gateway_policy(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustGatewayPolicyAttributes.new(attributes)
      resource(:cloudflare_zero_trust_gateway_policy, name) do
        account_id attrs.account_id
        name attrs.name
        action attrs.action
        precedence attrs.precedence
        enabled attrs.enabled if !attrs.enabled.nil?
        description attrs.description if attrs.description
        traffic attrs.traffic if attrs.traffic
        filters attrs.filters if attrs.filters
        rule_settings attrs.rule_settings if attrs.rule_settings
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_gateway_policy',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_gateway_policy.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustGatewayPolicy
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
