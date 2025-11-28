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
        # Type-safe attributes for Cloudflare Zone DNSSEC
        #
        # DNSSEC adds cryptographic signatures to DNS records to prevent
        # DNS spoofing and ensure authenticity of DNS responses.
        #
        # @example Enable DNSSEC for a zone
        #   ZoneDnssecAttributes.new(
        #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353"
        #   )
        #
        # @example Enable DNSSEC with presigned records
        #   ZoneDnssecAttributes.new(
        #     zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        #     dnssec_presigned: true
        #   )
        class ZoneDnssecAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute zone_id
          #   @return [String] The zone ID
          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId

          # @!attribute dnssec_presigned
          #   @return [Boolean, nil] Allow presigned DNSSEC records from external provider
          attribute :dnssec_presigned, ::Pangea::Resources::Types::Bool.optional.default(nil)

          # @!attribute dnssec_multi_signer
          #   @return [Boolean, nil] Allow multiple providers to serve DNSSEC-signed zone
          attribute :dnssec_multi_signer, ::Pangea::Resources::Types::Bool.optional.default(nil)

          # Check if using external provider signatures
          # @return [Boolean] true if dnssec_presigned is enabled
          def using_external_signatures?
            dnssec_presigned == true
          end

          # Check if multi-signer is enabled
          # @return [Boolean] true if multi_signer is enabled
          def multi_signer_enabled?
            dnssec_multi_signer == true
          end

          # Get DNSSEC mode description
          # @return [String] Description of DNSSEC configuration
          def dnssec_mode
            if using_external_signatures?
              "Presigned (external provider)"
            elsif multi_signer_enabled?
              "Multi-signer (multiple providers)"
            else
              "Cloudflare-managed"
            end
          end
        end
      end
    end
  end
end
