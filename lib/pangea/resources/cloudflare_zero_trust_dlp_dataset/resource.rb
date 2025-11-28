# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_zero_trust_dlp_dataset/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareZeroTrustDlpDataset
    def cloudflare_zero_trust_dlp_dataset(name, attributes = {})
      attrs = Cloudflare::Types::ZeroTrustDlpDatasetAttributes.new(attributes)
      resource(:cloudflare_zero_trust_dlp_dataset, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_zero_trust_dlp_dataset',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_zero_trust_dlp_dataset.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareZeroTrustDlpDataset
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
