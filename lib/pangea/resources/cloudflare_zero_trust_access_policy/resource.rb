# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_access_policy/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustAccessPolicy
    def cloudflare_zero_trust_access_policy(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustAccessPolicyAttributes.new(attributes)
      resource(:cloudflare_zero_trust_access_policy, name) do
        account_id attrs.account_id if attrs.account_id
        zone_id attrs.zone_id if attrs.zone_id
        application_id attrs.application_id if attrs.application_id
        name attrs.name
        decision attrs.decision
        precedence attrs.precedence
        include attrs.include if attrs.include
        exclude attrs.exclude if attrs.exclude
        require attrs.require if attrs.require
        approval_required attrs.approval_required if !attrs.approval_required.nil?
        approval_groups attrs.approval_groups if attrs.approval_groups
        purpose_justification_required attrs.purpose_justification_required if !attrs.purpose_justification_required.nil?
        purpose_justification_prompt attrs.purpose_justification_prompt if attrs.purpose_justification_prompt
        session_duration attrs.session_duration if attrs.session_duration
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_access_policy',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_access_policy.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustAccessPolicy
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
