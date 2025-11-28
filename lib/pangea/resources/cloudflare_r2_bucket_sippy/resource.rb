# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_r2_bucket_sippy/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareR2BucketSippy
    def cloudflare_r2_bucket_sippy(name, attributes = {})
      attrs = Cloudflare::Types::R2BucketSippyAttributes.new(attributes)
      resource(:cloudflare_r2_bucket_sippy, name) do
        account_id attrs.account_id
      end
      ResourceReference.new(
        type: 'cloudflare_r2_bucket_sippy',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_r2_bucket_sippy.\#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareR2BucketSippy
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
