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
require 'pangea/resources/cloudflare_rate_limit/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Rate Limit resource module that self-registers
    #
    # DEPRECATED: This resource is deprecated and will be removed in June 2025.
    # Use cloudflare_ruleset with phase="http_ratelimit" instead.
    module CloudflareRateLimit
      # Create a Cloudflare Rate Limit rule (Legacy)
      #
      # DEPRECATED: This resource is deprecated. Use cloudflare_ruleset instead.
      #
      # Protects against DDoS and abuse by rate limiting requests.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Rate limit attributes
      # @option attributes [String] :zone_id Zone ID (required)
      # @option attributes [Integer] :threshold Request threshold (2-1,000,000, required)
      # @option attributes [Integer] :period Time window in seconds (1-86,400, required)
      # @option attributes [String] :action_mode Action mode (required)
      # @option attributes [Integer] :action_timeout Action timeout in seconds
      # @option attributes [String] :description Description
      # @option attributes [String] :match_request_url URL pattern
      # @option attributes [Array<String>] :match_request_methods HTTP methods
      # @option attributes [Array<String>] :match_request_schemes Schemes (HTTP/HTTPS)
      # @option attributes [Array<Integer>] :match_response_status Status codes
      # @option attributes [Boolean] :disabled Disable rule
      # @option attributes [Array<String>] :bypass_url_patterns Bypass patterns
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Basic rate limit (100 req/min)
      #   cloudflare_rate_limit(:api_limit, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     threshold: 100,
      #     period: 60,
      #     action_mode: "challenge",
      #     description: "API rate limit"
      #   })
      #
      # @example Rate limit for specific path
      #   cloudflare_rate_limit(:login_limit, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     threshold: 5,
      #     period: 60,
      #     action_mode: "ban",
      #     action_timeout: 600,
      #     match_request_url: "*/login",
      #     match_request_methods: ["POST"]
      #   })
      def cloudflare_rate_limit(name, attributes = {})
        # Validate attributes using dry-struct
        rl_attrs = Cloudflare::Types::RateLimitAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_rate_limit, name) do
          zone_id rl_attrs.zone_id
          threshold rl_attrs.threshold
          period rl_attrs.period

          action do
            mode rl_attrs.action_mode
            timeout rl_attrs.action_timeout if rl_attrs.action_timeout
          end

          description rl_attrs.description if rl_attrs.description
          disabled rl_attrs.disabled if rl_attrs.disabled
          bypass_url_patterns rl_attrs.bypass_url_patterns if rl_attrs.bypass_url_patterns

          if rl_attrs.match_request_url || rl_attrs.match_request_methods ||
             rl_attrs.match_request_schemes || rl_attrs.match_response_status
            match do
              request do
                url_pattern rl_attrs.match_request_url if rl_attrs.match_request_url
                methods rl_attrs.match_request_methods if rl_attrs.match_request_methods
                schemes rl_attrs.match_request_schemes if rl_attrs.match_request_schemes
              end

              if rl_attrs.match_response_status
                response do
                  status rl_attrs.match_response_status
                end
              end
            end
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_rate_limit',
          name: name,
          resource_attributes: rl_attrs.to_h,
          outputs: {
            id: "${cloudflare_rate_limit.#{name}.id}",
            rule_id: "${cloudflare_rate_limit.#{name}.id}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareRateLimit
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
