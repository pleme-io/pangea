# frozen_string_literal: true
require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_r2_bucket_lock/types'
require 'pangea/resource_registry'

module Pangea::Resources
  module CloudflareR2BucketLock
    def cloudflare_r2_bucket_lock(name, attributes = {})
      attrs = Cloudflare::Types::R2BucketLockAttributes.new(attributes)
      resource(:cloudflare_r2_bucket_lock, name) do
        account_id attrs.account_id
        bucket_name attrs.bucket_name
        enabled attrs.enabled
        retention_period_days attrs.retention_period_days if attrs.retention_period_days
      end
      ResourceReference.new(
        type: 'cloudflare_r2_bucket_lock',
        name: name,
        resource_attributes: attrs.to_h,
        outputs: { id: "${cloudflare_r2_bucket_lock.#{name}.id}" }
      )
    end
  end
  module Cloudflare
    include CloudflareR2BucketLock
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
