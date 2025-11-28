# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_risk_behavior/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustRiskBehavior
    def cloudflare_zero_trust_risk_behavior(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustRiskBehaviorAttributes.new(attributes)
      resource(:cloudflare_zero_trust_risk_behavior, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_risk_behavior',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_risk_behavior.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustRiskBehavior
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
