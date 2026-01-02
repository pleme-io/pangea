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
      end
    end
  end
end
