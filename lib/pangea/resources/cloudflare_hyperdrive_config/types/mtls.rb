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

module Pangea
  module Resources
    module Cloudflare
      module Types
        # mTLS configuration for secure database connections
        class HyperdriveMtls < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute ca_certificate_id
          #   @return [String, nil] CA certificate identifier
          attribute :ca_certificate_id, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute mtls_certificate_id
          #   @return [String, nil] Client certificate identifier
          attribute :mtls_certificate_id, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute sslmode
          #   @return [String, nil] SSL verification mode
          attribute :sslmode, CloudflareHyperdriveSslMode.optional.default(nil)

          # Check if CA certificate configured
          # @return [Boolean] true if CA cert provided
          def ca_configured?
            !ca_certificate_id.nil?
          end

          # Check if full verification required
          # @return [Boolean] true if verify-full mode
          def full_verification?
            sslmode == 'verify-full'
          end
        end
      end
    end
  end
end
