# frozen_string_literal: true
require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Cloudflare
      module Types
        class R2LifecycleRule < Dry::Struct
          transform_keys(&:to_sym)
          attribute :enabled, Dry::Types['strict.bool']
          attribute :prefix, Dry::Types['strict.string'].optional.default(nil)
          attribute :abort_incomplete_multipart_upload_days, Dry::Types['coercible.integer'].optional.default(nil)
          attribute :expiration, Dry::Types['strict.hash'].optional.default(nil)
        end

        class R2BucketLifecycleAttributes < Dry::Struct
          transform_keys(&:to_sym)
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
          attribute :bucket_name, Dry::Types['strict.string']
          attribute :rules, Dry::Types['strict.array'].of(R2LifecycleRule)
        end
      end
    end
  end
end
