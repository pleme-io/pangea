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
        # Health check type enum
        CloudflareHealthcheckType = Dry::Types['strict.string'].default('HTTPS').enum(
          'HTTPS',
          'HTTP',
          'TCP'
        )

        # Type-safe attributes for Cloudflare Healthcheck
        #
        # Standalone health checks monitor the health of origin servers
        # independent of load balancers. Perfect for monitoring and alerting.
        #
        # @example Create an HTTPS health check
        #   HealthcheckAttributes.new(
        #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        #     name: "api-health",
        #     address: "api.example.com",
        #     type: "HTTPS",
        #     interval: 60
        #   )
        class HealthcheckAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute zone_id
          #   @return [String] The zone ID
          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId

          # @!attribute name
          #   @return [String] Health check name (alphanumeric, hyphens, underscores)
          attribute :name, Dry::Types['strict.string'].constrained(
            format: /\A[a-zA-Z0-9_-]+\z/,
            min_size: 1,
            max_size: 256
          )

          # @!attribute address
          #   @return [String] Hostname or IP address to monitor
          attribute :address, Dry::Types['strict.string'].constrained(
            min_size: 1,
            max_size: 256
          )

          # @!attribute type
          #   @return [String] Health check type (HTTPS, HTTP, TCP)
          attribute :type, CloudflareHealthcheckType

          # @!attribute interval
          #   @return [Integer, nil] Interval between checks in seconds
          attribute :interval, Dry::Types['coercible.integer']
            .constrained(gteq: 30, lteq: 3600)
            .optional
            .default(60)

          # @!attribute timeout
          #   @return [Integer, nil] Timeout for each check in seconds
          attribute :timeout, Dry::Types['coercible.integer']
            .constrained(gteq: 1, lteq: 10)
            .optional
            .default(5)

          # @!attribute retries
          #   @return [Integer, nil] Number of retries before marking unhealthy
          attribute :retries, Dry::Types['coercible.integer']
            .constrained(gteq: 0, lteq: 5)
            .optional
            .default(2)

          # @!attribute consecutive_fails
          #   @return [Integer, nil] Consecutive failures to mark unhealthy
          attribute :consecutive_fails, Dry::Types['coercible.integer']
            .constrained(gteq: 1, lteq: 10)
            .optional
            .default(nil)

          # @!attribute consecutive_successes
          #   @return [Integer, nil] Consecutive successes to mark healthy
          attribute :consecutive_successes, Dry::Types['coercible.integer']
            .constrained(gteq: 1, lteq: 10)
            .optional
            .default(nil)

          # @!attribute check_regions
          #   @return [Array<String>, nil] Regions to check from
          attribute :check_regions, Dry::Types['strict.array'].of(
            Dry::Types['strict.string']
          ).optional.default(nil)

          # @!attribute notification_suspended
          #   @return [Boolean, nil] Suspend notifications
          attribute :notification_suspended, ::Pangea::Resources::Types::Bool.optional.default(nil)

          # @!attribute notification_email_addresses
          #   @return [Array<String>, nil] Email addresses for notifications
          attribute :notification_email_addresses, Dry::Types['strict.array'].of(
            Dry::Types['strict.string'].constrained(format: /\A[^@]+@[^@]+\z/)
          ).optional.default(nil)

          # @!attribute description
          #   @return [String, nil] Health check description
          attribute :description, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute path
          #   @return [String, nil] Path to check (for HTTP/HTTPS)
          attribute :path, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute port
          #   @return [Integer, nil] Port to check
          attribute :port, Dry::Types['coercible.integer']
            .constrained(gteq: 1, lteq: 65535)
            .optional
            .default(nil)

          # @!attribute method
          #   @return [String, nil] HTTP method (for HTTP/HTTPS)
          attribute :method, Dry::Types['strict.string'].enum('GET', 'HEAD')
            .optional
            .default(nil)

          # @!attribute expected_codes
          #   @return [String, nil] Expected HTTP status codes
          attribute :expected_codes, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute expected_body
          #   @return [String, nil] Expected response body substring
          attribute :expected_body, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute follow_redirects
          #   @return [Boolean, nil] Follow HTTP redirects
          attribute :follow_redirects, ::Pangea::Resources::Types::Bool.optional.default(nil)

          # @!attribute allow_insecure
          #   @return [Boolean, nil] Allow insecure HTTPS
          attribute :allow_insecure, ::Pangea::Resources::Types::Bool.optional.default(nil)

          # Check if this is a frequent health check
          # @return [Boolean] true if interval <= 60 seconds
          def frequent_check?
            interval && interval <= 60
          end

          # Check if notifications are configured
          # @return [Boolean] true if email addresses configured
          def notifications_configured?
            notification_email_addresses && !notification_email_addresses.empty?
          end

          # Get default port for health check type
          # @return [Integer] Default port based on type
          def default_port
            case type
            when 'HTTPS'
              443
            when 'HTTP'
              80
            else
              port || 0
            end
          end

          # Check if health check uses HTTP/HTTPS
          # @return [Boolean] true if type is HTTP or HTTPS
          def http_check?
            %w[HTTP HTTPS].include?(type)
          end
        end
      end
    end
  end
end
