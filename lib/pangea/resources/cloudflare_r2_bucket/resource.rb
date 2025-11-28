# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_r2_bucket/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare R2 Bucket resource module that self-registers
    module CloudflareR2Bucket
      # Create a Cloudflare R2 Bucket
      #
      # R2 is Cloudflare's S3-compatible object storage with zero egress fees.
      # Perfect for storing images, videos, backups, and static assets.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Bucket attributes
      # @option attributes [String] :account_id Cloudflare account ID (required)
      # @option attributes [String] :name Bucket name (required, 3-63 chars)
      # @option attributes [String] :location Location hint (optional: apac, eeur, enam, weur, wnam, oc)
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Create a media assets bucket
      #   r2_bucket(:media, {
      #     account_id: "a" * 32,
      #     name: "media-assets",
      #     location: "wnam"
      #   })
      #
      # @example Create a backup bucket in Europe
      #   r2_bucket(:backups, {
      #     account_id: "a" * 32,
      #     name: "db-backups",
      #     location: "weur"
      #   })
      #
      # @example Create bucket with automatic location
      #   r2_bucket(:logs, {
      #     account_id: "a" * 32,
      #     name: "application-logs"
      #   })
      def cloudflare_r2_bucket(name, attributes = {})
        # Validate attributes using dry-struct
        bucket_attrs = Cloudflare::Types::R2BucketAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_r2_bucket, name) do
          account_id bucket_attrs.account_id
          name bucket_attrs.name
          location bucket_attrs.location if bucket_attrs.location
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_r2_bucket',
          name: name,
          resource_attributes: bucket_attrs.to_h,
          outputs: {
            id: "${cloudflare_r2_bucket.#{name}.id}",
            bucket_name: "${cloudflare_r2_bucket.#{name}.name}",
            location: "${cloudflare_r2_bucket.#{name}.location}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareR2Bucket
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
