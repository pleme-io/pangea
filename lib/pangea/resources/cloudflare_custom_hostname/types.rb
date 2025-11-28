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
        # SSL validation method for custom hostnames
        CloudflareCustomHostnameSSLMethod = Dry::Types['strict.string'].enum(
          'http',      # HTTP token validation
          'txt',       # DNS TXT record validation
          'email'      # Email validation
        )

        # SSL certificate type
        CloudflareCustomHostnameSSLType = Dry::Types['strict.string'].enum(
          'dv',        # Domain Validation (default)
          'dv_wildcard'  # Domain Validation with wildcard support
        )

        # Certificate authority
        CloudflareCustomHostnameSSLCA = Dry::Types['strict.string'].enum(
          'digicert',   # DigiCert
          'lets_encrypt', # Let's Encrypt
          'google'      # Google Trust Services
        )

        # Bundle method for certificate chain
        CloudflareCustomHostnameSSLBundleMethod = Dry::Types['strict.string'].enum(
          'ubiquitous', # Most compatible (default)
          'optimal',    # Balanced
          'force'       # Smallest bundle
        )

        # Minimum TLS version
        CloudflareMinTLSVersion = Dry::Types['strict.string'].enum(
          '1.0',
          '1.1',
          '1.2',
          '1.3'
        )

        # SSL settings for custom hostname
        class CustomHostnameSSLSettings < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute min_tls_version
          #   @return [String, nil] Minimum TLS version
          attribute :min_tls_version, CloudflareMinTLSVersion.optional.default(nil)

          # @!attribute early_hints
          #   @return [String, nil] Early Hints support ('on' or 'off')
          attribute :early_hints, Dry::Types['strict.string']
            .enum('on', 'off')
            .optional
            .default(nil)

          # @!attribute http2
          #   @return [String, nil] HTTP/2 support ('on' or 'off')
          attribute :http2, Dry::Types['strict.string']
            .enum('on', 'off')
            .optional
            .default(nil)

          # @!attribute tls13
          #   @return [String, nil] TLS 1.3 support ('on' or 'off')
          attribute :tls13, Dry::Types['strict.string']
            .enum('on', 'off')
            .optional
            .default(nil)

          # @!attribute ciphers
          #   @return [Array<String>, nil] List of allowed cipher suites
          attribute :ciphers, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)
        end

        # SSL configuration for custom hostname
        class CustomHostnameSSL < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute method
          #   @return [String, nil] Validation method
          attribute :method, CloudflareCustomHostnameSSLMethod.optional.default(nil)

          # @!attribute type
          #   @return [String, nil] Certificate type (defaults to 'dv')
          attribute :type, CloudflareCustomHostnameSSLType.optional.default(nil)

          # @!attribute certificate_authority
          #   @return [String, nil] Certificate authority
          attribute :certificate_authority, CloudflareCustomHostnameSSLCA.optional.default(nil)

          # @!attribute bundle_method
          #   @return [String, nil] Certificate bundle method
          attribute :bundle_method, CloudflareCustomHostnameSSLBundleMethod.optional.default(nil)

          # @!attribute wildcard
          #   @return [Boolean, nil] Enable wildcard certificate
          attribute :wildcard, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute custom_certificate
          #   @return [String, nil] Custom certificate PEM
          attribute :custom_certificate, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute custom_key
          #   @return [String, nil] Custom private key PEM
          attribute :custom_key, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute settings
          #   @return [CustomHostnameSSLSettings, nil] SSL settings
          attribute :settings, CustomHostnameSSLSettings.optional.default(nil)

          # Check if using custom certificate
          # @return [Boolean] true if custom certificate provided
          def custom_certificate?
            !custom_certificate.nil? && !custom_key.nil?
          end

          # Check if wildcard enabled
          # @return [Boolean] true if wildcard certificate requested
          def wildcard?
            wildcard == true
          end
        end

        # Type-safe attributes for Cloudflare Custom Hostname
        #
        # Custom hostnames allow customers to use their own domains
        # with Cloudflare services via CNAME records.
        #
        # @example Basic custom hostname
        #   CustomHostnameAttributes.new(
        #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        #     hostname: "app.customer.com",
        #     ssl: { method: "http", type: "dv" }
        #   )
        #
        # @example Custom hostname with custom origin
        #   CustomHostnameAttributes.new(
        #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        #     hostname: "app.customer.com",
        #     ssl: { method: "txt", certificate_authority: "lets_encrypt" },
        #     custom_origin_server: "origin.customer.com",
        #     custom_origin_sni: "sni.customer.com"
        #   )
        class CustomHostnameAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute zone_id
          #   @return [String] The zone ID
          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId

          # @!attribute hostname
          #   @return [String] The custom hostname (e.g., "app.customer.com")
          attribute :hostname, Dry::Types['strict.string'].constrained(
            format: /\A[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*\z/i
          )

          # @!attribute ssl
          #   @return [CustomHostnameSSL, nil] SSL configuration
          attribute :ssl, CustomHostnameSSL.optional.default(nil)

          # @!attribute custom_origin_server
          #   @return [String, nil] Custom origin server hostname
          attribute :custom_origin_server, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute custom_origin_sni
          #   @return [String, nil] Custom origin SNI hostname
          attribute :custom_origin_sni, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute custom_metadata
          #   @return [Hash, nil] Custom metadata (string keys and values)
          attribute :custom_metadata, Dry::Types['strict.hash']
            .map(Dry::Types['strict.string'], Dry::Types['strict.string'])
            .optional
            .default(nil)

          # @!attribute wait_for_ssl_pending_validation
          #   @return [Boolean, nil] Wait for SSL validation before returning
          attribute :wait_for_ssl_pending_validation, Dry::Types['strict.bool'].optional.default(nil)

          # Check if SSL is configured
          # @return [Boolean] true if SSL configuration provided
          def ssl_configured?
            !ssl.nil?
          end

          # Check if custom origin is configured
          # @return [Boolean] true if custom origin server provided
          def custom_origin?
            !custom_origin_server.nil?
          end

          # Check if custom metadata is provided
          # @return [Boolean] true if custom metadata exists
          def has_custom_metadata?
            !custom_metadata.nil? && !custom_metadata.empty?
          end

          # Check if wildcard hostname
          # @return [Boolean] true if hostname starts with wildcard
          def wildcard?
            hostname.start_with?('*.')
          end
        end
      end
    end
  end
end
