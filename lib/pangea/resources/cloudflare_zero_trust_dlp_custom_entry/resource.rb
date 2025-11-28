# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_dlp_custom_entry/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustDlpCustomEntry
    def cloudflare_zero_trust_dlp_custom_entry(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustDlpCustomEntryAttributes.new(attributes)
      resource(:cloudflare_zero_trust_dlp_custom_entry, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_dlp_custom_entry',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_dlp_custom_entry.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustDlpCustomEntry
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
