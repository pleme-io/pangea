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
require 'pangea/resources/cloudflare_healthcheck/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Healthcheck resource module that self-registers
    module CloudflareHealthcheck
      # Create a Cloudflare standalone health check
      #
      # Monitors origin server health independent of load balancers.
      # Perfect for monitoring, alerting, and visibility into origin health.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Health check attributes
      # @option attributes [String] :zone_id Zone ID (required)
      # @option attributes [String] :name Health check name (required)
      # @option attributes [String] :address Hostname or IP to monitor (required)
      # @option attributes [String] :type Check type: HTTPS, HTTP, TCP (default: HTTPS)
      # @option attributes [Integer] :interval Check interval in seconds (30-3600, default: 60)
      # @option attributes [Integer] :timeout Check timeout in seconds (1-10, default: 5)
      # @option attributes [Integer] :retries Retries before unhealthy (0-5, default: 2)
      # @option attributes [Integer] :consecutive_fails Failures to mark unhealthy
      # @option attributes [Integer] :consecutive_successes Successes to mark healthy
      # @option attributes [Array<String>] :check_regions Regions to check from
      # @option attributes [Boolean] :notification_suspended Suspend notifications
      # @option attributes [Array<String>] :notification_email_addresses Email addresses
      # @option attributes [String] :description Description
      # @option attributes [String] :path Path to check (HTTP/HTTPS)
      # @option attributes [Integer] :port Port to check
      # @option attributes [String] :method HTTP method (GET, HEAD)
      # @option attributes [String] :expected_codes Expected HTTP codes
      # @option attributes [String] :expected_body Expected body substring
      # @option attributes [Boolean] :follow_redirects Follow redirects
      # @option attributes [Boolean] :allow_insecure Allow insecure HTTPS
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Basic HTTPS health check
      #   cloudflare_healthcheck(:api_health, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     name: "api-server-health",
      #     address: "api.example.com",
      #     type: "HTTPS"
      #   })
      #
      # @example Advanced HTTP check with notifications
      #   cloudflare_healthcheck(:web_health, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     name: "web-health-check",
      #     address: "www.example.com",
      #     type: "HTTP",
      #     path: "/health",
      #     method: "GET",
      #     expected_codes: "200",
      #     expected_body: "OK",
      #     interval: 30,
      #     notification_email_addresses: ["ops@example.com"]
      #   })
      #
      # @example TCP health check
      #   cloudflare_healthcheck(:db_health, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     name: "database-health",
      #     address: "db.example.com",
      #     type: "TCP",
      #     port: 5432,
      #     interval: 60
      #   })
      def cloudflare_healthcheck(name, attributes = {})
        # Validate attributes using dry-struct
        hc_attrs = Cloudflare::Types::HealthcheckAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_healthcheck, name) do
          zone_id hc_attrs.zone_id
          name hc_attrs.name
          address hc_attrs.address
          type hc_attrs.type
          interval hc_attrs.interval if hc_attrs.interval
          timeout hc_attrs.timeout if hc_attrs.timeout
          retries hc_attrs.retries if hc_attrs.retries
          consecutive_fails hc_attrs.consecutive_fails if hc_attrs.consecutive_fails
          consecutive_successes hc_attrs.consecutive_successes if hc_attrs.consecutive_successes
          check_regions hc_attrs.check_regions if hc_attrs.check_regions
          notification_suspended hc_attrs.notification_suspended if hc_attrs.notification_suspended
          notification_email_addresses hc_attrs.notification_email_addresses if hc_attrs.notification_email_addresses
          description hc_attrs.description if hc_attrs.description
          path hc_attrs.path if hc_attrs.path
          port hc_attrs.port if hc_attrs.port
          method hc_attrs.method if hc_attrs.method
          expected_codes hc_attrs.expected_codes if hc_attrs.expected_codes
          expected_body hc_attrs.expected_body if hc_attrs.expected_body
          follow_redirects hc_attrs.follow_redirects if hc_attrs.follow_redirects
          allow_insecure hc_attrs.allow_insecure if hc_attrs.allow_insecure
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_healthcheck',
          name: name,
          resource_attributes: hc_attrs.to_h,
          outputs: {
            id: "${cloudflare_healthcheck.#{name}.id}",
            healthcheck_id: "${cloudflare_healthcheck.#{name}.id}",
            status: "${cloudflare_healthcheck.#{name}.status}",
            failure_reason: "${cloudflare_healthcheck.#{name}.failure_reason}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareHealthcheck
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
