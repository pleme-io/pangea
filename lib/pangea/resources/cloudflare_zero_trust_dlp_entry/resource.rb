# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_dlp_entry/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustDlpEntry
    def cloudflare_zero_trust_dlp_entry(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustDlpEntryAttributes.new(attributes)
      resource(:cloudflare_zero_trust_dlp_entry, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_dlp_entry',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_dlp_entry.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustDlpEntry
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
