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
require 'pangea/resources/cloudflare_zone_dnssec/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Zone DNSSEC resource module that self-registers
    module CloudflareZoneDnssec
      # Create a Cloudflare Zone DNSSEC configuration
      #
      # DNSSEC adds cryptographic signatures to DNS records to prevent
      # DNS spoofing and ensure DNS response authenticity.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] DNSSEC attributes
      # @option attributes [String] :zone_id Zone ID (required)
      # @option attributes [Boolean] :dnssec_presigned Allow presigned records from external provider
      # @option attributes [Boolean] :dnssec_multi_signer Allow multiple providers to serve zone
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Enable basic DNSSEC
      #   cloudflare_zone_dnssec(:example_dnssec, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353"
      #   })
      #
      # @example Enable DNSSEC with presigned records
      #   cloudflare_zone_dnssec(:presigned_dnssec, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     dnssec_presigned: true
      #   })
      #
      # @example Enable multi-signer DNSSEC
      #   cloudflare_zone_dnssec(:multi_signer, {
      #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
      #     dnssec_multi_signer: true
      #   })
      def cloudflare_zone_dnssec(name, attributes = {})
        # Validate attributes using dry-struct
        dnssec_attrs = Cloudflare::Types::ZoneDnssecAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_zone_dnssec, name) do
          zone_id dnssec_attrs.zone_id
          dnssec_presigned dnssec_attrs.dnssec_presigned if dnssec_attrs.dnssec_presigned
          dnssec_multi_signer dnssec_attrs.dnssec_multi_signer if dnssec_attrs.dnssec_multi_signer
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_zone_dnssec',
          name: name,
          resource_attributes: dnssec_attrs.to_h,
          outputs: {
            id: "${cloudflare_zone_dnssec.#{name}.id}",
            status: "${cloudflare_zone_dnssec.#{name}.status}",
            flags: "${cloudflare_zone_dnssec.#{name}.flags}",
            algorithm: "${cloudflare_zone_dnssec.#{name}.algorithm}",
            key_type: "${cloudflare_zone_dnssec.#{name}.key_type}",
            digest_type: "${cloudflare_zone_dnssec.#{name}.digest_type}",
            digest_algorithm: "${cloudflare_zone_dnssec.#{name}.digest_algorithm}",
            digest: "${cloudflare_zone_dnssec.#{name}.digest}",
            ds: "${cloudflare_zone_dnssec.#{name}.ds}",
            key_tag: "${cloudflare_zone_dnssec.#{name}.key_tag}",
            public_key: "${cloudflare_zone_dnssec.#{name}.public_key}"
          }
        )
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflareZoneDnssec
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
