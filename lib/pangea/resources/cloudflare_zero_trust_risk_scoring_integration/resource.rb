# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_risk_scoring_integration/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustRiskScoringIntegration
    def cloudflare_zero_trust_risk_scoring_integration(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustRiskScoringIntegrationAttributes.new(attributes)
      resource(:cloudflare_zero_trust_risk_scoring_integration, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_risk_scoring_integration',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_risk_scoring_integration.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustRiskScoringIntegration
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
