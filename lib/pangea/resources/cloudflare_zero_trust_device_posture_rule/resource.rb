# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_device_posture_rule/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustDevicePostureRule
    def cloudflare_zero_trust_device_posture_rule(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustDevicePostureRuleAttributes.new(attributes)
      resource(:cloudflare_zero_trust_device_posture_rule, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_device_posture_rule',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_device_posture_rule.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustDevicePostureRule
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
