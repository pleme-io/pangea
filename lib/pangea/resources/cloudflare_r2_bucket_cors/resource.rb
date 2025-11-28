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
require 'pangea/resources/cloudflare_r2_bucket_cors/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare R2 Bucket CORS resource module that self-registers
    module CloudflareR2BucketCors
      # Create Cloudflare R2 Bucket CORS configuration
      #
      # CORS (Cross-Origin Resource Sharing) controls which origins can
      # access R2 bucket objects from web browsers. Configure allowed
      # origins, methods, headers, and preflight caching.
      #
      # Origin format must be scheme://host[:port] without path components.
      # Use "*" for wildcard origins (public access).
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] R2 bucket CORS attributes
      # @option attributes [String] :account_id Account ID (required)
      # @option attributes [String] :bucket_name Bucket name (required)
      # @option attributes [Array<Hash>] :rules CORS rules (required)
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Basic CORS for specific origin
      #   cloudflare_r2_bucket_cors(:app_cors, {
      #     account_id: "a" * 32,
      #     bucket_name: "my-bucket",
      #     rules: [{
      #       allowed: {
      #         origins: ["https://app.example.com"],
      #         methods: ["GET", "HEAD"]
      #       },
      #       max_age_seconds: 3600
      #     }]
      #   })
      #
      # @example Public CORS with wildcard
      #   cloudflare_r2_bucket_cors(:public_cors, {
      #     account_id: "a" * 32,
      #     bucket_name: "public-assets",
      #     rules: [{
      #       allowed: {
      #         origins: ["*"],
      #         methods: ["GET"],
      #         headers: ["*"]
      #       },
      #       max_age_seconds: 86400
      #     }]
      #   })
      #
      # @example Multiple CORS rules with exposed headers
      #   cloudflare_r2_bucket_cors(:multi_cors, {
      #     account_id: "a" * 32,
      #     bucket_name: "api-bucket",
      #     rules: [
      #       {
      #         id: "production",
      #         allowed: {
      #           origins: ["https://app.example.com"],
      #           methods: ["GET", "POST", "PUT", "DELETE"],
      #           headers: ["Content-Type", "Authorization"]
      #         },
      #         max_age_seconds: 3600,
      #         expose_headers: ["ETag", "Content-Length"]
      #       },
      #       {
      #         id: "staging",
      #         allowed: {
      #           origins: ["https://staging.example.com"],
      #           methods: ["GET", "POST"]
      #         },
      #         max_age_seconds: 1800
      #       }
      #     ]
      #   })
      def cloudflare_r2_bucket_cors(name, attributes = {})
        # Validate attributes using dry-struct
        cors_attrs = Cloudflare::Types::R2BucketCorsAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_r2_bucket_cors, name) do
          account_id cors_attrs.account_id
          bucket_name cors_attrs.bucket_name

          # CORS rules as array (terraform-synthesizer handles array → blocks conversion)
          if cors_attrs.rules.any?
            rules cors_attrs.rules.map { |r| r.to_h }
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_r2_bucket_cors',
          name: name,
          resource_attributes: cors_attrs.to_h,
          outputs: {
            id: "${cloudflare_r2_bucket_cors.#{name}.id}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareR2BucketCors
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
