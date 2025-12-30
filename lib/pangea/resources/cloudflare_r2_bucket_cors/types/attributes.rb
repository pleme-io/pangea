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

module Pangea
  module Resources
    module Cloudflare
      module Types
        # Type-safe attributes for Cloudflare R2 Bucket CORS
        #
        # CORS (Cross-Origin Resource Sharing) configuration allows web
        # applications to make requests to R2 buckets from different origins.
        #
        # Origin format must be scheme://host[:port] without path components.
        # MaxAgeSeconds can be up to 86400 (24 hours).
        #
        # @example Basic CORS configuration
        #   R2BucketCorsAttributes.new(
        #     account_id: "a" * 32,
        #     bucket_name: "my-bucket",
        #     rules: [{
        #       allowed: {
        #         origins: ["https://example.com"],
        #         methods: ["GET", "HEAD"]
        #       },
        #       max_age_seconds: 3600
        #     }]
        #   )
        #
        # @example Wildcard CORS for public bucket
        #   R2BucketCorsAttributes.new(
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
        #   )
        class R2BucketCorsAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute account_id
          #   @return [String] The account ID
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId

          # @!attribute bucket_name
          #   @return [String] R2 bucket name
          attribute :bucket_name, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute rules
          #   @return [Array<R2CorsRule>] CORS rules
          attribute :rules, Dry::Types['strict.array']
            .of(R2CorsRule)
            .constrained(min_size: 1)

          # Check if any rule allows wildcard origins
          # @return [Boolean] true if any rule has wildcard origin
          def has_wildcard_origin?
            rules.any? { |rule| rule.allowed.wildcard_origin? }
          end

          # Check if any rule allows GET
          # @return [Boolean] true if any rule allows GET
          def allows_get?
            rules.any?(&:allows_get?)
          end

          # Check if multiple rules configured
          # @return [Boolean] true if more than one rule
          def multiple_rules?
            rules.length > 1
          end

          # Get all unique origins across rules
          # @return [Array<String>] all configured origins
          def all_origins
            rules.flat_map { |rule| rule.allowed.origins }.uniq
          end

          # Get all unique methods across rules
          # @return [Array<String>] all configured methods
          def all_methods
            rules.flat_map { |rule| rule.allowed[:methods] }.uniq
          end
        end
      end
    end
  end
end
