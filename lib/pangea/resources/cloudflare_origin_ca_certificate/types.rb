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
        # Request type enum for Origin CA certificates
        CloudflareOriginCARequestType = Dry::Types['strict.string'].enum(
          'origin-rsa',        # RSA certificate
          'origin-ecc',        # ECDSA certificate
          'keyless-certificate' # For Keyless SSL servers
        )

        # Valid certificate lifetimes in days
        CloudflareOriginCAValidity = Dry::Types['coercible.integer'].enum(
          7,     # 1 week
          30,    # 1 month
          90,    # 3 months
          365,   # 1 year
          730,   # 2 years
          1095,  # 3 years
          5475   # 15 years
        )

        # Type-safe attributes for Cloudflare Origin CA Certificate
        #
        # Origin CA certificates protect traffic between Cloudflare and origin
        # servers without involving third-party Certificate Authorities.
        #
        # @example RSA certificate for single hostname
        #   OriginCACertificateAttributes.new(
        #     csr: "-----BEGIN CERTIFICATE REQUEST-----\n...",
        #     hostnames: ["example.com"],
        #     request_type: "origin-rsa",
        #     requested_validity: 365
        #   )
        #
        # @example ECC certificate with wildcard
        #   OriginCACertificateAttributes.new(
        #     csr: "-----BEGIN CERTIFICATE REQUEST-----\n...",
        #     hostnames: ["*.example.com", "example.com"],
        #     request_type: "origin-ecc",
        #     requested_validity: 90
        #   )
        class OriginCACertificateAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute csr
          #   @return [String] Certificate Signing Request (newline-encoded)
          attribute :csr, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute hostnames
          #   @return [Array<String>] Hostnames or wildcard names
          attribute :hostnames, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'].constrained(min_size: 1))
            .constrained(min_size: 1)

          # @!attribute request_type
          #   @return [String] Signature type (origin-rsa, origin-ecc, keyless-certificate)
          attribute :request_type, CloudflareOriginCARequestType

          # @!attribute requested_validity
          #   @return [Integer] Validity period in days (7, 30, 90, 365, 730, 1095, 5475)
          attribute :requested_validity, CloudflareOriginCAValidity

          # Check if this is an RSA certificate
          # @return [Boolean] true if RSA
          def rsa?
            request_type == 'origin-rsa'
          end

          # Check if this is an ECC certificate
          # @return [Boolean] true if ECC
          def ecc?
            request_type == 'origin-ecc'
          end

          # Check if this is a keyless certificate
          # @return [Boolean] true if keyless
          def keyless?
            request_type == 'keyless-certificate'
          end

          # Check if certificate includes wildcards
          # @return [Boolean] true if any hostname is a wildcard
          def has_wildcards?
            hostnames.any? { |h| h.start_with?('*') }
          end

          # Get certificate validity in human-readable format
          # @return [String] Validity description
          def validity_description
            case requested_validity
            when 7 then "1 week"
            when 30 then "1 month"
            when 90 then "3 months"
            when 365 then "1 year"
            when 730 then "2 years"
            when 1095 then "3 years"
            when 5475 then "15 years"
            else "#{requested_validity} days"
            end
          end
        end
      end
    end
  end
end
