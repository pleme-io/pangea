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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Cloudflare
      module Types
        # HTTP methods for CORS
        CloudflareR2CorsMethod = Dry::Types['strict.string'].enum(
          'GET',
          'HEAD',
          'POST',
          'PUT',
          'DELETE',
          'PATCH',
          'OPTIONS'
        )

        # Allowed configuration for CORS rule
        class R2CorsAllowed < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute origins
          #   @return [Array<String>] Allowed origins (scheme://host[:port])
          attribute :origins, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .constrained(min_size: 1)

          # @!attribute methods
          #   @return [Array<String>] Allowed HTTP methods
          attribute :methods, Dry::Types['strict.array']
            .of(CloudflareR2CorsMethod)
            .constrained(min_size: 1)

          # @!attribute headers
          #   @return [Array<String>, nil] Allowed request headers
          attribute :headers, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # Check if wildcard origin
          # @return [Boolean] true if allows all origins
          def wildcard_origin?
            origins.include?('*')
          end

          # Check if wildcard headers
          # @return [Boolean] true if allows all headers
          def wildcard_headers?
            headers&.include?('*') || false
          end
        end

        # CORS rule for R2 bucket
        class R2CorsRule < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute allowed
          #   @return [R2CorsAllowed] Allowed origins, methods, headers
          attribute :allowed, R2CorsAllowed

          # @!attribute id
          #   @return [String, nil] Rule identifier
          attribute :id, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute max_age_seconds
          #   @return [Integer, nil] Preflight cache duration (max 86400)
          attribute :max_age_seconds, Dry::Types['coercible.integer']
            .constrained(gteq: 0, lteq: 86400)
            .optional
            .default(nil)

          # @!attribute expose_headers
          #   @return [Array<String>, nil] Headers exposed to JavaScript
          attribute :expose_headers, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # Check if GET requests allowed
          # @return [Boolean] true if GET in methods
          def allows_get?
            allowed[:methods].include?('GET')
          end

          # Check if POST requests allowed
          # @return [Boolean] true if POST in methods
          def allows_post?
            allowed[:methods].include?('POST')
          end

          # Check if has preflight caching
          # @return [Boolean] true if max_age_seconds configured
          def has_preflight_caching?
            !max_age_seconds.nil? && max_age_seconds > 0
          end

          # Check if exposes headers
          # @return [Boolean] true if expose_headers configured
          def exposes_headers?
            !expose_headers.nil? && !expose_headers.empty?
          end
        end

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
        #
        # @example Multiple CORS rules
        #   R2BucketCorsAttributes.new(
        #     account_id: "a" * 32,
        #     bucket_name: "multi-origin",
        #     rules: [
        #       {
        #         id: "production",
        #         allowed: {
        #           origins: ["https://app.example.com"],
        #           methods: ["GET", "POST", "PUT"],
        #           headers: ["Content-Type"]
        #         },
        #         max_age_seconds: 3600,
        #         expose_headers: ["ETag", "Content-Length"]
        #       },
        #       {
        #         id: "staging",
        #         allowed: {
        #           origins: ["https://staging.example.com"],
        #           methods: ["GET"]
        #         },
        #         max_age_seconds: 1800
        #       }
        #     ]
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
