# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_r2_bucket_lifecycle/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareR2BucketLifecycle
    def cloudflare_r2_bucket_lifecycle(name, attributes = {})
      attrs = Cloudflare::Types::R2BucketLifecycleAttributes.new(attributes)
      resource(:cloudflare_r2_bucket_lifecycle, name) do
        account_id attrs.account_id
        bucket_name attrs.bucket_name
        # Lifecycle rules as array (terraform-synthesizer handles array → blocks conversion)
        if attrs.rules.any?
          rules attrs.rules.map { |r| r.to_h }
        end
      end
      ResourceReference.new(
        type: 'cloudflare_r2_bucket_lifecycle',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_r2_bucket_lifecycle.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareR2BucketLifecycle
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
