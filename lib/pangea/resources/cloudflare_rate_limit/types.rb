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
        # Rate limit action mode enum
        CloudflareRateLimitMode = Dry::Types['strict.string'].enum(
          'simulate',
          'ban',
          'challenge',
          'js_challenge',
          'managed_challenge'
        )

        # Type-safe attributes for Cloudflare Rate Limit
        #
        # DEPRECATED: This resource is deprecated and will be removed in June 2025.
        # Use cloudflare_ruleset with phase="http_ratelimit" instead.
        #
        # Legacy rate limiting rules to protect against DDoS and abuse.
        #
        # @example Create rate limit rule
        #   RateLimitAttributes.new(
        #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        #     threshold: 100,
        #     period: 60,
        #     action_mode: "challenge"
        #   )
        class RateLimitAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute zone_id
          #   @return [String] The zone ID
          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId

          # @!attribute threshold
          #   @return [Integer] Request threshold that triggers action (2-1,000,000)
          attribute :threshold, Dry::Types['coercible.integer'].constrained(
            gteq: 2,
            lteq: 1_000_000
          )

          # @!attribute period
          #   @return [Integer] Time window in seconds (1-86,400)
          attribute :period, Dry::Types['coercible.integer'].constrained(
            gteq: 1,
            lteq: 86_400
          )

          # @!attribute action_mode
          #   @return [String] Action to take when threshold is exceeded
          attribute :action_mode, CloudflareRateLimitMode

          # @!attribute action_timeout
          #   @return [Integer, nil] Timeout for ban/challenge actions in seconds
          attribute :action_timeout, Dry::Types['coercible.integer']
            .constrained(gteq: 10, lteq: 86_400)
            .optional
            .default(nil)

          # @!attribute description
          #   @return [String, nil] Description of the rate limit rule
          attribute :description, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute match_request_url
          #   @return [String, nil] URL pattern to match
          attribute :match_request_url, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute match_request_methods
          #   @return [Array<String>, nil] HTTP methods to match
          attribute :match_request_methods, Dry::Types['strict.array'].of(
            Dry::Types['strict.string'].enum('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS')
          ).optional.default(nil)

          # @!attribute match_request_schemes
          #   @return [Array<String>, nil] Schemes to match (HTTP, HTTPS)
          attribute :match_request_schemes, Dry::Types['strict.array'].of(
            Dry::Types['strict.string'].enum('HTTP', 'HTTPS')
          ).optional.default(nil)

          # @!attribute match_response_status
          #   @return [Array<Integer>, nil] Response status codes to match
          attribute :match_response_status, Dry::Types['strict.array'].of(
            Dry::Types['coercible.integer'].constrained(gteq: 100, lteq: 599)
          ).optional.default(nil)

          # @!attribute disabled
          #   @return [Boolean, nil] Whether the rate limit is disabled
          attribute :disabled, ::Pangea::Resources::Types::Bool.optional.default(nil)

          # @!attribute bypass_url_patterns
          #   @return [Array<String>, nil] URL patterns to bypass rate limiting
          attribute :bypass_url_patterns, Dry::Types['strict.array'].of(
            Dry::Types['strict.string']
          ).optional.default(nil)

          # Check if rule applies to specific methods
          # @return [Boolean] true if methods are filtered
          def method_filtered?
            match_request_methods && !match_request_methods.empty?
          end

          # Check if rule only applies to errors
          # @return [Boolean] true if matching error status codes
          def error_only?
            return false unless match_response_status
            match_response_status.all? { |code| code >= 400 }
          end

          # Get rate in requests per second
          # @return [Float] Requests per second threshold
          def requests_per_second
            threshold.to_f / period
          end

          # Check if this is a strict rate limit
          # @return [Boolean] true if period is short (< 60s)
          def strict?
            period < 60
          end
        end
      end
    end
  end
end
