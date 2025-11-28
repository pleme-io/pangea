# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_dex_test/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustDexTest
    def cloudflare_zero_trust_dex_test(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustDexTestAttributes.new(attributes)
      resource(:cloudflare_zero_trust_dex_test, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_dex_test',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_dex_test.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustDexTest
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
