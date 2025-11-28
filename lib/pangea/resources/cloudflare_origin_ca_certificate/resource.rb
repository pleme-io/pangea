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
require 'pangea/resources/cloudflare_origin_ca_certificate/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Origin CA Certificate resource module that self-registers
    module CloudflareOriginCACertificate
      # Create a Cloudflare Origin CA Certificate
      #
      # Origin CA certificates protect traffic between Cloudflare and origin
      # servers without involving third-party Certificate Authorities.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Certificate attributes
      # @option attributes [String] :csr Certificate Signing Request (required)
      # @option attributes [Array<String>] :hostnames Hostnames or wildcards (required)
      # @option attributes [String] :request_type Signature type (required)
      # @option attributes [Integer] :requested_validity Validity in days (required)
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example RSA certificate for domain
      #   cloudflare_origin_ca_certificate(:origin_cert, {
      #     csr: "-----BEGIN CERTIFICATE REQUEST-----\n...",
      #     hostnames: ["example.com", "www.example.com"],
      #     request_type: "origin-rsa",
      #     requested_validity: 365
      #   })
      #
      # @example ECC certificate with wildcard
      #   cloudflare_origin_ca_certificate(:wildcard_cert, {
      #     csr: "-----BEGIN CERTIFICATE REQUEST-----\n...",
      #     hostnames: ["*.example.com", "example.com"],
      #     request_type: "origin-ecc",
      #     requested_validity: 90
      #   })
      #
      # @example Long-lived RSA certificate
      #   cloudflare_origin_ca_certificate(:long_cert, {
      #     csr: "-----BEGIN CERTIFICATE REQUEST-----\n...",
      #     hostnames: ["api.example.com"],
      #     request_type: "origin-rsa",
      #     requested_validity: 5475
      #   })
      def cloudflare_origin_ca_certificate(name, attributes = {})
        # Validate attributes using dry-struct
        cert_attrs = Cloudflare::Types::OriginCACertificateAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_origin_ca_certificate, name) do
          csr cert_attrs.csr
          hostnames cert_attrs.hostnames
          request_type cert_attrs.request_type
          requested_validity cert_attrs.requested_validity
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_origin_ca_certificate',
          name: name,
          resource_attributes: cert_attrs.to_h,
          outputs: {
            id: "${cloudflare_origin_ca_certificate.#{name}.id}",
            certificate: "${cloudflare_origin_ca_certificate.#{name}.certificate}",
            expires_on: "${cloudflare_origin_ca_certificate.#{name}.expires_on}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareOriginCACertificate
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
